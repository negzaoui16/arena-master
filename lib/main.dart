import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/challenges_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/edit_profile_screen.dart';
import 'theme/app_theme.dart';
// Cursor control system imports
import 'features/cursor_control/logic/face_messenger.dart';
import 'features/cursor_control/logic/cursor_controller.dart';
import 'features/cursor_control/logic/inactivity_detector.dart';
import 'features/cursor_control/ui/cursor_overlay.dart';

// Global cursor controller accessors
late CursorController globalCursorController;
late InactivityDetector globalInactivityDetector;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request camera permission at startup
  await Permission.camera.request();
  
  // Initialize cursor control system
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
  runApp(ArenaApp(
    cursorController: cursorController,
    inactivityDetector: inactivityDetector,
  ));
}

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
      // Wrap with cursor overlay and touch listener
      builder: (context, child) {
        return Listener(
          onPointerDown: (event) {
            // Only treat as user interaction if cursor is NOT currently showing
            // This prevents the simulated click from hiding the cursor
            if (!cursorController.isClicking) {
              inactivityDetector.onUserInteraction();
            }
          },
          onPointerMove: (event) {
            if (!cursorController.isClicking) {
              inactivityDetector.onUserInteraction();
            }
          },
          child: CursorOverlay(
            controller: cursorController,
            inactivityDetector: inactivityDetector,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/home': (context) => const MainShell(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
      },
    );
  }
}

/// Main shell with bottom navigation
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChallengesScreen(),
    const SizedBox(), // placeholder for FAB action
    const ChallengesScreen(), // Rankings reuses challenges for now
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00C2FF);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F141C).withAlpha(230) : Colors.white.withAlpha(230),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withAlpha(13) : Colors.grey.shade200,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                _buildNavItem(Icons.code_outlined, Icons.code, 'Challenges', 1),
                _buildFab(primaryColor),
                _buildNavItem(Icons.leaderboard_outlined, Icons.leaderboard, 'Rankings', 3),
                _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    final primaryColor = const Color(0xFF00C2FF);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(Color primaryColor) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to create challenge
      },
      child: Container(
        width: 56,
        height: 56,
        transform: Matrix4.translationValues(0, -16, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, const Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(100),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0B0E14)
                : Colors.white,
            width: 4,
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
