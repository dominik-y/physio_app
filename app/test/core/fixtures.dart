import 'package:physio_app/domain/models.dart';

const allWeek = {1, 2, 3, 4, 5, 6, 7};

ExerciseItem item(String videoId, int order, {int sets = 3, int reps = 10, int holdSec = 0}) =>
    ExerciseItem(
      videoId: videoId,
      order: order,
      sets: sets,
      reps: reps,
      holdSec: holdSec,
      title: 'Exercise $videoId',
      durationSec: 90,
      bodyPart: 'Knee',
    );

Assignment protocol(
  String id, {
  String patientId = 'p1',
  required List<ExerciseItem> items,
  Set<int> daysOfWeek = allWeek,
  required DateTime createdAt,
  String? name,
  bool active = true,
  bool seen = true,
}) =>
    Assignment(
      id: id,
      patientId: patientId,
      type: AssignmentType.protocol,
      name: name ?? 'Protocol $id',
      bodyParts: const ['Knee'],
      daysOfWeek: daysOfWeek,
      items: items,
      active: active,
      seenByPatient: seen,
      createdAt: createdAt,
    );

Assignment single(String id, {String patientId = 'p1', required DateTime createdAt}) => Assignment(
      id: id,
      patientId: patientId,
      type: AssignmentType.single,
      name: 'Single $id',
      bodyParts: const ['Knee'],
      daysOfWeek: allWeek,
      items: [item('v-$id', 0)],
      seenByPatient: false,
      createdAt: createdAt,
    );

Completion outcome(String date, String assignmentId, String videoId, CompletionStatus status) =>
    Completion.forDay(
      date: date,
      assignmentId: assignmentId,
      videoId: videoId,
      status: status,
      at: DateTime.parse('$date 12:00:00'),
    );
