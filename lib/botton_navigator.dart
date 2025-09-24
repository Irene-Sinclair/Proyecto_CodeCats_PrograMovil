import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// importa  pantallas para poder detectarlas por tipo
import 'package:proyecto_codecats/Catalogo/catalogo.dart';
import 'package:proyecto_codecats/user_profile/User.dart';
import 'package:proyecto_codecats/Pantallas_Admin/panel_adm.dart';
import 'package:proyecto_codecats/Carrito/carrito.dart'; 

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;          // se mantiene para compatibilidad
  final Function(int) onTap;
  final String accessType;         // se mantiene para no romper nada

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.accessType,
  }) : super(key: key);

  @override
  _CustomBottomNavigationState createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  bool isAdmin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final email = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    
    if (email == null) {
      setState(() {
        isAdmin = false;
        isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('information')
          .doc('admin')
          .get();
      
      if (adminDoc.exists && adminDoc.data() != null) {
        final data = adminDoc.data() as Map<String, dynamic>;
        String adminEmail = (data['correo'] ?? '').toString().toLowerCase().trim();
        setState(() {
          isAdmin = (email == adminEmail);
          isLoading = false;
        });
      } else {
        setState(() {
          isAdmin = false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      setState(() {
        isAdmin = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si aún está cargando, mostrar versión básica
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          currentIndex: 0,
          onTap: widget.onTap,
          items: _buildUserItems(), // Mostrar items de usuario por defecto mientras carga
        ),
      );
    }

    // index para identidicar pantallas
    final int activeIndex = _guessIndexFromContext(context, widget.currentIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        currentIndex: activeIndex,   // usamos el indice
        onTap: widget.onTap,
        items: isAdmin ? _buildAdminItems() : _buildUserItems(),
      ),
    );
  }

  /// detectar en qué pantalla estamos mirando el árbol de widgets.
  /// Si no logra detectarlo, usa el `fallback` (el currentIndex que ya pasas).
  int _guessIndexFromContext(BuildContext context, int fallback) {
    // Busca ancestros por tipo de widget (o State)
    if (context.findAncestorWidgetOfExactType<CatalogScreen>() != null ||
        context.findAncestorStateOfType<State<CatalogScreen>>() != null) {
      return 0;
    }
    if (context.findAncestorWidgetOfExactType<PaymentScreen>() != null ||
        context.findAncestorStateOfType<State<PaymentScreen>>() != null) {
      return 1;
    }
    if (context.findAncestorWidgetOfExactType<ProfileScreen>() != null ||
        context.findAncestorStateOfType<State<ProfileScreen>>() != null) {
      return 2;
    }
    if (context.findAncestorWidgetOfExactType<AdminSettingsScreen>() != null ||
        context.findAncestorStateOfType<State<AdminSettingsScreen>>() != null) {
      return 3;
    }
    return fallback; // por si acaso
  }

  List<BottomNavigationBarItem> _buildAdminItems() => const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Admin'),
  ];

  List<BottomNavigationBarItem> _buildUserItems() => const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
  ];
}