import 'dart:io';
import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:physio_app/domain/media_uploader.dart';
import 'package:video_compress/video_compress.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Storage rules cap uploads at 150 MB (raised from 100 while the iOS
/// compressor emits ~10 Mbps 720p — see the vault bitrate plan); checked
/// client-side on web where no compression runs (plan §3.6).
const _maxUploadBytes = 150 * 1024 * 1024;

// User-presentable (Croatian) — the sheet shows these verbatim. Kept here
// with the other Firebase-only strings until the day-12 copy review.
const _msgCompressFailed = 'Obrada videozapisa nije uspjela. Pokušajte ponovno.';
const _msgTooBig = 'Datoteka je prevelika — najviše 150 MB.';
const _msgUploadFailed =
    'Prijenos nije uspio. Provjerite vezu i pokušajte ponovno.';

/// Real media pipeline vs Cloud Storage (plan day 8). Mobile: 720p
/// compression + poster frame; web: uncompressed bytes with a size
/// pre-check, no poster. Wakelock held for the duration — iOS kills
/// backgrounded transfers.
class FirebaseMediaUploader implements MediaUploader {
  final FirebaseStorage storage;
  final String clinicId;
  FirebaseMediaUploader(this.storage, {this.clinicId = 'tendo'});

  @override
  Future<MediaUploadResult> upload({
    required XFile file,
    void Function(double progress)? onCompress,
    void Function(double progress)? onUpload,
  }) async {
    try {
      await WakelockPlus.enable();
    } catch (_) {} // unsupported platform: proceed without it
    try {
      final videoId = _newId();
      final folder = 'clinics/$clinicId/videos/$videoId';
      final videoRef = storage.ref('$folder/video.mp4');
      final metadata = SettableMetadata(contentType: 'video/mp4');

      UploadTask videoTask;
      File? posterFile;
      if (kIsWeb) {
        // No compression on web (plan §3.6): browsers give no usable
        // re-encode path, so bytes go up as-is behind the size pre-check.
        final bytes = await file.readAsBytes();
        if (bytes.length > _maxUploadBytes) {
          throw const MediaUploadException(MediaUploadStage.compress, _msgTooBig);
        }
        onCompress?.call(1.0);
        videoTask = videoRef.putData(bytes, metadata);
      } else {
        final compressed = await _compress(file.path, onCompress);
        posterFile = await _poster(file.path);
        videoTask = videoRef.putFile(compressed, metadata);
      }

      final sub = videoTask.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          onUpload?.call(s.bytesTransferred / s.totalBytes);
        }
      });
      try {
        await videoTask;
      } finally {
        await sub.cancel();
      }

      String? posterUrl;
      if (posterFile != null) {
        final posterRef = storage.ref('$folder/poster.jpg');
        await posterRef.putFile(
            posterFile, SettableMetadata(contentType: 'image/jpeg'));
        posterUrl = await posterRef.getDownloadURL();
      }

      return MediaUploadResult(
        videoId: videoId,
        mediaUrl: await videoRef.getDownloadURL(),
        posterUrl: posterUrl,
        storagePath: videoRef.fullPath,
      );
    } on MediaUploadException {
      rethrow;
    } on FirebaseException {
      throw const MediaUploadException(MediaUploadStage.upload, _msgUploadFailed);
    } catch (_) {
      throw const MediaUploadException(MediaUploadStage.upload, _msgUploadFailed);
    } finally {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  Future<File> _compress(
      String path, void Function(double progress)? onCompress) async {
    // compressProgress$ reports 0..100 for the in-flight compression.
    final sub = VideoCompress.compressProgress$.subscribe((p) {
      onCompress?.call((p / 100).clamp(0.0, 1.0));
    });
    try {
      final info = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.Res1280x720Quality, // MediumQuality is ~360p!
        deleteOrigin: false,
        includeAudio: true,
      );
      final compressedPath = info?.path;
      if (compressedPath == null) {
        throw const MediaUploadException(
            MediaUploadStage.compress, _msgCompressFailed);
      }
      onCompress?.call(1.0);
      return File(compressedPath);
    } on MediaUploadException {
      rethrow;
    } catch (_) {
      throw const MediaUploadException(
          MediaUploadStage.compress, _msgCompressFailed);
    } finally {
      sub.unsubscribe();
    }
  }

  /// Poster failures are non-fatal — the player falls back to its dark stage.
  Future<File?> _poster(String path) async {
    try {
      return await VideoCompress.getFileThumbnail(path, quality: 70);
    } catch (_) {
      return null;
    }
  }

  /// Firestore-style 20-char auto-id, minted client-side so the Storage
  /// folder and the (later) video doc share an id.
  static String _newId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(20, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
