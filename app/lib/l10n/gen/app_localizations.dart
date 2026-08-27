import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Poliklinika Tendo'**
  String get appTitle;

  /// No description provided for @roleGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showcase build — pick a side to explore'**
  String get roleGateSubtitle;

  /// No description provided for @enterAsPhysio.
  ///
  /// In en, this message translates to:
  /// **'Enter as physio'**
  String get enterAsPhysio;

  /// No description provided for @enterAsPatient.
  ///
  /// In en, this message translates to:
  /// **'Enter as patient'**
  String get enterAsPatient;

  /// No description provided for @roleGateFooter.
  ///
  /// In en, this message translates to:
  /// **'Demo data · resets on restart'**
  String get roleGateFooter;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @switchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch role'**
  String get switchRole;

  /// No description provided for @languageToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageToggleLabel;

  /// No description provided for @languageCroatian.
  ///
  /// In en, this message translates to:
  /// **'Hrvatski'**
  String get languageCroatian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @navPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get navPatients;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get navTemplates;

  /// No description provided for @patientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsTitle;

  /// No description provided for @noPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No patients yet'**
  String get noPatientsYet;

  /// No description provided for @addPatientDetail.
  ///
  /// In en, this message translates to:
  /// **'Add a patient to send them an invite code.'**
  String get addPatientDetail;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add patient'**
  String get addPatient;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @inviteCodeFor.
  ///
  /// In en, this message translates to:
  /// **'Invite code for {name}: {code}'**
  String inviteCodeFor(String name, String code);

  /// No description provided for @daysSilent.
  ///
  /// In en, this message translates to:
  /// **'{days} days silent'**
  String daysSilent(int days);

  /// No description provided for @invitedNotRedeemed.
  ///
  /// In en, this message translates to:
  /// **'invited — code not redeemed'**
  String get invitedNotRedeemed;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'not started'**
  String get notStarted;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'no activity yet'**
  String get noActivityYet;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @activeProtocols.
  ///
  /// In en, this message translates to:
  /// **'Active protocols'**
  String get activeProtocols;

  /// No description provided for @noActiveProtocols.
  ///
  /// In en, this message translates to:
  /// **'No active protocols yet.'**
  String get noActiveProtocols;

  /// No description provided for @alsoAssigned.
  ///
  /// In en, this message translates to:
  /// **'Also assigned'**
  String get alsoAssigned;

  /// No description provided for @privateNotes.
  ///
  /// In en, this message translates to:
  /// **'Private notes'**
  String get privateNotes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Clinical context only you can see…'**
  String get notesHint;

  /// No description provided for @assignSomething.
  ///
  /// In en, this message translates to:
  /// **'Assign something'**
  String get assignSomething;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'expires {date}'**
  String expiresOn(String date);

  /// No description provided for @regenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Regenerate code'**
  String get regenerateCode;

  /// No description provided for @newInviteCode.
  ///
  /// In en, this message translates to:
  /// **'New invite code: {code}'**
  String newInviteCode(String code);

  /// No description provided for @protocolSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} exercise} other{{count} exercises}} · {done} done · {skipped} skipped'**
  String protocolSummary(int count, int done, int skipped);

  /// No description provided for @exerciseNofM.
  ///
  /// In en, this message translates to:
  /// **'EXERCISE {n} OF {m}'**
  String exerciseNofM(int n, int m);

  /// No description provided for @doneNextExercise.
  ///
  /// In en, this message translates to:
  /// **'Done · next exercise'**
  String get doneNextExercise;

  /// No description provided for @skipThisOne.
  ///
  /// In en, this message translates to:
  /// **'Skip this one'**
  String get skipThisOne;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete'**
  String get sessionComplete;

  /// No description provided for @doneSkippedSummary.
  ///
  /// In en, this message translates to:
  /// **'{done} done · {skipped} skipped'**
  String doneSkippedSummary(int done, int skipped);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @nothingDueToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get nothingDueToday;

  /// No description provided for @setsPill.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get setsPill;

  /// No description provided for @repsPill.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsPill;

  /// No description provided for @holdPill.
  ///
  /// In en, this message translates to:
  /// **'hold'**
  String get holdPill;

  /// No description provided for @setsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsTitle;

  /// No description provided for @repsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsTitle;

  /// No description provided for @holdTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get holdTitle;

  /// No description provided for @noHold.
  ///
  /// In en, this message translates to:
  /// **'No hold'**
  String get noHold;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @nothingAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing assigned yet'**
  String get nothingAssignedYet;

  /// No description provided for @physioWillSetYouUp.
  ///
  /// In en, this message translates to:
  /// **'Your physio will set you up.'**
  String get physioWillSetYouUp;

  /// No description provided for @todaysSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'TODAY’S SESSION'**
  String get todaysSessionLabel;

  /// No description provided for @exercisesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} exercise} other{{count} exercises}}'**
  String exercisesCount(int count);

  /// No description provided for @remainingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String remainingCount(int count);

  /// No description provided for @doneForToday.
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get doneForToday;

  /// No description provided for @startTodaysSession.
  ///
  /// In en, this message translates to:
  /// **'Start today’s session'**
  String get startTodaysSession;

  /// No description provided for @resumeSession.
  ///
  /// In en, this message translates to:
  /// **'Resume session'**
  String get resumeSession;

  /// No description provided for @todaysSessionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Today’s session: {headline}'**
  String todaysSessionSemantic(String headline);

  /// No description provided for @newAssignment.
  ///
  /// In en, this message translates to:
  /// **'New assignment'**
  String get newAssignment;

  /// No description provided for @everythingDoneToday.
  ///
  /// In en, this message translates to:
  /// **'That’s everything for today — see you tomorrow.'**
  String get everythingDoneToday;

  /// No description provided for @setsTimesReps.
  ///
  /// In en, this message translates to:
  /// **'{sets}× {reps, plural, one{{reps} rep} other{{reps} reps}}'**
  String setsTimesReps(int sets, int reps);

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @filmUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Film / upload video'**
  String get filmUploadVideo;

  /// No description provided for @noVideosYet.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideosYet;

  /// No description provided for @filmFirstVideo.
  ///
  /// In en, this message translates to:
  /// **'Film or upload your first exercise video.'**
  String get filmFirstVideo;

  /// No description provided for @durationUsedBy.
  ///
  /// In en, this message translates to:
  /// **'{duration} · used by {count}'**
  String durationUsedBy(String duration, int count);

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @bodyPartLabel.
  ///
  /// In en, this message translates to:
  /// **'Body part'**
  String get bodyPartLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @privateToPatient.
  ///
  /// In en, this message translates to:
  /// **'Private to patient (optional)'**
  String get privateToPatient;

  /// No description provided for @noneSharedLibrary.
  ///
  /// In en, this message translates to:
  /// **'None — shared library'**
  String get noneSharedLibrary;

  /// No description provided for @compressAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Compress & upload'**
  String get compressAndUpload;

  /// No description provided for @compressing.
  ///
  /// In en, this message translates to:
  /// **'Compressing…'**
  String get compressing;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @addedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added to library'**
  String get addedToLibrary;

  /// No description provided for @privateChip.
  ///
  /// In en, this message translates to:
  /// **'private'**
  String get privateChip;

  /// No description provided for @invitedChip.
  ///
  /// In en, this message translates to:
  /// **'invited'**
  String get invitedChip;

  /// No description provided for @newChip.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newChip;

  /// No description provided for @bodyPartKnee.
  ///
  /// In en, this message translates to:
  /// **'Knee'**
  String get bodyPartKnee;

  /// No description provided for @bodyPartShoulder.
  ///
  /// In en, this message translates to:
  /// **'Shoulder'**
  String get bodyPartShoulder;

  /// No description provided for @bodyPartLowerBack.
  ///
  /// In en, this message translates to:
  /// **'Lower back'**
  String get bodyPartLowerBack;

  /// No description provided for @bodyPartNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get bodyPartNeck;

  /// No description provided for @assignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignTitle;

  /// No description provided for @sendAVideo.
  ///
  /// In en, this message translates to:
  /// **'Send a video'**
  String get sendAVideo;

  /// No description provided for @chooseVideos.
  ///
  /// In en, this message translates to:
  /// **'Choose videos'**
  String get chooseVideos;

  /// No description provided for @adjustDosage.
  ///
  /// In en, this message translates to:
  /// **'Adjust dosage'**
  String get adjustDosage;

  /// No description provided for @adjustFor.
  ///
  /// In en, this message translates to:
  /// **'Adjust for {name}'**
  String adjustFor(String name);

  /// No description provided for @assignedToast.
  ///
  /// In en, this message translates to:
  /// **'Assigned ✓'**
  String get assignedToast;

  /// No description provided for @fromATemplate.
  ///
  /// In en, this message translates to:
  /// **'From a template'**
  String get fromATemplate;

  /// No description provided for @templatesSavedPick.
  ///
  /// In en, this message translates to:
  /// **'{count} saved · pick one below'**
  String templatesSavedPick(int count);

  /// No description provided for @buildCustomProtocol.
  ///
  /// In en, this message translates to:
  /// **'Build a custom protocol'**
  String get buildCustomProtocol;

  /// No description provided for @pickVideosSetOrder.
  ///
  /// In en, this message translates to:
  /// **'Pick videos from the library, set order and dosage'**
  String get pickVideosSetOrder;

  /// No description provided for @sendSingleVideo.
  ///
  /// In en, this message translates to:
  /// **'Send a single video'**
  String get sendSingleVideo;

  /// No description provided for @oneClipNoCeremony.
  ///
  /// In en, this message translates to:
  /// **'One clip, no protocol, no dosage ceremony'**
  String get oneClipNoCeremony;

  /// No description provided for @recentTemplates.
  ///
  /// In en, this message translates to:
  /// **'Recent templates'**
  String get recentTemplates;

  /// No description provided for @noTemplatesYetBuild.
  ///
  /// In en, this message translates to:
  /// **'No templates yet — build a custom protocol and save it as one.'**
  String get noTemplatesYetBuild;

  /// No description provided for @templateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{bodyPart} · {count, plural, one{{count} exercise} other{{count} exercises}}'**
  String templateSubtitle(String bodyPart, int count);

  /// No description provided for @pickVideos.
  ///
  /// In en, this message translates to:
  /// **'Pick videos'**
  String get pickVideos;

  /// No description provided for @filmNew.
  ///
  /// In en, this message translates to:
  /// **'Film new'**
  String get filmNew;

  /// No description provided for @filmOneToStart.
  ///
  /// In en, this message translates to:
  /// **'Film one to get started.'**
  String get filmOneToStart;

  /// No description provided for @sendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to {name}'**
  String sendTo(String name);

  /// No description provided for @addNExercises.
  ///
  /// In en, this message translates to:
  /// **'Add {count, plural, one{{count} exercise} other{{count} exercises}}'**
  String addNExercises(int count);

  /// No description provided for @protocolNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Protocol name'**
  String get protocolNameLabel;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @noExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercises;

  /// No description provided for @addAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one to assign.'**
  String get addAtLeastOne;

  /// No description provided for @saveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get saveAsTemplate;

  /// No description provided for @assignToName.
  ///
  /// In en, this message translates to:
  /// **'Assign to {name}'**
  String assignToName(String name);

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templatesTitle;

  /// No description provided for @noTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// No description provided for @saveOneFromAssign.
  ///
  /// In en, this message translates to:
  /// **'Save one from the assign flow after building a protocol.'**
  String get saveOneFromAssign;

  /// No description provided for @templatesSavedFromAssign.
  ///
  /// In en, this message translates to:
  /// **'New templates are saved from the assign flow'**
  String get templatesSavedFromAssign;

  /// No description provided for @templateSubtitleWithMin.
  ///
  /// In en, this message translates to:
  /// **'{bodyPart} · {count, plural, one{{count} exercise} other{{count} exercises}} · ~{min} min'**
  String templateSubtitleWithMin(String bodyPart, int count, int min);

  /// No description provided for @pickVideoCta.
  ///
  /// In en, this message translates to:
  /// **'Choose or film a video'**
  String get pickVideoCta;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get pickFromGallery;

  /// No description provided for @filmWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Film now'**
  String get filmWithCamera;

  /// No description provided for @videoTooLong.
  ///
  /// In en, this message translates to:
  /// **'Demo limit is 15 seconds — pick a shorter clip.'**
  String get videoTooLong;

  /// No description provided for @videoReady.
  ///
  /// In en, this message translates to:
  /// **'Video attached · {duration}'**
  String videoReady(String duration);

  /// No description provided for @replaceVideo.
  ///
  /// In en, this message translates to:
  /// **'Replace video'**
  String get replaceVideo;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playVideo;

  /// No description provided for @pauseVideo.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseVideo;

  /// No description provided for @removePatient.
  ///
  /// In en, this message translates to:
  /// **'Remove patient'**
  String get removePatient;

  /// No description provided for @removePatientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} and all their data?'**
  String removePatientConfirm(String name);

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @legendDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get legendDone;

  /// No description provided for @legendSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get legendSkipped;

  /// No description provided for @legendMissed.
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get legendMissed;

  /// No description provided for @fullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreenTooltip;

  /// No description provided for @exitFullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get exitFullscreenTooltip;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your exercise program, at home'**
  String get signInSubtitle;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, a reset link is on its way.'**
  String get resetEmailSent;

  /// No description provided for @resetEmailEnterFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above first.'**
  String get resetEmailEnterFirst;

  /// No description provided for @haveInviteCode.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code'**
  String get haveInviteCode;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate your program'**
  String get inviteTitle;

  /// No description provided for @inviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code your physiotherapist gave you and choose a password.'**
  String get inviteSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get createAccountButton;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get passwordsDontMatch;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @signOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutLabel;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountLabel;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your access. Enter your password to confirm.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirm;

  /// No description provided for @resolvingIdentity.
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get resolvingIdentity;

  /// No description provided for @notLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get notLinkedTitle;

  /// No description provided for @notLinkedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t linked to a program yet. Enter your invite code to finish.'**
  String get notLinkedBody;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryButton;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailInUseWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account, but the password doesn\'t match it.'**
  String get errEmailInUseWrongPassword;

  /// No description provided for @errInvalidInvite.
  ///
  /// In en, this message translates to:
  /// **'That invite code isn\'t valid. Check it with your physiotherapist.'**
  String get errInvalidInvite;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak — use at least 6 characters.'**
  String get errWeakPassword;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email address.'**
  String get errInvalidEmail;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errNetwork;

  /// No description provided for @errRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then retry.'**
  String get errRequiresRecentLogin;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errUnknown;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hr': return AppLocalizationsHr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
