import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 agrega este import

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String accessType; // lo conservamos para no romper nada

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.accessType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ ÚNICA fuente de verdad: el correo del usuario autenticado
    final email = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    final bool isAdmin = (email == 'admin@gmail.com'); // 👈 aquí decidimos

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
        currentIndex: currentIndex,
        onTap: onTap,
        items: isAdmin ? _buildAdminItems() : _buildUserItems(),
      ),
    );
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
