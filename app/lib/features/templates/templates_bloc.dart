import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/core/streams.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

class TemplateRow extends Equatable {
  final ProtocolTemplate template;

  /// Sum of each item's video duration, or null when a referenced video is
  /// missing from the library (row falls back to exercise count only).
  final int? totalDurationSec;

  const TemplateRow({required this.template, required this.totalDurationSec});

  @override
  List<Object?> get props => [template, totalDurationSec];
}

class TemplatesState extends Equatable {
  final bool loading;
  final List<TemplateRow> rows;

  const TemplatesState({required this.loading, required this.rows});

  const TemplatesState.initial() : loading = true, rows = const [];

  @override
  List<Object?> get props => [loading, rows];
}

class TemplatesBloc extends Bloc<_TemplatesEvent, TemplatesState> {
  final TemplatesRepository templatesRepository;
  final LibraryRepository libraryRepository;
  late final StreamSubscription _sub;

  TemplatesBloc({required this.templatesRepository, required this.libraryRepository})
      : super(const TemplatesState.initial()) {
    on<_DataUpdated>((event, emit) => emit(event.state));
    _sub = combineLatest2(
      templatesRepository.watchTemplates(),
      libraryRepository.watchVideos(),
      (List<ProtocolTemplate> templates, List<VideoItem> videos) {
        final videoById = {for (final v in videos) v.id: v};
        final rows = templates
            .map((t) {
              var missing = false;
              var total = 0;
              for (final item in t.items) {
                final video = videoById[item.videoId];
                if (video == null) {
                  missing = true;
                  break;
                }
                total += video.durationSec;
              }
              return TemplateRow(template: t, totalDurationSec: missing ? null : total);
            })
            .toList();
        return TemplatesState(loading: false, rows: rows);
      },
    ).listen((state) => add(_DataUpdated(state)));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

sealed class _TemplatesEvent {}

class _DataUpdated extends _TemplatesEvent {
  final TemplatesState state;
  _DataUpdated(this.state);
}
