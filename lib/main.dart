import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'login/login.dart ';
import 'Catalogo/catalogo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lee preferencia de "recordarme". Si es false, cerramos sesión antes de construir la UI.
  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool('remember_me') ?? false;
  if (!remember && FirebaseAuth.instance.currentUser != null) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snap.data != null) return CatalogoWrapper();
          return const LoginPage();
        },
      ),
    );
  }
}


class CatalogoWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CatalogScreen();
}
