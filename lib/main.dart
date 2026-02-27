import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:arena/app/app.dart';
import 'package:arena/features/cursor_control/logic/face_messenger.dart';
import 'package:arena/features/cursor_control/logic/cursor_controller.dart';
import 'package:arena/features/cursor_control/logic/inactivity_detector.dart';
import 'package:arena/core/services/push_notification_service.dart';

// Global accessors for cursor control (used by CursorOverlay + ProfileScreen toggle)
late CursorController globalCursorController;
late InactivityDetector globalInactivityDetector;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  await Permission.camera.request();

  final faceMessenger = FaceMessenger();
  final cursorController = CursorController(faceMessenger);
  final inactivityDetector = InactivityDetector();

  globalCursorController = cursorController;
  globalInactivityDetector = inactivityDetector;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize push notifications (after Firebase)
  PushNotificationService().init();

  runApp(ArenaApp(
    cursorController: cursorController,
    inactivityDetector: inactivityDetector,
  ));
}
