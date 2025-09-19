import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proyecto_codecats/Carrito/carrito.dart';
import 'package:proyecto_codecats/Catalogo/catalogo.dart';
import 'package:proyecto_codecats/botton_navigator.dart';
import 'package:proyecto_codecats/Pantallas_Admin/panel_adm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyecto_codecats/Login/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 2;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  
  // Controladores para los campos editables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('Clients').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
            // Llenar los controladores con los datos actuales
            _nameController.text = _userData['nombre'] ?? '';
            _phoneController.text = _userData['telefono'] ?? '';
            _cityController.text = _userData['ciudad'] ?? '';
            _addressController.text = _userData['direccion'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploadingImage = true);
        
        final User? user = _auth.currentUser;
        if (user != null) {
          // Subir imagen a Firebase Storage
          final File file = File(image.path);
          final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference storageRef = _storage.ref().child('profile_images/$fileName');
          
          // Subir el archivo
          final TaskSnapshot uploadTask = await storageRef.putFile(file);
          
          // Obtener la URL de descarga
          final String downloadURL = await uploadTask.ref.getDownloadURL();
          
          // Actualizar en Firestore
          await _firestore.collection('Clients').doc(user.uid).update({
            'imagen_perfil': downloadURL,
          });

          // Actualizar localmente
          setState(() {
            _userData['imagen_perfil'] = downloadURL;
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada')),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
    }
  }

  Future<void> _updateUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Clients').doc(user.uid).update({
          'nombre': _nameController.text.trim(),
          'telefono': _phoneController.text.trim(),
          'ciudad': _cityController.text.trim(),
          'direccion': _addressController.text.trim(),
        });

        // Recargar datos
        await _loadUserData();
        
        setState(() => _isEditing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Sección del avatar y nombre
                        _buildProfileHeader(),
                        
                        // Sección de información personal
                        _buildPersonalInfoSection(),
                      ],
                    ),
                  ),
          ),
          
          // Botón cerrar sesión o guardar cambios
          _isEditing ? _buildSaveButton() : _buildLogoutButton(),
          
          // Bottom navigation
          CustomBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (_isEditing) {
                // Si está editando, mostrar advertencia
                _showDiscardChangesDialog(index);
              } else {
                _navigateToScreen(index);
              }
            },
            accessType: 'admin',
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CatalogScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PaymentScreen()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminSettingsScreen()),
        );
        break;
    }
  }

  void _showDiscardChangesDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambios sin guardar'),
          content: const Text('Tienes cambios sin guardar. ¿Deseas descartarlos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isEditing = false);
                _navigateToScreen(index);
              },
              child: const Text('Descartar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () {
          if (_isEditing) {
            _showDiscardChangesDialog(2);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        _isEditing ? 'Editar Perfil' : 'Mi perfil',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () => setState(() => _isEditing = true),
          ),
        if (_isEditing)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _isEditing = false),
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Avatar con funcionalidad de subida
          Stack(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickAndUploadImage : null,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: _isUploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : _userData['imagen_perfil']?.isNotEmpty == true
                          ? ClipOval(
                              child: Image.network(
                                _userData['imagen_perfil'],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.black,
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.black,
                            ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Nombre del usuario (sin icono de lápiz)
          Text(
            _userData['nombre'] ?? 'Sin nombre',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildPersonalInfoSection() {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Row(
          children: [
            const Icon(Icons.person_outline, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Email (no editable)
        _buildInfoItem(
          icon: Icons.email_outlined,
          title: 'Email',
          value: _userData['email']?.isNotEmpty == true ? _userData['email']! : 'Sin email',
          isEditable: false,
        ),
        
        const SizedBox(height: 20),
        
        // Teléfono
        _buildInfoItem(
          icon: Icons.phone_outlined,
          title: 'Teléfono',
          value: _userData['telefono']?.isNotEmpty == true ? _userData['telefono']! : 'Sin teléfono',
          isEditable: true,
          controller: _phoneController,
        ),
        
        const SizedBox(height: 20),
        
        // Ciudad
        _buildInfoItem(
          icon: Icons.location_city_outlined,
          title: 'Ciudad',
          value: _userData['ciudad']?.isNotEmpty == true ? _userData['ciudad']! : 'Sin ciudad',
          isEditable: true,
          controller: _cityController,
        ),
        
        const SizedBox(height: 20),
        
        // Dirección
        _buildInfoItem(
          icon: Icons.home_outlined,
          title: 'Dirección',
          value: _userData['direccion']?.isNotEmpty == true ? _userData['direccion']! : 'Sin dirección',
          isEditable: true,
          controller: _addressController,
        ),

        const SizedBox(height: 20),
        
        // Nombre
        _buildInfoItem(
          icon: Icons.person_outlined,
          title: 'Nombre Completo',
          value: _userData['nombre']?.isNotEmpty == true ? _userData['nombre']! : 'Sin nombre',
          isEditable: true,
          controller: _nameController,
        ),
      ],
    ),
  );
}

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isEditable,
    TextEditingController? controller,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              _isEditing && isEditable
                  ? TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: value,
                        border: const UnderlineInputBorder(),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
            ],
          ),
        ),
        if (_isEditing && isEditable)
          const Icon(Icons.edit, color: Colors.grey, size: 18),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _showLogoutDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _updateUserData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Guardar Cambios',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _logoutUser();
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logoutUser() async {
    try {
      await _auth.signOut();
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }
}