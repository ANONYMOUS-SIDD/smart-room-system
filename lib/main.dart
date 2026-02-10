import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_room/screens/home/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'controllers/auth_controller.dart';
import 'controllers/loader_controller.dart';
import 'controllers/show_password_controller.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/toast_service.dart';
import 'config.dart';
import 'chat/services/chat_service.dart';

/// MAIN APPLICATION ENTRY POINT
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await _initializePermissionHandler();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

/// INITIALIZE APPLICATION PERMISSIONS
Future<void> _initializePermissionHandler() async {
  await Permission.location.request();

  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }

  if (await Permission.camera.isDenied) {
    await Permission.camera.request();
  }

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

/// ROOT APPLICATION WIDGET
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

/// DEPENDENCY INJECTION BINDINGS FOR APPLICATION SERVICES
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoaderController(), fenix: true);
    Get.lazyPut(() => ShowPasswordController(), fenix: true);
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => ToastService(), fenix: true);
    Get.lazyPut(() => ChatService(), fenix: true);
    Get.lazyPut(() => PermissionHandlerService(), fenix: true);
    Get.lazyPut(() => Supabase.instance.client, fenix: true);
  }
}

/// PERMISSION HANDLING SERVICE FOR APPLICATION PERMISSIONS MANAGEMENT
class PermissionHandlerService extends GetxService {

  Future<bool> get isLocationGranted async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  Future<bool> get isStorageGranted async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestStoragePermission() async {
    return await Permission.storage.request();
  }

  Future<bool> get isCameraGranted async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'storage': await Permission.storage.isGranted,
      'camera': await Permission.camera.isGranted,
    };
  }
}

/// MAIN APPLICATION HOME WIDGET CONTAINER
class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  /// INITIALIZE CHAT SERVICE AFTER APPLICATION STARTUP
  Future<void> _initializeChat() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      final chatService = Get.find<ChatService>();
    } catch (e) {
      // CHAT SERVICE INITIALIZATION ERROR HANDLED SILENTLY
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SplashScreen(),
    );
  }
}