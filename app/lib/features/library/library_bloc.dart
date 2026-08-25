import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

/// Sections always appear in this order when present; any other body part
/// (e.g. a physio-defined category outside the demo set) is appended
/// alphabetically after them.
const libraryFixedSectionOrder = ['Knee', 'Shoulder', 'Lower back', 'Neck'];

/// Groups the library by body part for browsing (spec §6.4). Re-groups on
/// every repository emission so an upload appears immediately.
class LibraryBloc extends Cubit<Map<String, List<VideoItem>>> {
  final LibraryRepository repository;
  StreamSubscription<List<VideoItem>>? _sub;

  LibraryBloc(this.repository) : super(const {}) {
    _sub = repository.watchVideos().listen(_onVideos);
  }

  void _onVideos(List<VideoItem> videos) {
    final byBodyPart = <String, List<VideoItem>>{};
    for (final video in videos) {
      (byBodyPart[video.bodyPart] ??= []).add(video);
    }
    for (final section in byBodyPart.values) {
      section.sort((a, b) => a.title.compareTo(b.title));
    }
    final others = byBodyPart.keys.where((k) => !libraryFixedSectionOrder.contains(k)).toList()
      ..sort();
    final order = [
      ...libraryFixedSectionOrder.where(byBodyPart.containsKey),
      ...others,
    ];
    emit({for (final section in order) section: byBodyPart[section]!});
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
