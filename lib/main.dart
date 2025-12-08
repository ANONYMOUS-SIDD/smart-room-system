import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_room/screens/home/splash_screen.dart';

import 'controllers/auth_controller.dart';
import 'controllers/loader_controller.dart';
import 'controllers/show_password_controller.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/toast_service.dart';

/// Main Application Entry Point
Future<void> main() async {
  /// Ensure Flutter Framework Is Initialized Before Any Async Operations
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// Set Transparent Status Bar With Dark Icons (Black Icons)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent Status Bar
      statusBarIconBrightness: Brightness.dark, // Black Icons For Android
      statusBarBrightness: Brightness.light, // Black Icons For iOS
      systemNavigationBarColor: Colors.white, // White Navigation Bar
      systemNavigationBarIconBrightness: Brightness.dark, // Black Navigation Icons
    ),
  );

  runApp(const MyApp());
}

/// Root Application Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialBinding: AppBindings(),
      home: const AppHome(),
    );
  }
}

/// Dependency Injection Binding Class
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Register Controllers
    Get.lazyPut(() => LoaderController(), fenix: true);
    Get.lazyPut(() => ShowPasswordController(), fenix: true);
    Get.lazyPut(() => AuthController(), fenix: true);

    // Register Services
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => ToastService(), fenix: true);
  }
}

/// Main Application Home Widget
class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white, body: SplashScreen());
  }
}
