import 'package:flutter_test/flutter_test.dart';

import 'package:arena/main.dart';
import 'package:arena/features/cursor_control/logic/face_messenger.dart';
import 'package:arena/features/cursor_control/logic/cursor_controller.dart';
import 'package:arena/features/cursor_control/logic/inactivity_detector.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    // Create cursor control dependencies for testing
    final faceMessenger = FaceMessenger();
    final cursorController = CursorController(faceMessenger);
    final inactivityDetector = InactivityDetector();
    
    await tester.pumpWidget(ArenaApp(
      cursorController: cursorController,
      inactivityDetector: inactivityDetector,
    ));
    await tester.pumpAndSettle();

    // Verify that the splash screen renders with the app title
    expect(find.text('Get Started'), findsOneWidget);
  });
}

