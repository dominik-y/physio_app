/// Demo-mode media registry: maps a library video id to a locally picked
/// clip (blob URL on web, file path on device). Deliberately in-memory and
/// capped at 15-second clips by the upload sheet — the real pipeline
/// (Cloud Storage + compression) replaces this in the Firebase phase.
class DemoMediaStore {
  DemoMediaStore._();
  static final DemoMediaStore instance = DemoMediaStore._();

  final Map<String, String> _urlByVideoId = {};

  void register(String videoId, String url) => _urlByVideoId[videoId] = url;

  String? urlFor(String? videoId) =>
      videoId == null ? null : _urlByVideoId[videoId];
}
