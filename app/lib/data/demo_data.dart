import 'package:physio_app/core/dates.dart';
import 'package:physio_app/domain/models.dart';

/// Seeded showcase fixture (spec §15.1): one practice, six patients in
/// deliberately different states, a small library, three templates, and three
/// weeks of generated completion history. All history is generated relative
/// to [now] via [Dates.scheduledDatesBetween] — never hand-written dates.
class DemoData {
  static const String physioName = 'Tomislav Perić, mag. physioth.';
  static const String currentPatientId = 'pat-ana';
  static const String currentPatientName = 'Ana Kovačević';

  // Named fixture IDs so tests can address specific patient states.
  static const String adherentPatientId = 'pat-ivana';
  static const String skippingPatientId = 'pat-marko';
  static const String twoProtocolPatientId = 'pat-ana';
  static const String silentPatientId = 'pat-josip';
  static const String newTodayPatientId = 'pat-petra';
  static const String unredeemedPatientId = 'pat-luka';

  final List<Patient> patients;
  final List<VideoItem> videos;
  final List<ProtocolTemplate> templates;
  final List<Assignment> assignments;
  final Map<String, List<Completion>> completionsByPatient;

  DemoData._({
    required this.patients,
    required this.videos,
    required this.templates,
    required this.assignments,
    required this.completionsByPatient,
  });

  factory DemoData.seed(DateTime now) {
    final today = Dates.dateOnly(now);
    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);

    // ---- Library -----------------------------------------------------------
    VideoItem video(String id, String title, String bodyPart, int durationSec,
            {String? privateTo, int createdDaysAgo = 60}) =>
        VideoItem(
          id: id,
          title: title,
          bodyPart: bodyPart,
          durationSec: durationSec,
          visibility: privateTo == null ? 'library' : 'private',
          privateToPatientId: privateTo,
          createdAt: daysAgo(createdDaysAgo),
        );

    final videos = <VideoItem>[
      video('v-quad', 'Ekstenzija koljena u sjedu', 'Knee', 105),
      video('v-heel', 'Klizanje petom', 'Knee', 90),
      video('v-bridge', 'Glutealni most', 'Knee', 120),
      video('v-step', 'Kontrolirani uspon na step', 'Knee', 100),
      video('v-pend', 'Pendularne kretnje', 'Shoulder', 80),
      video('v-wall', 'Klizanje uz zid', 'Shoulder', 95),
      video('v-band', 'Vanjska rotacija s trakom', 'Shoulder', 110),
      video('v-cat', 'Mačka–deva', 'Lower back', 85),
      video('v-bird', 'Ptica-pas', 'Lower back', 115),
      video('v-pelvic', 'Nagib zdjelice', 'Lower back', 75),
      video('v-chin', 'Uvlačenje brade', 'Neck', 60),
      // Real Tendo footage (their Instagram reel, owner-approved 2026-08-25) —
      // media registered as a bundled asset in PhysioApp.
      video('v-tendo-drill', 'Agilnost — rad s loptom', 'Knee', 18,
          createdDaysAgo: 5),
      video('v-ana-focus', 'Ana — fokus na koljeno ovaj tjedan', 'Knee', 130,
          privateTo: currentPatientId, createdDaysAgo: 2),
    ];
    final videoById = {for (final v in videos) v.id: v};

    // ---- Templates ---------------------------------------------------------
    TemplateItem ti(String videoId, int order, int sets, int reps, [int hold = 0]) =>
        TemplateItem(videoId: videoId, order: order, sets: sets, reps: reps, holdSec: hold);

    final meniscus = ProtocolTemplate(
      id: 'tpl-meniscus',
      name: 'Oporavak meniskusa — faza 1',
      bodyPart: 'Knee',
      items: [ti('v-quad', 0, 3, 12), ti('v-heel', 1, 3, 10), ti('v-bridge', 2, 3, 8, 5), ti('v-step', 3, 2, 10)],
      createdAt: daysAgo(45),
    );
    final rotator = ProtocolTemplate(
      id: 'tpl-rotator',
      name: 'Rotatorna manšeta — rana faza',
      bodyPart: 'Shoulder',
      items: [ti('v-pend', 0, 2, 15), ti('v-wall', 1, 3, 10), ti('v-band', 2, 3, 12)],
      createdAt: daysAgo(40),
    );
    final core = ProtocolTemplate(
      id: 'tpl-core',
      name: 'Stabilnost trupa',
      bodyPart: 'Lower back',
      items: [ti('v-cat', 0, 2, 10), ti('v-bird', 1, 3, 8, 3), ti('v-pelvic', 2, 3, 12)],
      createdAt: daysAgo(35),
    );

