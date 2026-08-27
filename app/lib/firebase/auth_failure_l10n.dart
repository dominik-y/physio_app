import 'package:physio_app/firebase/auth_service.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

extension AuthFailureL10n on AuthFailure {
  String message(AppLocalizations l) => switch (this) {
        AuthFailure.invalidCredentials => l.errInvalidCredentials,
        AuthFailure.emailInUseWrongPassword => l.errEmailInUseWrongPassword,
        AuthFailure.invalidInvite => l.errInvalidInvite,
        AuthFailure.notLinked => l.notLinkedBody,
        AuthFailure.weakPassword => l.errWeakPassword,
        AuthFailure.invalidEmail => l.errInvalidEmail,
        AuthFailure.network => l.errNetwork,
        AuthFailure.requiresRecentLogin => l.errRequiresRecentLogin,
        AuthFailure.unknown => l.errUnknown,
      };
}
