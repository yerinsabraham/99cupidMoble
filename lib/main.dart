import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'routes/app_router.dart';
import 'data/services/notification_service.dart';
import 'data/services/user_account_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final UserAccountService _userAccountService = UserAccountService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLastSeenUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startLastSeenUpdates() {
    // Update lastSeen immediately on app start if user is logged in
    if (FirebaseAuth.instance.currentUser != null) {
      _userAccountService.updateLastSeen();
    }

    // Update lastSeen every 2 minutes while app is running
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 2));
      if (mounted && FirebaseAuth.instance.currentUser != null) {
        _userAccountService.updateLastSeen();
        return true;
      }
      return false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update lastSeen when app becomes active
    if (state == AppLifecycleState.resumed && FirebaseAuth.instance.currentUser != null) {
      _userAccountService.updateLastSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: '99cupid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cupidPink,
          primary: AppColors.cupidPink,
          secondary: AppColors.deepPlum,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.softIvory,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cupidPink,
          primary: AppColors.cupidPink,
          secondary: AppColors.deepPlum,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