    // ---- Assignment builder (snapshot semantics, spec §4.4/§4.7) -----------
    Assignment fromTemplate(String id, String patientId, ProtocolTemplate t, DateTime createdAt,
        {bool seen = true}) {
      final items = t.items
          .map((i) => ExerciseItem(
                videoId: i.videoId,
                order: i.order,
                sets: i.sets,
                reps: i.reps,
                holdSec: i.holdSec,
                title: videoById[i.videoId]!.title,
                durationSec: videoById[i.videoId]!.durationSec,
                bodyPart: videoById[i.videoId]!.bodyPart,
              ))
          .toList();
      return Assignment(
        id: id,
        patientId: patientId,
        type: AssignmentType.protocol,
        name: t.name,
        sourceTemplateId: t.id,
        bodyParts: [t.bodyPart],
        daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
        items: items,
        seenByPatient: seen,
        createdAt: createdAt,
      );
    }

    final assignments = <Assignment>[
      // Ivana: adherent knee patient, 3 weeks in.
      fromTemplate('as-ivana-knee', 'pat-ivana', meniscus, daysAgo(21)),
      // Marko: shoulder, skips pendulum swings every day this week (§5.2).
      fromTemplate('as-marko-shoulder', 'pat-marko', rotator, daysAgo(10)),
      // Ana: TWO concurrent protocols (§4.6) + a private single video.
      fromTemplate('as-ana-knee', 'pat-ana', meniscus, daysAgo(14)),
      fromTemplate('as-ana-back', 'pat-ana', core, daysAgo(7)),
      Assignment(
        id: 'as-ana-single',
        patientId: 'pat-ana',
        type: AssignmentType.single,
        name: 'Ana — fokus na koljeno ovaj tjedan',
        bodyParts: const ['Knee'],
        daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
        items: const [
          ExerciseItem(
            videoId: 'v-ana-focus',
            order: 0,
            sets: 1,
            reps: 1,
            title: 'Ana — fokus na koljeno ovaj tjedan',
            durationSec: 130,
            bodyPart: 'Knee',
          ),
        ],
        seenByPatient: false, // New badge on "Also assigned" (§5.4)
        createdAt: daysAgo(2),
      ),
      // Josip: silent for 9 days (§6.1 red row).
      fromTemplate('as-josip-knee', 'pat-josip', meniscus, daysAgo(30)),
      // Petra: assigned TODAY -> New badge, adherence '—'.
      fromTemplate('as-petra-back', 'pat-petra', core, now, seen: false),
    ];

    // ---- Completion history ------------------------------------------------
    final completions = <String, List<Completion>>{};
    void record(String patientId, Assignment a, DateTime day, String videoId, CompletionStatus s) {
      final date = Dates.ymd(day);
      (completions[patientId] ??= []).add(Completion.forDay(
        date: date,
        assignmentId: a.id,
        videoId: videoId,
        status: s,
        at: DateTime(day.year, day.month, day.day, 18, 30),
      ));
    }

    List<DateTime> historyDates(Assignment a, {int stopDaysAgo = 0}) =>
        Dates.scheduledDatesBetween(
          daysOfWeek: a.daysOfWeek,
          from: a.createdAt,
          toExclusive: daysAgo(stopDaysAgo), // exclusive -> excludes today when 0
        );

    // Ivana ~94%: everything done, heel slides skipped every 4th day.
    final ivana = assignments[0];
    final ivanaDates = historyDates(ivana);
    for (var d = 0; d < ivanaDates.length; d++) {
      for (final item in ivana.items) {
        final skip = item.videoId == 'v-heel' && d % 4 == 3;
        record('pat-ivana', ivana, ivanaDates[d], item.videoId,
            skip ? CompletionStatus.skipped : CompletionStatus.done);
      }
    }

    // Marko: all done until a week ago; since then pendulum skipped daily.
    final marko = assignments[1];
    for (final day in historyDates(marko)) {
      final thisWeek = !day.isBefore(daysAgo(7));
      for (final item in marko.items) {
        final skip = thisWeek && item.videoId == 'v-pend';
        record('pat-marko', marko, day, item.videoId,
            skip ? CompletionStatus.skipped : CompletionStatus.done);
      }
    }

