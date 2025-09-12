import 'package:flutter/material.dart';
import 'login/login.dart'; // 👈 Importa tu archivo
import 'package:proyecto_codecats/Pantallas_Admin/panel_adm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Americano Cruz',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: const AdminSettingsScreen(), // 👈 Aquí llamamos la clase del archivo login.dart
    );
  }
}
