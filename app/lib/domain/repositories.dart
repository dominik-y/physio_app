import 'package:physio_app/core/result.dart';
import 'package:physio_app/domain/models.dart';

abstract class PatientsRepository {
  Stream<List<Patient>> watchPatients();
  Stream<Patient?> watchPatient(String id);
  Future<Result<Patient>> addPatient({required String name, required String email});
  Future<Result<void>> updateNotes(String patientId, String notes);

  /// Returns the new single-use code (spec §3.2).
  Future<Result<String>> regenerateInvite(String patientId);
}

abstract class LibraryRepository {
  Stream<List<VideoItem>> watchVideos();
  Future<Result<VideoItem>> addVideo({
    required String title,
    required String bodyPart,
    required int durationSec,
    String? privateToPatientId,
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
