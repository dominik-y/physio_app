import 'package:cross_file/cross_file.dart';

/// Where a real upload failed — retry re-runs the whole sequence either way,
/// but the sheet can show a stage-appropriate message.
enum MediaUploadStage { compress, upload }

class MediaUploadException implements Exception {
  final MediaUploadStage stage;

  /// Already user-presentable (Croatian) — the sheet shows it verbatim.
  final String message;
  const MediaUploadException(this.stage, this.message);

  @override
  String toString() => 'MediaUploadException($stage): $message';
}

/// What a finished upload hands back for the video doc. [videoId] is minted
/// by the uploader so the Storage folder and the Firestore doc share an id.
class MediaUploadResult {
  final String videoId;
  final String mediaUrl;
  final String? posterUrl;
  final String storagePath;

  const MediaUploadResult({
    required this.videoId,
    required this.mediaUrl,
    this.posterUrl,
    required this.storagePath,
  });
}

/// Flavor seam for real media handling (plan §3.5–3.7). XFile-based so one
/// interface covers web (bytes) and mobile (file path). Upload-first
/// ordering: media lands in Storage before any video doc exists, so a killed
/// app leaves an invisible orphan file — never a stuck 'uploading' doc.
abstract class MediaUploader {
  /// Compresses (mobile) and uploads [file]; progress callbacks are each
  /// 0..1. Throws [MediaUploadException] on failure.
  Future<MediaUploadResult> upload({
    required XFile file,
    void Function(double progress)? onCompress,
    void Function(double progress)? onUpload,
  });
}

/// Per-flavor media behavior for the upload sheet. Demo: no uploader (the
/// UploadCubit simulation runs) and the 15-second in-memory cap. Firebase:
/// a real uploader and the 90-second clip cap (§6 decision, Firebase-only).
class MediaConfig {
  final MediaUploader? uploader;
  final int importMaxSec;

  const MediaConfig.demo()
      : uploader = null,
        importMaxSec = 15;

  const MediaConfig.real({required MediaUploader this.uploader})
      : importMaxSec = 90;
}
