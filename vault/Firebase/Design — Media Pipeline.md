# Video/Media Pipeline — Firebase Storage

Scope: how physio-filmed exercise videos get from the phone into Cloud Storage, how patients play them back, and what is deliberately deferred. Grounded in the current code: `app/lib/features/library/upload_sheet.dart` (picker + UploadCubit states already exist), `app/lib/design_system/demo_video_player.dart` + `real_video_player.dart` (player already handles http/blob/file/asset URLs), `app/lib/data/demo_media_store.dart` (the in-memory registry this replaces).

## 1. Upload flow (physio app)

The demo already has the right skeleton: `showUploadSheet` → `image_picker.pickVideo(camera|gallery)` → probe duration with a throwaway `VideoPlayerController` → `UploadCubit` with states `UploadIdle / UploadCompressing / UploadUploading / UploadFailed / UploadDone` and two progress bars. The Firebase implementation fills in the cubit; the sheet UI is unchanged.

Pipeline per upload:

1. **Pick** — `ImagePicker().pickVideo(source, maxDuration: 90s)` (camera respects it; gallery may not).
2. **Validate client-side** — reuse `_probeDurationSec` (already in `upload_sheet.dart`): reject > 90 s (production cap, replacing the demo's 15 s `demoImportMaxSec`); reject raw file > 500 MB via `File.length()` (sanity guard before compression); reject unplayable files (probe returns null).
3. **Compress** — `video_compress` (pin ~3.1.x; Dart constraint compatible with 3.5.3 — verify on `flutter pub get`), `VideoQuality.MediumQuality` targeting 720p H.264/AAC. Progress stream drives the existing "Compressing" bar. A 90 s clip lands around 15–40 MB. **Web fallback:** no compression on web — upload the original if ≤ 100 MB, else reject with a message ("film on the phone"). Physio uploads are expected from the iOS app anyway.
4. **Poster** — `VideoCompress.getFileThumbnail()` (JPEG, ~720px wide) generated in the same step, nearly free since the package is already loaded.
5. **Upload** — pre-generate the Firestore doc id (`FirebaseFirestore.instance.collection(...).doc().id`), then `putFile` video and poster with `SettableMetadata(contentType: 'video/mp4' | 'image/jpeg')`. `TaskSnapshot` stream drives the "Uploading" bar. **Order: bytes first, Firestore doc last** — a failed upload leaves at most an orphaned file, never a library entry pointing at nothing.
6. **Finalize** — `getDownloadURL()` for both files, then create the `VideoItem` doc (via `LibraryRepository.addVideo`, extended — see §3) with real probed `durationSec`, `mediaUrl`, `posterUrl`, `storagePath`, `sizeBytes`.
7. **Retry** — `UploadFailed` + existing Retry button re-runs from the compressed temp file (skip re-compression). Compressed temp files are cleaned with `VideoCompress.deleteAllCache()` after success.

Post-upload confirm: the sheet's Done state already exists; optionally play the clip back before closing (deferred — nice-to-have).

## 2. Storage layout

```
clinics/{clinicId}/videos/{videoId}/video.mp4
clinics/{clinicId}/videos/{videoId}/poster.jpg
```

- `clinicId` = `"tendo"` day one; the prefix exists purely to keep the multi-tenant door open (matches the structural-clinicId stance in the vault) and to make per-clinic Storage rules a one-line change later.
- `{videoId}` is the Firestore auto-id (20 random chars, ~120 bits) — this is what makes "unguessable path" a real, if weak, protection for private videos (see §6).
- Fixed filenames inside the folder keep deletion trivial (delete two known objects) and paths derivable from the doc.

## 3. Model changes

`VideoItem` gains: `String? mediaUrl`, `String? posterUrl`, `String? storagePath`, `int? sizeBytes`. All nullable so demo fixtures and tests are untouched.

`ExerciseItem` (embedded in Assignment) gains: `String? mediaUrl`, `String? posterUrl` — **denormalized at assign time** exactly like title/durationSec/bodyPart already are. This is load-bearing: patients never read the library collection (spec §4.7), and `DemoMediaStore.urlFor` is synchronous, so the playback URL must already sit on the data the patient reads. Assign-flow snapshotting copies the two fields; no new reads.

**Replacing DemoMediaStore:** it has exactly two live call sites — `upload_sheet.dart:142` (register) and `demo_video_player.dart:118` (lookup). Change `DemoVideoPlayer` to accept an optional `mediaUrl`/`posterUrl` parameter passed down from whatever model the screen already holds (VideoItem in library/templates, ExerciseItem in session/patient-home); when null, it falls back to `DemoMediaStore.instance.urlFor(videoId)` so **demo mode behaves byte-for-byte as today**. `RealVideoPlayer` needs zero changes — Storage download URLs are plain https and it already routes `http…` to `VideoPlayerController.networkUrl`.

## 4. Limits

| Limit | Value | Where enforced |
|---|---|---|
| Duration | **90 s** (owner-pitched cap; demo's 15 s was a memory constraint, gone) | picker `maxDuration` + probe check + (optionally) a `maxDurationSec` field in a Firestore `config/app` doc so raising it is a config edit, "never a renegotiation" |
| Raw pick size | 500 MB | client, pre-compression |
| Uploaded object size | 150 MB | Storage rules (`request.resource.size < 150 * 1024 * 1024`) — backstop, not primary |
| Content type | `video/mp4` / `image/jpeg` per path | Storage rules |

Duration cannot be enforced server-side without a Cloud Function probing the file — accepted: the only writers are 1–3 trusted physios.

## 5. Playback, caching, offline — honest version

**Download URLs, not SDK streaming.** The Storage SDK has no streaming API (`getData` buffers the whole file in memory); `getDownloadURL` returns a long-lived token URL that AVPlayer range-requests and seeks natively. URL is stored on the doc at upload time (no per-play `getDownloadURL` round-trip, and it keeps `urlFor`-style synchronous access alive). Trade-off accepted: token URLs work without auth for anyone holding the link — same trust level as the unguessable-path Storage read story (§6).

**What works offline day one:** the exercise plan, checklist, completion recording — all Firestore offline persistence. **What does not: video bytes.** `video_player`/AVPlayer buffers ahead within a session (a stall mid-video usually recovers; a fully buffered video keeps playing) but persists nothing across app launches; every session re-streams. On flaky-but-present connectivity this is fine (progressive MP4, 720p, ≤ 40 MB); with *no* connectivity the patient sees the plan but the player shows the poster + an error/retry state — RealVideoPlayer needs a small error UI for `initialize()` failure (today it spins forever), which IS day-one scope.

**Deferred (deliberately, matches vault "offline downloads only on complaint"):** a local file cache — `flutter_cache_manager` keyed by videoId, download-then-`VideoPlayerController.file`, prefetch on assignment-seen. Well-understood, ~1–2 days, added when a real patient complains. The denormalized `mediaUrl` field makes this a player-internal change later.

## 6. Storage security rules

Physios are hand-provisioned by Dominik, so a **custom claim `physio: true`** set by a one-off admin script (Node, service account) at provisioning time is cheap and available to Storage rules day one — no Firestore lookups needed (Storage rules can't do them anyway).

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /clinics/{clinicId}/videos/{videoId}/{file} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.auth.token.physio == true
                   && request.resource.size < 150 * 1024 * 1024
                   && (
                        (file == 'video.mp4' && request.resource.contentType == 'video/mp4') ||
                        (file == 'poster.jpg' && request.resource.contentType.matches('image/.*'))
                      );
    }
  }
}
```

Known, accepted single-tenant gaps (documented in Complications.md, restated here): (a) any authenticated patient can read any video object if they learn its path — private videos are protected by unguessable auto-id paths only; (b) token download URLs bypass auth entirely. Both are blocking prerequisites for a second clinic, not for Tendo. Rules get emulator tests alongside the Firestore rules suite (physio can write, patient cannot, wrong contentType rejected, oversize rejected).

**Deletion:** `deletePatient` cascade and future video-delete must also delete the two Storage objects. Day one: client-side best-effort delete after the Firestore batch; an orphaned 30 MB file costs ~EUR 0.001/mo — periodic manual sweep acceptable, Cloud Function cleanup deferred.

## 7. Cost at realistic scale

Assume 100 videos x 30 MB = **3 GB stored**; 30 active patients, ~4 sessions/week x 3 videos x 30 MB full re-download (worst case, no cache):

- Storage: 3 GB x ~$0.026/GB/mo ≈ **$0.08/mo**
- Egress: 30 x 4 x 3 x 30 MB ≈ 10.8 GB/week ≈ **45 GB/mo** x ~$0.12/GB ≈ **$5.4/mo**
- Upload ops, metadata ops: cents.

Note the free tier (5 GB / 1 GB-day egress) applies to US-region default buckets; the bucket is pinned `europe-west3`, so assume ~**EUR 5–8/month** all-in for media at this scale — under 5 % of the EUR 170/month fee. It scales linearly with watch volume; the later file cache would cut egress roughly by the re-watch factor. Not a pricing risk.

## 8. The bundled demo reel

`app/assets/videos/tendo_reel8.mp4` (3.4 MB, registered in `app.dart` as `asset:assets/videos/tendo_reel8.mp4` for `v-tendo-drill`):

- **Demo mode: untouched.** The asset stays bundled, `DemoMediaStore` registration stays, the pitch build keeps working unchanged — hard requirement.
- **Firebase mode: it simply doesn't exist.** Production starts with an empty library; the physio films real content. The reel is not seeded into Storage. During the day-5 smoke test it may be uploaded through the real pipeline as a throwaway test clip, then deleted.
- The 3.4 MB stays in the production IPA because the asset ships in both flavors — acceptable; stripping it via flavor-specific asset lists is a later polish item.

## 9. Explicitly deferred

- Local video file cache / offline downloads (on complaint; design sketched in §5).
- Server-side transcode / HLS (progressive 720p MP4 is fine at 90 s).
- Poster shown in list tiles (posters are uploaded from day one so files exist retroactively; the gradient `VideoThumb` stays in lists until a UI pass — session player uses the poster as its loading/error backdrop day one).
- Storage read tightening via per-patient claims (second-clinic prerequisite).
- Cloud Function orphan cleanup, video replace/edit, web-upload compression.