    // Ana: knee protocol ~86% (bridge missed some days), back protocol solid,
    // and TODAY: first knee exercise already done -> resume state (§5.3).
    final anaKnee = assignments[2];
    final anaKneeDates = historyDates(anaKnee);
    for (var d = 0; d < anaKneeDates.length; d++) {
      for (final item in anaKnee.items) {
        final miss = item.videoId == 'v-bridge' && d % 3 == 1; // nothing recorded
        if (!miss) record('pat-ana', anaKnee, anaKneeDates[d], item.videoId, CompletionStatus.done);
      }
    }
    final anaBack = assignments[3];
    for (final day in historyDates(anaBack)) {
      for (final item in anaBack.items) {
        record('pat-ana', anaBack, day, item.videoId, CompletionStatus.done);
      }
    }
    record('pat-ana', anaKnee, today, 'v-quad', CompletionStatus.done);

    // Josip: did the work for three weeks, then nothing for 9 days.
    final josip = assignments[5];
    // toExclusive is exclusive: stop at 8 -> last recorded day is 9 days ago.
    for (final day in historyDates(josip, stopDaysAgo: 8)) {
      for (final item in josip.items) {
        record('pat-josip', josip, day, item.videoId, CompletionStatus.done);
      }
    }

    DateTime? lastActive(String patientId) {
      final list = completions[patientId];
      if (list == null || list.isEmpty) return null;
      return list.map((c) => c.at).reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // ---- Patients ----------------------------------------------------------
    final patients = <Patient>[
      Patient(
        id: 'pat-ivana',
        name: 'Ivana Horvat',
        email: 'ivana.horvat@example.com',
        uid: 'uid-ivana',
        primaryBodyPart: 'Knee',
        notes: 'Parcijalna medijalna meniscektomija prije 6 tjedana. Odobren rad u zatvorenom kinetičkom lancu.',
        lastActiveAt: lastActive('pat-ivana'),
        createdAt: daysAgo(22),
      ),
      Patient(
        id: 'pat-marko',
        name: 'Marko Babić',
        email: 'marko.babic@example.com',
        uid: 'uid-marko',
        primaryBodyPart: 'Shoulder',
        notes: 'Tendinopatija supraspinatusa. Navodi bol kod pendularnih kretnji — provjeriti doziranje.',
        lastActiveAt: lastActive('pat-marko'),
        createdAt: daysAgo(11),
      ),
      Patient(
        id: 'pat-ana',
        name: 'Ana Kovačević',
        email: 'ana.kovacevic@example.com',
        uid: 'uid-ana',
        primaryBodyPart: 'Knee',
        notes: 'Rehabilitacija nakon rekonstrukcije ACL-a, 3. mjesec. Istegnuće donjih leđa od kompenzacije.',
        lastActiveAt: lastActive('pat-ana'),
        createdAt: daysAgo(15),
      ),
      Patient(
        id: 'pat-josip',
        name: 'Josip Novak',
        email: 'josip.novak@example.com',
        uid: 'uid-josip',
        primaryBodyPart: 'Knee',
        notes: 'Nakon totalne endoproteze koljena. Bio dosljedan, prestao se javljati — nazvati prije termina u četvrtak.',
        lastActiveAt: lastActive('pat-josip'),
        createdAt: daysAgo(31),
      ),
      Patient(
        id: 'pat-petra',
        name: 'Petra Marić',
        email: 'petra.maric@example.com',
        uid: 'uid-petra',
        primaryBodyPart: 'Lower back',
        notes: 'Kronična ukočenost lumbalne kralježnice, uredski posao. Počela danas.',
        lastActiveAt: null,
        createdAt: today,
      ),
      Patient(
        id: 'pat-luka',
        name: 'Luka Jurić',
        email: 'luka.juric@example.com',
        uid: null, // hasn't redeemed the invite yet -> 'invited' chip (§6.1)
        primaryBodyPart: 'Shoulder',
        notes: '',
        inviteCode: 'LK7-3FQ9',
        inviteExpiresAt: daysAgo(-12),
        createdAt: daysAgo(2),
      ),
    ];

    // Usage counts reflect seeded assignments.
    final usage = <String, int>{};
    for (final a in assignments) {
      for (final item in a.items) {
        usage[item.videoId] = (usage[item.videoId] ?? 0) + 1;
      }
    }
    final countedVideos =
        videos.map((v) => v.copyWith(usageCount: usage[v.id] ?? 0)).toList();

    return DemoData._(
      patients: patients,
      videos: countedVideos,
      templates: [meniscus, rotator, core],
      assignments: assignments,
      completionsByPatient: completions,
    );
  }
}
