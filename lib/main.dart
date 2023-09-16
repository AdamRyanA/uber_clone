import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uber_clone/app/pages/Splash/splash_page.dart';
import 'package:uber_clone/app/utils/route_generator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber',
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      onGenerateRoute: RouteGenerator.generatorRoute,
      initialRoute: "/",
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
    );
  }
}

final ThemeData temaPadrao = ThemeData(
  primaryColor: const Color(0xff37474f),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: const Color(0xff546e7a),
  ),
);
