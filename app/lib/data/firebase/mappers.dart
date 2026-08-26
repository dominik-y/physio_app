import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physio_app/domain/models.dart';

/// Pure toMap/fromDoc converters between domain models and Firestore doc
/// shapes. No I/O — round-trip unit-tested in test/data/mappers_test.dart.
///
/// Conventions:
/// - Doc IDs are never stored inside the doc; fromDoc takes them separately.
/// - Enums travel as their `.name`.
/// - `Set<int>` daysOfWeek travels as a sorted array.
/// - `Completion.date` stays a 'YYYY-MM-DD' string (the doc ID embeds it).
/// - Clinical notes are NOT on the patient doc: they live in the physio-only
///   `patientNotes/{patientId}` collection; the repository merges them in.

DateTime? _toDate(Object? v) => v == null ? null : (v as Timestamp).toDate();
Timestamp? _toTs(DateTime? v) => v == null ? null : Timestamp.fromDate(v);

// ---------------------------------------------------------------- patients

Map<String, Object?> patientToMap(Patient p) => {
      'name': p.name,
      'email': p.email,
      'uid': p.uid,
      'primaryBodyPart': p.primaryBodyPart,
      'lastActiveAt': _toTs(p.lastActiveAt),
      'inviteCode': p.inviteCode,
      'inviteExpiresAt': _toTs(p.inviteExpiresAt),
      'createdAt': Timestamp.fromDate(p.createdAt),
    };

Patient patientFromDoc(String id, Map<String, Object?> d, {String notes = ''}) =>
    Patient(
      id: id,
      name: d['name'] as String,
      email: d['email'] as String,
      uid: d['uid'] as String?,
      notes: notes,
      primaryBodyPart: d['primaryBodyPart'] as String?,
      lastActiveAt: _toDate(d['lastActiveAt']),
      inviteCode: d['inviteCode'] as String?,
      inviteExpiresAt: _toDate(d['inviteExpiresAt']),
      createdAt: _toDate(d['createdAt'])!,
    );

// ------------------------------------------------------------------ videos

Map<String, Object?> videoToMap(VideoItem v) => {
      'title': v.title,
      'bodyPart': v.bodyPart,
      'durationSec': v.durationSec,
      'visibility': v.visibility,
      'privateToPatientId': v.privateToPatientId,
      'usageCount': v.usageCount,
      'createdAt': Timestamp.fromDate(v.createdAt),
      'mediaUrl': v.mediaUrl,
      'posterUrl': v.posterUrl,
      'storagePath': v.storagePath,
      'status': v.status,
    };

VideoItem videoFromDoc(String id, Map<String, Object?> d) => VideoItem(
      id: id,
      title: d['title'] as String,
      bodyPart: d['bodyPart'] as String,
      durationSec: d['durationSec'] as int,
      visibility: d['visibility'] as String? ?? 'library',
      privateToPatientId: d['privateToPatientId'] as String?,
      usageCount: d['usageCount'] as int? ?? 0,
      createdAt: _toDate(d['createdAt'])!,
      mediaUrl: d['mediaUrl'] as String?,
      posterUrl: d['posterUrl'] as String?,
      storagePath: d['storagePath'] as String?,
      status: d['status'] as String? ?? 'ready',
    );

// --------------------------------------------------------------- templates

Map<String, Object?> templateToMap(ProtocolTemplate t) => {
      'name': t.name,
      'bodyPart': t.bodyPart,
      'items': [
        for (final i in t.items)
          {
            'videoId': i.videoId,
            'order': i.order,
            'sets': i.sets,
            'reps': i.reps,
            'holdSec': i.holdSec,
          }
      ],
      'createdAt': Timestamp.fromDate(t.createdAt),
    };

ProtocolTemplate templateFromDoc(String id, Map<String, Object?> d) =>
    ProtocolTemplate(
      id: id,
      name: d['name'] as String,
      bodyPart: d['bodyPart'] as String,
      items: [
        for (final raw in d['items'] as List)
          TemplateItem(
            videoId: (raw as Map)['videoId'] as String,
            order: raw['order'] as int,
            sets: raw['sets'] as int,
            reps: raw['reps'] as int,
            holdSec: raw['holdSec'] as int? ?? 0,
          )
      ],
      createdAt: _toDate(d['createdAt'])!,
    );

// ------------------------------------------------------------- assignments

Map<String, Object?> assignmentToMap(Assignment a) => {
      'patientId': a.patientId,
      'type': a.type.name,
      'name': a.name,
      'sourceTemplateId': a.sourceTemplateId,
      'bodyParts': a.bodyParts,
      'daysOfWeek': a.daysOfWeek.toList()..sort(),
      'items': [
        for (final i in a.items)
          {
            'videoId': i.videoId,
            'order': i.order,
            'sets': i.sets,
            'reps': i.reps,
            'holdSec': i.holdSec,
            'overridden': i.overridden,
            'title': i.title,
            'durationSec': i.durationSec,
            'bodyPart': i.bodyPart,
            'mediaUrl': i.mediaUrl,
            'posterUrl': i.posterUrl,
          }
      ],
      'active': a.active,
      'seenByPatient': a.seenByPatient,
      'createdAt': Timestamp.fromDate(a.createdAt),
    };

Assignment assignmentFromDoc(String id, Map<String, Object?> d) => Assignment(
      id: id,
      patientId: d['patientId'] as String,
      type: AssignmentType.values.byName(d['type'] as String),
      name: d['name'] as String,
      sourceTemplateId: d['sourceTemplateId'] as String?,
      bodyParts: (d['bodyParts'] as List).cast<String>(),
      daysOfWeek: (d['daysOfWeek'] as List).cast<int>().toSet(),
      items: [
        for (final raw in d['items'] as List)
          ExerciseItem(
            videoId: (raw as Map)['videoId'] as String,
            order: raw['order'] as int,
            sets: raw['sets'] as int,
            reps: raw['reps'] as int,
            holdSec: raw['holdSec'] as int? ?? 0,
            overridden: raw['overridden'] as bool? ?? false,
            title: raw['title'] as String,
            durationSec: raw['durationSec'] as int,
            bodyPart: raw['bodyPart'] as String,
            mediaUrl: raw['mediaUrl'] as String?,
            posterUrl: raw['posterUrl'] as String?,
          )
      ],
      active: d['active'] as bool? ?? true,
      seenByPatient: d['seenByPatient'] as bool? ?? false,
      createdAt: _toDate(d['createdAt'])!,
    );

// ------------------------------------------------------------- completions

Map<String, Object?> completionToMap(Completion c) => {
      'patientId': null, // caller fills in: the domain model doesn't carry it
      'date': c.date,
      'assignmentId': c.assignmentId,
      'videoId': c.videoId,
      'status': c.status.name,
      'at': Timestamp.fromDate(c.at),
    };

/// The rules require patientId on the doc; the domain Completion doesn't
/// carry it (completions are keyed per patient upstream), so the repository
/// passes it explicitly.
Map<String, Object?> completionToMapFor(String patientId, Completion c) =>
    {...completionToMap(c), 'patientId': patientId};

Completion completionFromDoc(String id, Map<String, Object?> d) => Completion(
      id: id,
      date: d['date'] as String,
      assignmentId: d['assignmentId'] as String,
      videoId: d['videoId'] as String,
      status: CompletionStatus.values.byName(d['status'] as String),
      at: _toDate(d['at'])!,
    );
