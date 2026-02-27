import 'package:flutter/material.dart';
import 'package:arena/core/theme/app_theme.dart';
import 'package:arena/app/router.dart';
import 'package:arena/features/cursor_control/logic/cursor_controller.dart';
import 'package:arena/features/cursor_control/logic/inactivity_detector.dart';
import 'package:arena/features/cursor_control/ui/cursor_overlay.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

/// Root application widget.
class ArenaApp extends StatelessWidget {
  final CursorController cursorController;
  final InactivityDetector inactivityDetector;

  const ArenaApp({
    super.key,
    required this.cursorController,
    required this.inactivityDetector,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arena of Coders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return stream.StreamChatTheme(
          data: isDark
              ? stream.StreamChatThemeData.dark()
              : stream.StreamChatThemeData.light(),
          child: Listener(
            onPointerDown: (_) {
              if (!cursorController.isClicking) {
                inactivityDetector.onUserInteraction();
              }
            },
            onPointerMove: (_) {
              if (!cursorController.isClicking) {
                inactivityDetector.onUserInteraction();
              }
            },
            child: CursorOverlay(
              controller: cursorController,
              inactivityDetector: inactivityDetector,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
