import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// YouTube-style fullscreen stage: rotates to landscape and hides system
/// chrome while open, restores portrait on exit. The hosted player renders
/// its own exit control and pops with its playback position so the inline
/// player can resume where fullscreen left off.
class FullscreenVideoPage extends StatefulWidget {
  final WidgetBuilder builder;

  const FullscreenVideoPage({super.key, required this.builder});

  static Future<T?> open<T>(BuildContext context, WidgetBuilder builder) {
    return Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenVideoPage(builder: builder),
      ),
    );
  }

  /// Pops the fullscreen stage. Portrait is restored BEFORE the pop and the
  /// call waits for the rotation to land — popping while the window is still
  /// landscape paints the portrait page underneath at landscape size for a
  /// frame (visible overflow flash during the pop animation).
  static Future<void> exit<T extends Object?>(
      BuildContext context, T result) async {
    final navigator = Navigator.of(context);
    final view = View.of(context);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!kIsWeb) {
      for (var i = 0;
          i < 45 && view.physicalSize.width > view.physicalSize.height;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }
    navigator.pop(result);
  }

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: widget.builder(context)),
    );
  }
}
