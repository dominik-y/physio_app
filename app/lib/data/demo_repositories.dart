import 'package:physio_app/core/dates.dart';
import 'package:physio_app/core/result.dart';
import 'package:physio_app/core/watchable.dart';
import 'package:physio_app/data/demo_data.dart';
import 'package:physio_app/domain/media_uploader.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/domain/repository_bundle.dart';

/// The in-memory bundle the demo entrypoint (and the pitch build) runs on.
RepositoryBundle demoRepositoryBundle(DemoStore store) => RepositoryBundle(
      patients: DemoPatientsRepository(store),
      library: DemoLibraryRepository(store),
      templates: DemoTemplatesRepository(store),
      assignments: DemoAssignmentsRepository(store),
      completions: DemoCompletionsRepository(store),
    );

/// Shared in-memory state behind all demo repositories. One instance per app
/// run; every mutation goes through [Watchable.update] so open screens react.
class DemoStore {
  final Watchable<List<Patient>> patients;
  final Watchable<List<VideoItem>> videos;
  final Watchable<List<ProtocolTemplate>> templates;
  final Watchable<List<Assignment>> assignments;
  final Watchable<Map<String, List<Completion>>> completions;
  final NowFn now;
  int _idCounter = 0;

  DemoStore.seed({NowFn? now})
      : this._(DemoData.seed((now ?? DateTime.now)()), now ?? DateTime.now);

  DemoStore._(DemoData data, this.now)
      : patients = Watchable(data.patients),
        videos = Watchable(data.videos),
        templates = Watchable(data.templates),
        assignments = Watchable(data.assignments),
        completions = Watchable(data.completionsByPatient);

  String nextId(String prefix) => '$prefix-${++_idCounter}';
}

class DemoPatientsRepository implements PatientsRepository {
  final DemoStore store;
  DemoPatientsRepository(this.store);

  @override
  Stream<List<Patient>> watchPatients() => store.patients.watch();

  @override
  Stream<Patient?> watchPatient(String id) => store.patients.watch().map((list) {
        for (final p in list) {
          if (p.id == id) return p;
        }
        return null;
      });

  @override
  Future<Result<Patient>> addPatient({required String name, required String email}) async {
    if (name.trim().isEmpty) return const Err('Name is required');
    final now = store.now();
    final patient = Patient(
      id: store.nextId('pat'),
      name: name.trim(),
      email: email.trim(),
      inviteCode: _inviteCode(),
      inviteExpiresAt: now.add(const Duration(days: 14)),
      createdAt: now,
    );
    store.patients.update((list) => [...list, patient]);
    return Ok(patient);
  }

  @override
  Future<Result<void>> updateNotes(String patientId, String notes) async {
    store.patients.update(
        (list) => [for (final p in list) p.id == patientId ? p.copyWith(notes: notes) : p]);
    return const Ok(null);
  }

  @override
  Future<Result<void>> deletePatient(String patientId) async {
    store.patients.update((list) => [for (final p in list) if (p.id != patientId) p]);
    store.assignments.update((list) => [for (final a in list) if (a.patientId != patientId) a]);
    store.completions.update((map) => {...map}..remove(patientId));
    return const Ok(null);
  }

  @override
  Future<Result<String>> regenerateInvite(String patientId) async {
    final code = _inviteCode();
    store.patients.update((list) => [
          for (final p in list)
            p.id == patientId
                ? p.copyWith(
                    inviteCode: code,
                    inviteExpiresAt: store.now().add(const Duration(days: 14)))
                : p
        ]);
    return Ok(code);
  }

  String _inviteCode() {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final seed = store.now().microsecondsSinceEpoch + store.nextId('c').hashCode;
    final chars = List.generate(7, (i) => alphabet[(seed >> (i * 5)) % alphabet.length]);
    return '${chars.sublist(0, 3).join()}-${chars.sublist(3).join()}';
  }
}

class DemoLibraryRepository implements LibraryRepository {
  final DemoStore store;
  DemoLibraryRepository(this.store);

  @override
  Stream<List<VideoItem>> watchVideos() => store.videos.watch();

  @override
  Future<Result<VideoItem>> addVideo({
    required String title,
    required String bodyPart,
    required int durationSec,
    String? privateToPatientId,
    MediaUploadResult? media, // demo playback goes through DemoMediaStore
  }) async {
    if (title.trim().isEmpty) return const Err('Title is required');
    final video = VideoItem(
      id: store.nextId('v'),
      title: title.trim(),
      bodyPart: bodyPart,
      durationSec: durationSec,
      visibility: privateToPatientId == null ? 'library' : 'private',
      privateToPatientId: privateToPatientId,
      createdAt: store.now(),
    );
    store.videos.update((list) => [...list, video]);
    return Ok(video);
  }
}

class DemoTemplatesRepository implements TemplatesRepository {
  final DemoStore store;
  DemoTemplatesRepository(this.store);

  @override
  Stream<List<ProtocolTemplate>> watchTemplates() => store.templates.watch();

  @override
  Future<Result<ProtocolTemplate>> saveTemplate(ProtocolTemplate template) async {
    store.templates.update((list) => [...list, template]);
    return Ok(template);
  }
}

class DemoAssignmentsRepository implements AssignmentsRepository {
  final DemoStore store;
  DemoAssignmentsRepository(this.store);

  @override
  Stream<List<Assignment>> watchForPatient(String patientId) =>
      store.assignments.watch().map((list) => list.where((a) => a.patientId == patientId).toList());

  @override
  Stream<List<Assignment>> watchAll() => store.assignments.watch();

  @override
  Future<Result<Assignment>> create(Assignment assignment) async {
    if (assignment.items.isEmpty) return const Err('An assignment needs at least one exercise');
    store.assignments.update((list) => [...list, assignment]);
    final usedIds = assignment.items.map((i) => i.videoId).toSet();
    store.videos.update((list) => [
          for (final v in list)
            usedIds.contains(v.id) ? v.copyWith(usageCount: v.usageCount + 1) : v
        ]);
    return Ok(assignment);
  }

  @override
  Future<Result<void>> markSeen(String assignmentId) async {
    store.assignments.update((list) => [
          for (final a in list)
            a.id == assignmentId && !a.seenByPatient ? a.copyWith(seenByPatient: true) : a
        ]);
    return const Ok(null);
  }
}

class DemoCompletionsRepository implements CompletionsRepository {
  final DemoStore store;
  DemoCompletionsRepository(this.store);

  @override
  Stream<List<Completion>> watchForPatient(String patientId) =>
      store.completions.watch().map((m) => List.unmodifiable(m[patientId] ?? const []));

  @override
  Stream<Map<String, List<Completion>>> watchAllByPatient() => store.completions.watch();

  @override
  Future<Result<void>> record(String patientId, Completion completion) async {
    store.completions.update((m) {
      final list = List<Completion>.of(m[patientId] ?? const []);
      final idx = list.indexWhere((c) => c.id == completion.id);
      if (idx >= 0) {
        list[idx] = completion; // upsert: deterministic ID (§9)
      } else {
        list.add(completion);
      }
      return {...m, patientId: list};
    });
    // A recorded outcome is activity — keep the physio's last-active fresh.
    store.patients.update((list) => [
          for (final p in list)
            p.id == patientId ? p.copyWith(lastActiveAt: completion.at) : p
        ]);
    return const Ok(null);
  }
}
