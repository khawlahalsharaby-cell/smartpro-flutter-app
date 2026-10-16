import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'views/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartProApp());
}

class SmartProApp extends StatefulWidget {
  const SmartProApp({super.key});

  @override
  State<SmartProApp> createState() => _SmartProAppState();
}

class _SmartProAppState extends State<SmartProApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SmartPro ERP',
      debugShowCheckedModeBanner: false,

      // ── دعم اللغة العربية والـ RTL ──────────────────
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },

      // ── الثيمات ───────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,

      // ── الهيكل الرئيسي مع تمرير الثيم ────────────
      home: MainShell(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) {
          setState(() => _themeMode = mode);
        },
      ),
    );
  }
}
