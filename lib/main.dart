import 'package:expence_flow_pro/features/auth/binding/auth_binding.dart';
import 'package:expence_flow_pro/features/settings/controller/settings_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/constants/app_theme.dart';
import 'database/app_database.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();

  // App-wide singletons — available everywhere, never disposed
  Get.put(AppDatabase(), permanent: true);
  Get.put(SettingsController(), permanent: true); // currency symbol used app-wide
  
  runApp(const ExpenseFlowApp());
}

class ExpenseFlowApp extends StatelessWidget {
  const ExpenseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: GetMaterialApp(
        title: 'ExpenseFlow',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        defaultTransition: Transition.fadeIn,
        getPages: appPages,
        initialRoute: AppRoutes.initialRoute,
        initialBinding: AuthBinding(),
        unknownRoute: GetPage(name: '/unknown_route', page: () => const UnknownRoute()),
      ),
    );
  }
}

class UnknownRoute extends StatelessWidget {
  const UnknownRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('No Route Here. Please contact the Developer.')));
  }
}
