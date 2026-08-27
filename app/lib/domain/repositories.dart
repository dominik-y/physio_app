import 'package:physio_app/core/result.dart';
import 'package:physio_app/domain/media_uploader.dart';
import 'package:physio_app/domain/models.dart';

abstract class PatientsRepository {
  Stream<List<Patient>> watchPatients();
  Stream<Patient?> watchPatient(String id);
  Future<Result<Patient>> addPatient({required String name, required String email});
  Future<Result<void>> updateNotes(String patientId, String notes);

  /// Returns the new single-use code (spec §3.2).
  Future<Result<String>> regenerateInvite(String patientId);

  /// Removes the patient and everything hanging off them (assignments,
  /// completion history). Owner request 2026-08-25: swipe-to-delete.
  Future<Result<void>> deletePatient(String patientId);
}

abstract class LibraryRepository {
  Stream<List<VideoItem>> watchVideos();

  /// [media] is the finished Storage upload (Firebase flavor, upload-first:
  /// the doc is only created once its media exists, so status is 'ready' on
  /// create and no doc can ever reference a missing file). Demo ignores it.
  Future<Result<VideoItem>> addVideo({
    required String title,
    required String bodyPart,
    required int durationSec,
    String? privateToPatientId,
    MediaUploadResult? media,
  });
}

abstract class TemplatesRepository {
  Stream<List<ProtocolTemplate>> watchTemplates();
  Future<Result<ProtocolTemplate>> saveTemplate(ProtocolTemplate template);
}

abstract class AssignmentsRepository {
  Stream<List<Assignment>> watchForPatient(String patientId);
  Stream<List<Assignment>> watchAll();

  /// Also increments usageCount on each referenced library video.
  Future<Result<Assignment>> create(Assignment assignment);

  /// Clears the New badge (spec §5.4).
  Future<Result<void>> markSeen(String assignmentId);
}

abstract class CompletionsRepository {
  Stream<List<Completion>> watchForPatient(String patientId);
  Stream<Map<String, List<Completion>>> watchAllByPatient();

  /// UPSERT by completion.id (spec §9 deterministic ID).
  Future<Result<void>> record(String patientId, Completion completion);
}
