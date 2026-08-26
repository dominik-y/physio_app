import 'package:physio_app/domain/repositories.dart';

/// The five repository implementations an app flavor provides. The demo
/// entrypoint builds an in-memory bundle (data/demo_repositories.dart); the
/// Firebase entrypoint will build a Firestore-backed one. app/app.dart is
/// flavor-agnostic and only ever sees this.
class RepositoryBundle {
  final PatientsRepository patients;
  final LibraryRepository library;
  final TemplatesRepository templates;
  final AssignmentsRepository assignments;
  final CompletionsRepository completions;

  const RepositoryBundle({
    required this.patients,
    required this.library,
    required this.templates,
    required this.assignments,
    required this.completions,
  });
}
