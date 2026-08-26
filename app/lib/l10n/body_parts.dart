import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Body parts are stored as canonical English strings (data, grouping keys,
/// thumb palette seeds); only their *display* localizes. Unknown values pass
/// through so physio-typed custom parts still render.
String localizedBodyPart(AppLocalizations l, String bodyPart) {
  return switch (bodyPart) {
    'Knee' => l.bodyPartKnee,
    'Shoulder' => l.bodyPartShoulder,
    'Lower back' => l.bodyPartLowerBack,
    'Neck' => l.bodyPartNeck,
    _ => bodyPart,
  };
}
