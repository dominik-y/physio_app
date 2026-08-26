import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physio_app/core/result.dart';
import 'package:physio_app/core/streams.dart';
import 'package:physio_app/data/firebase/mappers.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/domain/repository_bundle.dart';

/// Firestore-backed bundle for the Firebase flavor. [forPhysio] decides
/// whether patient docs are enriched with clinical notes (physio-only
/// `patientNotes` collection — a patient session may not read it, and a
/// stream error there would kill the merged stream).
RepositoryBundle firestoreRepositoryBundle(
  FirebaseFirestore db, {
  required bool forPhysio,
}) =>
    RepositoryBundle(
      patients: FirestorePatientsRepository(db, includeNotes: forPhysio),
      library: FirestoreLibraryRepository(db),
      templates: FirestoreTemplatesRepository(db),
      assignments: FirestoreAssignmentsRepository(db),
      completions: FirestoreCompletionsRepository(db),
    );

/// Every write funnels through this: exceptions become Err, values Ok —
/// the Result contract means no Firebase exception crosses a layer boundary.
Future<Result<T>> _guard<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on FirebaseException catch (e) {
    return Err(e.message ?? e.code);
  } catch (e) {
    return Err('$e');
  }
}

class FirestorePatientsRepository implements PatientsRepository {
  final FirebaseFirestore db;
  final bool includeNotes;
  FirestorePatientsRepository(this.db, {required this.includeNotes});

  CollectionReference<Map<String, dynamic>> get _patients =>
      db.collection('patients');

  Stream<Map<String, String>> _notesById() => db
      .collection('patientNotes')
      .snapshots()
      .map((snap) => {
            for (final d in snap.docs)
              d.id: (d.data()['notes'] as String?) ?? '',
          });

  @override
  Stream<List<Patient>> watchPatients() {
    final patients = _patients.orderBy('createdAt').snapshots().map(
        (snap) => [for (final d in snap.docs) (id: d.id, data: d.data())]);
    if (!includeNotes) {
      return patients.map(
          (rows) => [for (final r in rows) patientFromDoc(r.id, r.data)]);
    }
    return combineLatest2(patients, _notesById(),
        (rows, notes) => [
              for (final r in rows)
                patientFromDoc(r.id, r.data, notes: notes[r.id] ?? '')
            ]);
  }

  @override
  Stream<Patient?> watchPatient(String id) {
    final patient = _patients.doc(id).snapshots().map(
        (d) => d.exists ? (id: d.id, data: d.data()!) : null);
    if (!includeNotes) {
      return patient.map((r) => r == null ? null : patientFromDoc(r.id, r.data));
    }
    return combineLatest2(patient, _notesById(),
        (r, notes) =>
            r == null ? null : patientFromDoc(r.id, r.data, notes: notes[r.id] ?? ''));
  }

  @override
  Future<Result<Patient>> addPatient(
      {required String name, required String email}) {
    if (name.trim().isEmpty) return Future.value(const Err('Name is required'));
    return _guard(() async {
      final now = DateTime.now();
      final code = generateInviteCode(Random.secure());
      final patient = Patient(
        id: _patients.doc().id,
        name: name.trim(),
        email: email.trim(),
        inviteCode: code,
        inviteExpiresAt: now.add(const Duration(days: 14)),
        createdAt: now,
      );
      final batch = db.batch();
      batch.set(_patients.doc(patient.id), patientToMap(patient));
      batch.set(db.collection('invites').doc(code), {
        'patientId': patient.id,
        'expiresAt': Timestamp.fromDate(patient.inviteExpiresAt!),
        'createdAt': Timestamp.fromDate(now),
        'createdBy': null, // filled by auth layer wiring later if needed
        'redeemed': false,
        'redeemedBy': null,
        'redeemedAt': null,
      });
      await batch.commit();
      return patient;
    });
  }

  @override
  Future<Result<void>> updateNotes(String patientId, String notes) =>
      _guard(() => db.collection('patientNotes').doc(patientId).set({
            'notes': notes,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)));

  @override
  Future<Result<String>> regenerateInvite(String patientId) =>
      _guard(() async {
        final snap = await _patients.doc(patientId).get();
        final oldCode = snap.data()?['inviteCode'] as String?;
        final code = generateInviteCode(Random.secure());
        final now = DateTime.now();
        final expires = now.add(const Duration(days: 14));
        final batch = db.batch();
        if (oldCode != null) {
          batch.delete(db.collection('invites').doc(oldCode));
        }
        batch.set(db.collection('invites').doc(code), {
          'patientId': patientId,
          'expiresAt': Timestamp.fromDate(expires),
          'createdAt': Timestamp.fromDate(now),
          'createdBy': null,
          'redeemed': false,
          'redeemedBy': null,
          'redeemedAt': null,
        });
        batch.update(_patients.doc(patientId), {
          'inviteCode': code,
          'inviteExpiresAt': Timestamp.fromDate(expires),
        });
        await batch.commit();
        return code;
      });

  @override
  Future<Result<void>> deletePatient(String patientId) => _guard(() async {
        // Firestore has no cascade: delete dependents in chunked batches,
        // the patient doc last — a mid-way failure is fixed by re-running.
        final assignments = await db
            .collection('assignments')
            .where('patientId', isEqualTo: patientId)
            .get();
        final completions = await db
            .collection('completions')
            .where('patientId', isEqualTo: patientId)
            .get();
        final refs = [
          for (final d in completions.docs) d.reference,
          for (final d in assignments.docs) d.reference,
        ];
        for (var i = 0; i < refs.length; i += 450) {
          final batch = db.batch();
          for (final ref in refs.skip(i).take(450)) {
            batch.delete(ref);
          }
          await batch.commit();
        }
        final snap = await _patients.doc(patientId).get();
        final inviteCode = snap.data()?['inviteCode'] as String?;
        final last = db.batch();
        if (inviteCode != null) {
          last.delete(db.collection('invites').doc(inviteCode));
        }
        last.delete(db.collection('patientNotes').doc(patientId));
        last.delete(_patients.doc(patientId));
        await last.commit();
      });
}

