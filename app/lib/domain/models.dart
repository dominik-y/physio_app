import 'package:equatable/equatable.dart';

enum UserRole { physio, patient }

enum AssignmentType { protocol, single }

enum CompletionStatus { done, skipped }

class Patient extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? uid; // set on invite redemption; demo: non-null = redeemed
  final String notes;
  final String? primaryBodyPart;
  final DateTime? lastActiveAt;
  final String? inviteCode;
  final DateTime? inviteExpiresAt;
  final DateTime createdAt;

  const Patient({
    required this.id,
    required this.name,
    required this.email,
    this.uid,
    this.notes = '',
    this.primaryBodyPart,
    this.lastActiveAt,
    this.inviteCode,
    this.inviteExpiresAt,
    required this.createdAt,
  });

  bool get redeemed => uid != null;

  Patient copyWith({
    String? name,
    String? email,
    String? uid,
    String? notes,
    String? primaryBodyPart,
    DateTime? lastActiveAt,
    String? inviteCode,
    DateTime? inviteExpiresAt,
  }) =>
      Patient(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        uid: uid ?? this.uid,
        notes: notes ?? this.notes,
        primaryBodyPart: primaryBodyPart ?? this.primaryBodyPart,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        inviteCode: inviteCode ?? this.inviteCode,
        inviteExpiresAt: inviteExpiresAt ?? this.inviteExpiresAt,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, name, email, uid, notes, primaryBodyPart, lastActiveAt, inviteCode, inviteExpiresAt, createdAt];
}

class VideoItem extends Equatable {
  final String id;
  final String title;
  final String bodyPart;
  final int durationSec;

  /// 'library' or 'private' (spec §4.2).
  final String visibility;
  final String? privateToPatientId;
  final int usageCount;
  final DateTime createdAt;

  const VideoItem({
    required this.id,
    required this.title,
    required this.bodyPart,
    required this.durationSec,
    this.visibility = 'library',
    this.privateToPatientId,
    this.usageCount = 0,
    required this.createdAt,
  });

  bool get isPrivate => visibility == 'private';

  VideoItem copyWith({String? title, String? bodyPart, int? durationSec, int? usageCount}) => VideoItem(
        id: id,
        title: title ?? this.title,
        bodyPart: bodyPart ?? this.bodyPart,
        durationSec: durationSec ?? this.durationSec,
        visibility: visibility,
        privateToPatientId: privateToPatientId,
        usageCount: usageCount ?? this.usageCount,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, bodyPart, durationSec, visibility, privateToPatientId, usageCount, createdAt];
}

class TemplateItem extends Equatable {
  final String videoId;
  final int order;
  final int sets;
  final int reps;
  final int holdSec;

  const TemplateItem({
    required this.videoId,
    required this.order,
    required this.sets,
    required this.reps,
    this.holdSec = 0,
  });

  @override
  List<Object?> get props => [videoId, order, sets, reps, holdSec];
}

class ProtocolTemplate extends Equatable {
  final String id;
  final String name;
  final String bodyPart;
  final List<TemplateItem> items;
  final DateTime createdAt;

  const ProtocolTemplate({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.items,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, bodyPart, items, createdAt];
}

/// One exercise inside an assignment. Video metadata is denormalized at
/// assign time (spec §4.7) — patients never read the library.
class ExerciseItem extends Equatable {
  final String videoId;
  final int order;
  final int sets;
  final int reps;
  final int holdSec;

  /// Differs from the source template default (spec §6.3).
  final bool overridden;
  final String title;
  final int durationSec;
  final String bodyPart;

  const ExerciseItem({
    required this.videoId,
    required this.order,
    required this.sets,
    required this.reps,
    this.holdSec = 0,
    this.overridden = false,
    required this.title,
    required this.durationSec,
    required this.bodyPart,
  });

  ExerciseItem copyWith({int? order, int? sets, int? reps, int? holdSec, bool? overridden}) => ExerciseItem(
        videoId: videoId,
        order: order ?? this.order,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        holdSec: holdSec ?? this.holdSec,
        overridden: overridden ?? this.overridden,
        title: title,
        durationSec: durationSec,
        bodyPart: bodyPart,
      );

  @override
  List<Object?> get props => [videoId, order, sets, reps, holdSec, overridden, title, durationSec, bodyPart];
}

class Assignment extends Equatable {
  final String id;
  final String patientId;
  final AssignmentType type;
  final String name;

  /// Provenance only, never followed (snapshot-on-assign, spec §4.4).
  final String? sourceTemplateId;
  final List<String> bodyParts;

  /// ISO 1=Mon..7=Sun. Daily is {1,...,7}.
  final Set<int> daysOfWeek;
  final List<ExerciseItem> items;
  final bool active;

  /// New badge lifecycle (spec §5.4): false until the patient first opens it.
  final bool seenByPatient;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.patientId,
    required this.type,
    required this.name,
    this.sourceTemplateId,
    required this.bodyParts,
    required this.daysOfWeek,
    required this.items,
    this.active = true,
    this.seenByPatient = false,
    required this.createdAt,
  })  : assert(daysOfWeek.every((d) => d >= 1 && d <= 7), 'daysOfWeek must be ISO 1..7'),
        // The deterministic completion ID {date}_{assignmentId}_{videoId}
        // requires each video to appear at most once per assignment.
        assert(items.map((i) => i.videoId).toSet().length == items.length,
            'an assignment may not contain the same video twice');

  Assignment copyWith({bool? active, bool? seenByPatient}) => Assignment(
        id: id,
        patientId: patientId,
        type: type,
        name: name,
        sourceTemplateId: sourceTemplateId,
        bodyParts: bodyParts,
        daysOfWeek: daysOfWeek,
        items: items,
        active: active ?? this.active,
        seenByPatient: seenByPatient ?? this.seenByPatient,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, patientId, type, name, sourceTemplateId, bodyParts, daysOfWeek, items, active, seenByPatient, createdAt];
}

class Completion extends Equatable {
  /// Deterministic: one outcome per exercise per day (spec §9). A double-tap
  /// or retry overwrites instead of duplicating.
  final String id;
  final String date; // 'YYYY-MM-DD', local
  final String assignmentId;
  final String videoId;
  final CompletionStatus status;
  final DateTime at;

  const Completion({
    required this.id,
    required this.date,
    required this.assignmentId,
    required this.videoId,
    required this.status,
    required this.at,
  });

  static String idFor(String date, String assignmentId, String videoId) => '${date}_${assignmentId}_$videoId';

  factory Completion.forDay({
    required String date,
    required String assignmentId,
    required String videoId,
    required CompletionStatus status,
    required DateTime at,
  }) =>
      Completion(
        id: idFor(date, assignmentId, videoId),
        date: date,
        assignmentId: assignmentId,
        videoId: videoId,
        status: status,
        at: at,
      );

  @override
  List<Object?> get props => [id, date, assignmentId, videoId, status, at];
}
