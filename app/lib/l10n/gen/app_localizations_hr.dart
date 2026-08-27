import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'Poliklinika Tendo';

  @override
  String get roleGateSubtitle => 'Demonstracijska verzija — odaberite stranu';

  @override
  String get enterAsPhysio => 'Uđi kao fizioterapeut';

  @override
  String get enterAsPatient => 'Uđi kao pacijent';

  @override
  String get roleGateFooter => 'Demo podaci · vraćaju se pri ponovnom pokretanju';

  @override
  String get profileTooltip => 'Profil';

  @override
  String get switchRole => 'Promijeni ulogu';

  @override
  String get languageToggleLabel => 'Promijeni jezik';

  @override
  String get languageCroatian => 'Hrvatski';

  @override
  String get languageEnglish => 'English';

  @override
  String get cancel => 'Odustani';

  @override
  String get save => 'Spremi';

  @override
  String get close => 'Zatvori';

  @override
  String get retry => 'Pokušaj ponovno';

  @override
  String get add => 'Dodaj';

  @override
  String get somethingWentWrong => 'Nešto je pošlo po zlu';

  @override
  String get navPatients => 'Pacijenti';

  @override
  String get navLibrary => 'Videoteka';

  @override
  String get navTemplates => 'Predlošci';

  @override
  String get patientsTitle => 'Pacijenti';

  @override
  String get noPatientsYet => 'Još nema pacijenata';

  @override
  String get addPatientDetail => 'Dodajte pacijenta kako biste mu poslali pozivni kod.';

  @override
  String get addPatient => 'Dodaj pacijenta';

  @override
  String get nameLabel => 'Ime i prezime';

  @override
  String get emailLabel => 'E-mail';

  @override
  String inviteCodeFor(String name, String code) {
    return 'Pozivni kod za $name: $code';
  }

  @override
  String daysSilent(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dana bez aktivnosti',
      few: '$days dana bez aktivnosti',
      one: '$days dan bez aktivnosti',
    );
    return '$_temp0';
  }

  @override
  String get invitedNotRedeemed => 'pozvan — kod nije iskorišten';

  @override
  String get notStarted => 'nije započeto';

  @override
  String get noActivityYet => 'još nema aktivnosti';

  @override
  String get today => 'danas';

  @override
  String get yesterday => 'jučer';

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'prije $days dana',
      few: 'prije $days dana',
      one: 'prije $days dan',
    );
    return '$_temp0';
  }

  @override
  String get activeProtocols => 'Aktivni protokoli';

  @override
  String get noActiveProtocols => 'Još nema aktivnih protokola.';

  @override
  String get alsoAssigned => 'Dodatno zadano';

  @override
  String get privateNotes => 'Privatne bilješke';

  @override
  String get notesHint => 'Klinički kontekst vidljiv samo vama…';

  @override
  String get assignSomething => 'Zadaj vježbe';

  @override
  String get inviteCode => 'Pozivni kod';

  @override
  String expiresOn(String date) {
    return 'vrijedi do $date';
  }

  @override
  String get regenerateCode => 'Generiraj novi kod';

  @override
  String newInviteCode(String code) {
    return 'Novi pozivni kod: $code';
  }

  @override
  String protocolSummary(int count, int done, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vježbi',
      few: '$count vježbe',
      one: '$count vježba',
    );
    return '$_temp0 · odrađeno: $done · preskočeno: $skipped';
  }

  @override
  String exerciseNofM(int n, int m) {
    return 'VJEŽBA $n OD $m';
  }

  @override
  String get doneNextExercise => 'Gotovo · sljedeća vježba';

  @override
  String get skipThisOne => 'Preskoči ovu';

  @override
  String get sessionComplete => 'Trening odrađen';

  @override
  String doneSkippedSummary(int done, int skipped) {
    return 'odrađeno: $done · preskočeno: $skipped';
  }

  @override
  String get backToHome => 'Natrag na početnu';

  @override
  String get nothingDueToday => 'Danas nema zadanih vježbi';

  @override
  String get setsPill => 'serije';

  @override
  String get repsPill => 'ponavljanja';

  @override
  String get holdPill => 'izdržaj';

  @override
  String get setsTitle => 'Serije';

  @override
  String get repsTitle => 'Ponavljanja';

  @override
  String get holdTitle => 'Izdržaj';

  @override
  String get noHold => 'Bez izdržaja';

  @override
  String get goodMorning => 'Dobro jutro';

  @override
  String get goodAfternoon => 'Dobar dan';

  @override
  String get goodEvening => 'Dobra večer';

  @override
  String get nothingAssignedYet => 'Još nema zadanih vježbi';

  @override
  String get physioWillSetYouUp => 'Vaš fizioterapeut će vam ih uskoro zadati.';

  @override
  String get todaysSessionLabel => 'DANAŠNJI TRENING';

  @override
  String exercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vježbi',
      few: '$count vježbe',
      one: '$count vježba',
    );
    return '$_temp0';
  }

  @override
  String remainingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'još $count vježbi',
      few: 'još $count vježbe',
      one: 'još $count vježba',
    );
    return '$_temp0';
  }

  @override
  String get doneForToday => 'Gotovo za danas';

  @override
  String get startTodaysSession => 'Započni današnji trening';

  @override
  String get resumeSession => 'Nastavi trening';

  @override
  String todaysSessionSemantic(String headline) {
    return 'Današnji trening: $headline';
  }

  @override
  String get newAssignment => 'Novi program vježbi';

  @override
  String get everythingDoneToday => 'To je sve za danas — vidimo se sutra.';

  @override
  String setsTimesReps(int sets, int reps) {
    String _temp0 = intl.Intl.pluralLogic(
      reps,
      locale: localeName,
      other: '$reps ponavljanja',
      few: '$reps ponavljanja',
      one: '$reps ponavljanje',
    );
    return '$sets× $_temp0';
  }

  @override
  String get libraryTitle => 'Videoteka';

  @override
  String get filmUploadVideo => 'Snimi ili učitaj video';

  @override
  String get noVideosYet => 'Još nema videa';

  @override
  String get filmFirstVideo => 'Snimite ili učitajte prvi video vježbe.';

  @override
  String durationUsedBy(String duration, int count) {
    return '$duration · korišteno: $count';
  }

  @override
  String get titleLabel => 'Naziv';

  @override
  String get bodyPartLabel => 'Dio tijela';

  @override
  String get durationLabel => 'Trajanje';

  @override
  String get privateToPatient => 'Privatno za pacijenta (neobavezno)';

  @override
  String get noneSharedLibrary => 'Nijedan — zajednička videoteka';

  @override
  String get compressAndUpload => 'Komprimiraj i učitaj';

  @override
  String get compressing => 'Komprimiranje…';

  @override
  String get uploading => 'Učitavanje…';

  @override
  String get addedToLibrary => 'Dodano u videoteku';

  @override
  String get privateChip => 'privatno';

  @override
  String get invitedChip => 'pozvan';

  @override
  String get newChip => 'Novo';

  @override
  String get bodyPartKnee => 'Koljeno';

  @override
  String get bodyPartShoulder => 'Rame';

  @override
  String get bodyPartLowerBack => 'Donji dio leđa';

  @override
  String get bodyPartNeck => 'Vrat';

  @override
  String get assignTitle => 'Zadavanje';

  @override
  String get sendAVideo => 'Pošalji video';

  @override
  String get chooseVideos => 'Odaberi videe';

  @override
  String get adjustDosage => 'Prilagodi doziranje';

  @override
  String adjustFor(String name) {
    return 'Prilagodi za: $name';
  }

  @override
  String get assignedToast => 'Zadano ✓';

  @override
  String get fromATemplate => 'Iz predloška';

  @override
  String templatesSavedPick(int count) {
    return 'spremljenih: $count · odaberite ispod';
  }

  @override
  String get buildCustomProtocol => 'Složi vlastiti protokol';

  @override
  String get pickVideosSetOrder => 'Odaberite videe iz videoteke, poredak i doziranje';

  @override
  String get sendSingleVideo => 'Pošalji jedan video';

  @override
  String get oneClipNoCeremony => 'Jedan video, bez protokola i doziranja';

  @override
  String get recentTemplates => 'Nedavni predlošci';

  @override
  String get noTemplatesYetBuild => 'Još nema predložaka — složite protokol i spremite ga kao predložak.';

  @override
  String templateSubtitle(String bodyPart, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vježbi',
      few: '$count vježbe',
      one: '$count vježba',
    );
    return '$bodyPart · $_temp0';
  }

  @override
  String get pickVideos => 'Odaberi videe';

  @override
  String get filmNew => 'Snimi novi';

  @override
  String get filmOneToStart => 'Snimite prvi video za početak.';

  @override
  String sendTo(String name) {
    return 'Pošalji: $name';
  }

  @override
  String addNExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodaj $count vježbi',
      few: 'Dodaj $count vježbe',
      one: 'Dodaj $count vježbu',
    );
    return '$_temp0';
  }

  @override
  String get protocolNameLabel => 'Naziv protokola';

  @override
  String get dayMon => 'Pon';

  @override
  String get dayTue => 'Uto';

  @override
  String get dayWed => 'Sri';

  @override
  String get dayThu => 'Čet';

  @override
  String get dayFri => 'Pet';

  @override
  String get daySat => 'Sub';

  @override
  String get daySun => 'Ned';

  @override
  String get noExercises => 'Nema vježbi';

  @override
  String get addAtLeastOne => 'Dodajte barem jednu vježbu.';

  @override
  String get saveAsTemplate => 'Spremi kao predložak';

  @override
  String assignToName(String name) {
    return 'Zadaj: $name';
  }

  @override
  String get templatesTitle => 'Predlošci';

  @override
  String get noTemplatesYet => 'Još nema predložaka';

  @override
  String get saveOneFromAssign => 'Spremite predložak nakon što složite protokol u zadavanju.';

  @override
  String get templatesSavedFromAssign => 'Novi predlošci spremaju se iz zadavanja vježbi';

  @override
  String templateSubtitleWithMin(String bodyPart, int count, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vježbi',
      few: '$count vježbe',
      one: '$count vježba',
    );
    return '$bodyPart · $_temp0 · ~$min min';
  }

  @override
  String get pickVideoCta => 'Odaberi ili snimi video';

  @override
  String get pickFromGallery => 'Iz galerije';

  @override
  String get filmWithCamera => 'Snimi sada';

  @override
  String get videoTooLong => 'Demo ograničenje je 15 sekundi — odaberite kraći isječak.';

  @override
  String videoReady(String duration) {
    return 'Video dodan · $duration';
  }

  @override
  String get replaceVideo => 'Zamijeni video';

  @override
  String get playVideo => 'Reproduciraj';

  @override
  String get pauseVideo => 'Pauziraj';

  @override
  String get removePatient => 'Ukloni pacijenta';

  @override
  String removePatientConfirm(String name) {
    return 'Ukloniti pacijenta $name i sve njegove podatke?';
  }

  @override
  String get removeAction => 'Ukloni';

  @override
  String get legendDone => 'odrađeno';

  @override
  String get legendSkipped => 'preskočeno';

  @override
  String get legendMissed => 'propušteno';

  @override
  String get fullscreenTooltip => 'Cijeli zaslon';

  @override
  String get exitFullscreenTooltip => 'Zatvori cijeli zaslon';

  @override
  String get signInTitle => 'Prijava';

  @override
  String get signInSubtitle => 'Vaš program vježbi, kod kuće';

  @override
  String get passwordLabel => 'Lozinka';

  @override
  String get signInButton => 'Prijavi se';

  @override
  String get forgotPassword => 'Zaboravljena lozinka?';

  @override
  String get resetEmailSent => 'Ako račun s tom e-adresom postoji, poveznica za promjenu lozinke je poslana.';

  @override
  String get resetEmailEnterFirst => 'Najprije upišite e-adresu iznad.';

  @override
  String get haveInviteCode => 'Imam pozivni kod';

  @override
  String get inviteTitle => 'Aktivirajte svoj program';

  @override
  String get inviteSubtitle => 'Upišite kod koji vam je dao fizioterapeut i odaberite lozinku.';

  @override
  String get inviteCodeLabel => 'Pozivni kod';

  @override
  String get confirmPasswordLabel => 'Potvrdite lozinku';

  @override
  String get createAccountButton => 'Aktiviraj';

  @override
  String get backToSignIn => 'Natrag na prijavu';

  @override
  String get passwordsDontMatch => 'Lozinke se ne podudaraju.';

  @override
  String get fieldRequired => 'Obavezno';

  @override
  String get signOutLabel => 'Odjava';

  @override
  String get deleteAccountLabel => 'Izbriši račun';

  @override
  String get deleteAccountTitle => 'Izbrisati račun?';

  @override
  String get deleteAccountBody => 'Ovime trajno gubite pristup. Za potvrdu upišite lozinku.';

  @override
  String get deleteAccountConfirm => 'Izbriši';

  @override
  String get resolvingIdentity => 'Prijava u tijeku…';

  @override
  String get notLinkedTitle => 'Još samo korak';

  @override
  String get notLinkedBody => 'Vaš račun još nije povezan s programom. Upišite pozivni kod za dovršetak.';

  @override
  String get retryButton => 'Pokušaj ponovno';

  @override
  String get errInvalidCredentials => 'Pogrešna e-adresa ili lozinka.';

  @override
  String get errEmailInUseWrongPassword => 'Ova e-adresa već ima račun, ali lozinka nije točna.';

  @override
  String get errInvalidInvite => 'Pozivni kod nije važeći. Provjerite ga sa svojim fizioterapeutom.';

  @override
  String get errWeakPassword => 'Lozinka je preslaba — upotrijebite barem 6 znakova.';

  @override
  String get errInvalidEmail => 'To ne izgleda kao e-adresa.';

  @override
  String get errNetwork => 'Nema veze s internetom. Provjerite vezu i pokušajte ponovno.';

  @override
  String get errRequiresRecentLogin => 'Prijavite se ponovno pa pokušajte opet.';

  @override
  String get errUnknown => 'Nešto je pošlo po zlu. Pokušajte ponovno.';
}
