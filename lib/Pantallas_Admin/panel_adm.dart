import 'package:flutter/material.dart';
import 'package:proyecto_codecats/AgregarProductos/agregar_productos.dart';
import 'package:proyecto_codecats/GestionProductos/gestion_productos.dart';
import 'package:proyecto_codecats/Pantallas_Admin/gestion_clientes_adm.dart';
import 'package:proyecto_codecats/Carrito/carrito.dart';
import 'package:proyecto_codecats/Catalogo/catalogo.dart';
import 'package:proyecto_codecats/botton_navigator.dart';
import 'package:proyecto_codecats/user_profile/User.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 3; // Índice para Ajustes (admin)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToScreen(Widget screenName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screenName),
    );
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navegar a la pantalla correspondiente
    switch (index) {
      case 0: // Inicio
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CatalogScreen()),
        );
        break;
      case 1: // Carrito
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaymentScreen()),
        );
        break;
      case 2: // Perfil 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()), // Cambia por tu pantalla de perfil
        );
        break;
      case 3: // Ajustes Admin (ya estamos aquí)
        // No hacer nada, ya estamos en ajustes
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'Ajustes de administrador',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildMenuOption(
                icon: Icons.edit_outlined,
                title: 'Gestión de Productos',
                onTap: () => _navigateToScreen(GestionProductosScreen()),
                index: 0,
              ),
              const SizedBox(height: 16),
              _buildMenuOption(
                icon: Icons.person_outline,
                title: 'Gestión de Clientes',
                onTap: () => _navigateToScreen(ClientManagementScreen()),
                index: 1,
              ),
              const SizedBox(height: 16),
              _buildMenuOption(
                icon: Icons.add_circle_outline,
                title: 'Crear Productos',
                onTap: () => _navigateToScreen(AgregarProductoScreen()),
                index: 2,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavItemTapped,
        accessType: 'admin', // Siempre es admin en esta pantalla
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int index,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 10)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.black.withOpacity(0.1),
                  highlightColor: Colors.black.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.black, 
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}