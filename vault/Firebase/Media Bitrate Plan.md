# Media Bitrate Plan — fixing the 10 Mbps compressor output

Status: **planned, not started** · Created 2026-08-27 after the first on-device compression test · Owner decision: interim 150 MB Storage cap accepted, proper fix wanted "with code" to bring costs down.

## The problem, measured

First real on-device run (iPhone 14 Pro, 11 s clip "ured", 2026-08-27):

| | target (cost model) | actual |
|---|---|---|
| resolution | 1280×720 ✅ | 1280×720 ✅ |
| video codec | H.264 ✅ | H.264 ✅ |
| **video bitrate** | **~1.5–2.5 Mbps** | **9.7 Mbps** |
| 11 s file | ~3 MB | **13.8 MB** |
| 90 s worst case | ~25 MB | **~110 MB** |

Root cause: `video_compress 3.1.4` on iOS wraps `AVAssetExportSession` with the preset `AVAssetExportPreset1280x720`. Apple's presets control **resolution only** — bitrate is whatever the preset defaults to (~10 Mbps). The package exposes **no bitrate parameter**, and it is unmaintained (our whole FlutterFire generation is frozen on Dart 3.5 anyway), so no upstream fix is coming.

Consequences at 10 Mbps: uploads ~6× larger → the 100 MB rule cap rejected 90 s clips (interim: cap raised to 150 MB), storage ~6× (trivial: still <€1/mo at 1 000 videos), **bandwidth ~6×** (the real cost: worst-case uncached ~€19/mo instead of ~€3).

## Interim state (already shipped)

- Storage rules cap **100 → 150 MB** (`storage.rules`, comment marks it temporary; drop back to 100 when this plan lands)
- Web pre-check + Croatian error updated to 150 MB
- **Day-9 cache-first playback is the real cost mitigation**: each patient device downloads a video once, so even 10 Mbps clips cost ~one download per patient — the €19/mo figure assumes pathological no-cache re-streaming. With caching, the interim state is likely <€5/mo at pitch scale. The bitrate fix is about not paying 6× forever, not about surviving the next month.

## The fix: own the encode on iOS (Option A — recommended)

Replace `video_compress`'s iOS path with a **~150-line Swift platform channel** using `AVAssetReader` + `AVAssetWriter` with explicit settings:

```swift
AVVideoCompressionPropertiesKey: [
  AVVideoAverageBitRateKey: 2_200_000,        // ~2.2 Mbps
  AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
  AVVideoMaxKeyFrameIntervalKey: 60,
]
// 1280×720 (portrait 720×1280 via transform), 30 fps, AAC 96 kbps mono
```

Exercise videos are static-camera, low-motion — 2.2 Mbps 720p is visually transparent for this content. Expected 90 s file: **~25 MB**.

Integration is cheap because the seam already exists: only `FirebaseMediaUploader._compress` changes — it calls the channel instead of `VideoCompress.compressVideo`. Progress reporting via the writer's `progress` polling → same `onCompress` callback → the sheet UI is untouched. Poster keeps using `getFileThumbnail` (works fine) or moves to `AVAssetImageGenerator` in the same channel.

**Android**: measure first. `video_compress` on Android drives MediaCodec with its own bitrate logic (different code path from iOS) — it may already be sane. If not, the same channel gets an Android twin (`MediaCodec` + `MediaMuxer`, ~250 lines). No Android release for ~3 months per the pitch, so this is not on the critical path.

### Acceptance tests (device required)

1. 90 s 4K camera clip → output ≤ 30 MB, 1280×720, plays on iPhone + web + after Storage round-trip
2. Portrait + landscape sources keep orientation (the `AVAssetWriter` transform is the classic bug)
3. Clip with audio keeps audio in sync at the end of 90 s
4. Compression time ≤ ~1.5× realtime on the oldest physio iPhone (measure day 11's timing pass)
5. Cost re-check: 50 users × 20 videos back to ~3.5 GB → restore the **100 MB rules cap** and re-run the rules suite

## Rejected alternatives

- **Fork video_compress**: same Swift work plus maintaining a fork of an abandoned plugin — strictly worse than owning 150 clean lines.
- **ffmpeg_kit**: retired upstream (Jan 2025), +30 MB binary, LGPL headaches for the App Store. No.
- **Server-side transcode (Cloud Function / Cloud Run + ffmpeg)**: adds paid infra and a second encode of every upload — the plan's no-functions posture holds; client CPU is free.
- **Lower preset (960×540)**: still preset-controlled bitrate (~5 Mbps) — halves the problem instead of fixing it, and gives up the 720p promise.

## When

Post-signature, **paid-phase day 9** (alongside cache-first playback and the on-device drills — same test devices, same day) or day 14 buffer. Not before the pitch: the emulator demo doesn't pay bandwidth, and the 150 MB interim keeps every flow working.
