import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/upload_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AIOutfitMatcherApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const UploadScreen(),
    ),
  ],
);

class AIOutfitMatcherApp extends StatelessWidget {
  const AIOutfitMatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryNeon = Color(0xFFB026FF);
    const backgroundDark = Color(0xFF0D0D14);
    const surfaceDark = Color(0xFF1A1A24);

    return MaterialApp.router(
      title: 'Outfit Matcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        primaryColor: primaryNeon,
        colorScheme: const ColorScheme.dark(
          primary: primaryNeon,
          secondary: Color(0xFF00E5FF),
          surface: surfaceDark,
          background: backgroundDark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryNeon,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: primaryNeon.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryNeon, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: surfaceDark,
          elevation: 8,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      routerConfig: _router,
    );
  }
}
