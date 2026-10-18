import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← NOUVEAU
import 'package:stageapp/homepage.dart'; // ← Remplacer par votre chemin d'import
import 'package:stageapp/auth/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initializeDateFormatting('fr_FR', null); // ← NOUVEAU

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stage App - Station Météo IoT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: FirebaseAuth.instance.currentUser != null
          ? const MyHomePageDynamic() // ← Changé: MyHomePage → MyHomePageDynamic
          : const loginpage(),
      routes: {
        'loginpage': (context) => const loginpage(),
        'homepage': (context) => const MyHomePageDynamic(), // ← Changé
      },
    );
  }
}
