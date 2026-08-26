import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/data/firebase/mappers.dart';
import 'package:physio_app/domain/models.dart';

// Pure round-trip tests — Timestamp is plain Dart, no plugin channel needed.
void main() {
  final createdAt = DateTime(2026, 8, 20, 10, 30);
  final lastActive = DateTime(2026, 8, 25, 18, 5);

  group('mappers round-trip', () {
    test('Patient (notes live outside the doc and merge back in)', () {
      final p = Patient(
        id: 'pat-1',
        name: 'Ana Kovačević',
        email: 'ana@example.com',
        uid: 'ana-uid',
        notes: 'Oprez s desnim koljenom',
        primaryBodyPart: 'Knee',
        lastActiveAt: lastActive,
        inviteCode: 'LK7-3FQ9',
        inviteExpiresAt: createdAt,
        createdAt: createdAt,
      );
      final map = patientToMap(p);
      expect(map.containsKey('notes'), isFalse,
          reason: 'notes are physio-only (patientNotes collection)');
      expect(patientFromDoc('pat-1', map, notes: p.notes), p);
    });

    test('Patient with nullable fields null', () {
      final p = Patient(
        id: 'pat-2',
        name: 'Luka Babić',
        email: 'luka@example.com',
        createdAt: createdAt,
      );
      expect(patientFromDoc('pat-2', patientToMap(p)), p);
    });

    test('VideoItem with media fields', () {
      final v = VideoItem(
        id: 'v-1',
        title: 'Klizanje petom',
        bodyPart: 'Knee',
        durationSec: 60,
        visibility: 'private',
        privateToPatientId: 'pat-1',
        usageCount: 3,
        createdAt: createdAt,
        mediaUrl: 'https://example.com/v.mp4',
        posterUrl: 'https://example.com/p.jpg',
        storagePath: 'clinics/tendo/videos/v-1/video.mp4',
        status: 'ready',
      );
      expect(videoFromDoc('v-1', videoToMap(v)), v);
    });

    test('VideoItem demo-shaped (media fields null)', () {
      final v = VideoItem(
        id: 'v-2',
        title: 'Most',
        bodyPart: 'Lower back',
        durationSec: 45,
        createdAt: createdAt,
      );
      expect(videoFromDoc('v-2', videoToMap(v)), v);
    });

    test('ProtocolTemplate with items', () {
      final t = ProtocolTemplate(
        id: 't-1',
        name: 'Oporavak meniskusa',
        bodyPart: 'Knee',
        items: const [
          TemplateItem(videoId: 'v-1', order: 0, sets: 3, reps: 10),
          TemplateItem(videoId: 'v-2', order: 1, sets: 2, reps: 8, holdSec: 20),
        ],
        createdAt: createdAt,
      );
      expect(templateFromDoc('t-1', templateToMap(t)), t);
    });

    test('Assignment: enums, daysOfWeek set, denormalized items', () {
      final a = Assignment(
        id: 'as-1',
        patientId: 'pat-1',
        type: AssignmentType.protocol,
        name: 'Oporavak meniskusa — faza 1',
        sourceTemplateId: 't-1',
        bodyParts: const ['Knee'],
        daysOfWeek: const {7, 1, 3},
        items: const [
          ExerciseItem(
            videoId: 'v-1',
            order: 0,
            sets: 3,
            reps: 10,
            holdSec: 15,
            overridden: true,
            title: 'Klizanje petom',
            durationSec: 60,
            bodyPart: 'Knee',
            mediaUrl: 'https://example.com/v.mp4',
            posterUrl: 'https://example.com/p.jpg',
          ),
        ],
        active: false,
        seenByPatient: true,
        createdAt: createdAt,
      );
      final map = assignmentToMap(a);
      expect(map['daysOfWeek'], [1, 3, 7], reason: 'sorted array on the wire');
      expect(map['type'], 'protocol');
      expect(assignmentFromDoc('as-1', map), a);
    });

    test('Completion: date string preserved, patientId injected for rules', () {
      final c = Completion.forDay(
        date: '2026-08-25',
        assignmentId: 'as-1',
        videoId: 'v-1',
        status: CompletionStatus.skipped,
        at: lastActive,
      );
      final map = completionToMapFor('pat-1', c);
      expect(map['patientId'], 'pat-1');
      expect(map['date'], '2026-08-25');
      expect(c.id, '2026-08-25_as-1_v-1');
      expect(completionFromDoc(c.id, map), c);
    });
  });
}
