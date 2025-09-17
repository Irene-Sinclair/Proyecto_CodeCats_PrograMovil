import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String accessType; // Variable para el tipo de acceso

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.accessType, // Recibir el tipo de acceso
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar si es admin
    bool isAdmin = accessType == 'admin';

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
        items: isAdmin 
          ? _buildAdminItems() // Items para admin
          : _buildUserItems(), // Items para usuario normal
      ),
    );
  }

  // Items para usuarios administradores
  List<BottomNavigationBarItem> _buildAdminItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Carrito',
      ),
      
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings), // Ícono de tuerca para admin
        label: 'Admin',
      ),
    ];
  }

  // Items para usuarios normales
  List<BottomNavigationBarItem> _buildUserItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Carrito',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];
  }
}