import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Poliklinika Tendo';

  @override
  String get roleGateSubtitle => 'Showcase build — pick a side to explore';

  @override
  String get enterAsPhysio => 'Enter as physio';

  @override
  String get enterAsPatient => 'Enter as patient';

  @override
  String get roleGateFooter => 'Demo data · resets on restart';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get switchRole => 'Switch role';

  @override
  String get languageToggleLabel => 'Change language';

  @override
  String get languageCroatian => 'Hrvatski';

  @override
  String get languageEnglish => 'English';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get add => 'Add';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get navPatients => 'Patients';

  @override
  String get navLibrary => 'Library';

  @override
  String get navTemplates => 'Templates';

  @override
  String get patientsTitle => 'Patients';

  @override
  String get noPatientsYet => 'No patients yet';

  @override
  String get addPatientDetail => 'Add a patient to send them an invite code.';

  @override
  String get addPatient => 'Add patient';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String inviteCodeFor(String name, String code) {
    return 'Invite code for $name: $code';
  }

  @override
  String daysSilent(int days) {
    return '$days days silent';
  }

  @override
  String get invitedNotRedeemed => 'invited — code not redeemed';

  @override
  String get notStarted => 'not started';

  @override
  String get noActivityYet => 'no activity yet';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get activeProtocols => 'Active protocols';

  @override
  String get noActiveProtocols => 'No active protocols yet.';

  @override
  String get alsoAssigned => 'Also assigned';

  @override
  String get privateNotes => 'Private notes';

  @override
  String get notesHint => 'Clinical context only you can see…';

  @override
  String get assignSomething => 'Assign something';

  @override
  String get inviteCode => 'Invite code';

  @override
  String expiresOn(String date) {
    return 'expires $date';
  }

  @override
  String get regenerateCode => 'Regenerate code';

  @override
  String newInviteCode(String code) {
    return 'New invite code: $code';
  }

  @override
  String protocolSummary(int count, int done, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0 · $done done · $skipped skipped';
  }

  @override
  String exerciseNofM(int n, int m) {
    return 'EXERCISE $n OF $m';
  }

  @override
  String get doneNextExercise => 'Done · next exercise';

  @override
  String get skipThisOne => 'Skip this one';

  @override
  String get sessionComplete => 'Session complete';

  @override
  String doneSkippedSummary(int done, int skipped) {
    return '$done done · $skipped skipped';
  }

  @override
  String get backToHome => 'Back to home';

  @override
  String get nothingDueToday => 'Nothing due today';

  @override
  String get setsPill => 'sets';

  @override
  String get repsPill => 'reps';

  @override
  String get holdPill => 'hold';

  @override
  String get setsTitle => 'Sets';

  @override
  String get repsTitle => 'Reps';

  @override
  String get holdTitle => 'Hold';

  @override
  String get noHold => 'No hold';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get nothingAssignedYet => 'Nothing assigned yet';

  @override
  String get physioWillSetYouUp => 'Your physio will set you up.';

  @override
  String get todaysSessionLabel => 'TODAY’S SESSION';

  @override
  String exercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0';
  }

  @override
  String remainingCount(int count) {
    return '$count remaining';
  }

  @override
  String get doneForToday => 'Done for today';

  @override
  String get startTodaysSession => 'Start today’s session';

  @override
  String get resumeSession => 'Resume session';

  @override
  String todaysSessionSemantic(String headline) {
    return 'Today’s session: $headline';
  }

  @override
  String get newAssignment => 'New assignment';

  @override
  String get everythingDoneToday => 'That’s everything for today — see you tomorrow.';

  @override
  String setsTimesReps(int sets, int reps) {
    String _temp0 = intl.Intl.pluralLogic(
      reps,
      locale: localeName,
      other: '$reps reps',
      one: '$reps rep',
    );
    return '$sets× $_temp0';
  }

  @override
  String get libraryTitle => 'Library';

  @override
  String get filmUploadVideo => 'Film / upload video';

  @override
  String get noVideosYet => 'No videos yet';

  @override
  String get filmFirstVideo => 'Film or upload your first exercise video.';

  @override
  String durationUsedBy(String duration, int count) {
    return '$duration · used by $count';
  }

  @override
  String get titleLabel => 'Title';

  @override
  String get bodyPartLabel => 'Body part';

  @override
  String get durationLabel => 'Duration';

  @override
  String get privateToPatient => 'Private to patient (optional)';

  @override
  String get noneSharedLibrary => 'None — shared library';

  @override
  String get compressAndUpload => 'Compress & upload';

  @override
  String get compressing => 'Compressing…';

  @override
  String get uploading => 'Uploading…';

  @override
  String get addedToLibrary => 'Added to library';

  @override
  String get privateChip => 'private';

  @override
  String get invitedChip => 'invited';

  @override
  String get newChip => 'New';

  @override
  String get bodyPartKnee => 'Knee';

  @override
  String get bodyPartShoulder => 'Shoulder';

  @override
  String get bodyPartLowerBack => 'Lower back';

  @override
  String get bodyPartNeck => 'Neck';

  @override
  String get assignTitle => 'Assign';

  @override
  String get sendAVideo => 'Send a video';

  @override
  String get chooseVideos => 'Choose videos';

  @override
  String get adjustDosage => 'Adjust dosage';

  @override
  String adjustFor(String name) {
    return 'Adjust for $name';
  }

  @override
  String get assignedToast => 'Assigned ✓';

  @override
  String get fromATemplate => 'From a template';

  @override
  String templatesSavedPick(int count) {
    return '$count saved · pick one below';
  }

  @override
  String get buildCustomProtocol => 'Build a custom protocol';

  @override
  String get pickVideosSetOrder => 'Pick videos from the library, set order and dosage';

  @override
  String get sendSingleVideo => 'Send a single video';

  @override
  String get oneClipNoCeremony => 'One clip, no protocol, no dosage ceremony';

  @override
  String get recentTemplates => 'Recent templates';

  @override
  String get noTemplatesYetBuild => 'No templates yet — build a custom protocol and save it as one.';

  @override
  String templateSubtitle(String bodyPart, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$bodyPart · $_temp0';
  }

  @override
  String get pickVideos => 'Pick videos';

  @override
  String get filmNew => 'Film new';

  @override
  String get filmOneToStart => 'Film one to get started.';

  @override
  String sendTo(String name) {
    return 'Send to $name';
  }

  @override
  String addNExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return 'Add $_temp0';
  }

  @override
  String get protocolNameLabel => 'Protocol name';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get noExercises => 'No exercises';

  @override
  String get addAtLeastOne => 'Add at least one to assign.';

  @override
  String get saveAsTemplate => 'Save as template';

  @override
  String assignToName(String name) {
    return 'Assign to $name';
  }

  @override
  String get templatesTitle => 'Templates';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get saveOneFromAssign => 'Save one from the assign flow after building a protocol.';

  @override
  String get templatesSavedFromAssign => 'New templates are saved from the assign flow';

  @override
  String templateSubtitleWithMin(String bodyPart, int count, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$bodyPart · $_temp0 · ~$min min';
  }

  @override
  String get pickVideoCta => 'Choose or film a video';

  @override
  String get pickFromGallery => 'From gallery';

  @override
  String get filmWithCamera => 'Film now';

  @override
  String get videoTooLong => 'Demo limit is 15 seconds — pick a shorter clip.';

  @override
  String videoReady(String duration) {
    return 'Video attached · $duration';
  }

  @override
  String get replaceVideo => 'Replace video';

  @override
  String get playVideo => 'Play';

  @override
  String get pauseVideo => 'Pause';

  @override
  String get removePatient => 'Remove patient';

  @override
  String removePatientConfirm(String name) {
    return 'Remove $name and all their data?';
  }

  @override
  String get removeAction => 'Remove';

  @override
  String get legendDone => 'done';

  @override
  String get legendSkipped => 'skipped';

  @override
  String get legendMissed => 'missed';

  @override
  String get fullscreenTooltip => 'Fullscreen';

  @override
  String get exitFullscreenTooltip => 'Exit fullscreen';
}