/// 7 chars from an ambiguity-free alphabet, formatted XXX-XXXX. The dashed
/// form IS the invite doc ID — no display/storage conversion anywhere.
String generateInviteCode(Random rng) {
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  final chars =
      List.generate(7, (_) => alphabet[rng.nextInt(alphabet.length)]);
  return '${chars.sublist(0, 3).join()}-${chars.sublist(3).join()}';
}

class FirestoreLibraryRepository implements LibraryRepository {
  final FirebaseFirestore db;
  FirestoreLibraryRepository(this.db);

  @override
  Stream<List<VideoItem>> watchVideos() =>
      db.collection('videos').orderBy('createdAt').snapshots().map(
          (snap) => [for (final d in snap.docs) videoFromDoc(d.id, d.data())]);

  @override
  Future<Result<VideoItem>> addVideo({
    required String title,
    required String bodyPart,
    required int durationSec,
    String? privateToPatientId,
  }) {
    if (title.trim().isEmpty) {
      return Future.value(const Err('Title is required'));
    }
    return _guard(() async {
      final ref = db.collection('videos').doc();
      final video = VideoItem(
        id: ref.id,
        title: title.trim(),
        bodyPart: bodyPart,
        durationSec: durationSec,
        visibility: privateToPatientId == null ? 'library' : 'private',
        privateToPatientId: privateToPatientId,
        createdAt: DateTime.now(),
      );
      await ref.set(videoToMap(video));
      return video;
    });
  }
}

class FirestoreTemplatesRepository implements TemplatesRepository {
  final FirebaseFirestore db;
  FirestoreTemplatesRepository(this.db);

  @override
  Stream<List<ProtocolTemplate>> watchTemplates() =>
      db.collection('templates').orderBy('createdAt').snapshots().map((snap) =>
          [for (final d in snap.docs) templateFromDoc(d.id, d.data())]);

  @override
  Future<Result<ProtocolTemplate>> saveTemplate(ProtocolTemplate template) =>
      _guard(() async {
        // Owner call: set-by-id — templates gain update semantics in
        // production (demo stays append-only).
        final id = template.id.isEmpty
            ? db.collection('templates').doc().id
            : template.id;
        await db.collection('templates').doc(id).set(templateToMap(template));
        return ProtocolTemplate(
          id: id,
          name: template.name,
          bodyPart: template.bodyPart,
          items: template.items,
          createdAt: template.createdAt,
        );
      });
}

class FirestoreAssignmentsRepository implements AssignmentsRepository {
  final FirebaseFirestore db;
  FirestoreAssignmentsRepository(this.db);

  @override
  Stream<List<Assignment>> watchForPatient(String patientId) => db
      .collection('assignments')
      .where('patientId', isEqualTo: patientId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          [for (final d in snap.docs) assignmentFromDoc(d.id, d.data())]);

  @override
  Stream<List<Assignment>> watchAll() => db
      .collection('assignments')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          [for (final d in snap.docs) assignmentFromDoc(d.id, d.data())]);

  @override
  Future<Result<Assignment>> create(Assignment assignment) {
    if (assignment.items.isEmpty) {
      return Future.value(const Err('An assignment needs at least one exercise'));
    }
    return _guard(() async {
      final id = assignment.id.isEmpty
          ? db.collection('assignments').doc().id
          : assignment.id;
      final batch = db.batch();
      batch.set(db.collection('assignments').doc(id),
          assignmentToMap(assignment));
      for (final videoId in assignment.items.map((i) => i.videoId).toSet()) {
        batch.update(db.collection('videos').doc(videoId),
            {'usageCount': FieldValue.increment(1)});
      }
      await batch.commit();
      return assignment;
    });
  }

  @override
  Future<Result<void>> markSeen(String assignmentId) =>
      _guard(() => db
          .collection('assignments')
          .doc(assignmentId)
          .update({'seenByPatient': true}));
}

class FirestoreCompletionsRepository implements CompletionsRepository {
  final FirebaseFirestore db;
  FirestoreCompletionsRepository(this.db);

  @override
  Stream<List<Completion>> watchForPatient(String patientId) => db
      .collection('completions')
      .where('patientId', isEqualTo: patientId)
      .snapshots()
      .map((snap) =>
          [for (final d in snap.docs) completionFromDoc(d.id, d.data())]);

  @override
  Stream<Map<String, List<Completion>>> watchAllByPatient() =>
      db.collection('completions').snapshots().map((snap) {
        final byPatient = <String, List<Completion>>{};
        for (final d in snap.docs) {
          final pid = d.data()['patientId'] as String;
          (byPatient[pid] ??= []).add(completionFromDoc(d.id, d.data()));
        }
        return byPatient;
      });

  @override
  Future<Result<void>> record(String patientId, Completion completion) =>
      _guard(() async {
        // Upsert on the deterministic ID + last-active bump, one atomic
        // batch — the shape the completions/patients rules validate.
        final batch = db.batch();
        batch.set(db.collection('completions').doc(completion.id),
            completionToMapFor(patientId, completion));
        batch.update(db.collection('patients').doc(patientId),
            {'lastActiveAt': Timestamp.fromDate(completion.at)});
        await batch.commit();
      });
}
