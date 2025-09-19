import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vizualizacion_clientes.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  List<ClientModel> clients = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClientsFromFirebase();
  }

  Future<void> _loadClientsFromFirebase() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Consultar la colección "Clients" en Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Clients')
          .get();

      List<ClientModel> loadedClients = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          loadedClients.add(
            ClientModel(
              id: (data['ID'] as String?) ?? doc.id,
              name:
                  (data['nombre'] as String?) ??
                  'Sin nombre',
                code: (data['ID'] as String?) ?? doc.id,
              profileImage:
                  (data['imagen_perfil'] as String?) ??
                  '',
              email: (data['email'] as String?) ?? '',
              phone:
                  (data['telefono'] as String?) ??
                  'Sin teléfono',
              city:
                  (data['ciudad'] as String?) ??
                  'Sin ciudad',
              address:
                  (data['direccion'] as String?) ??
                  'Sin dirección',
              password:
                  (data['password'] as String?) ?? '',
            ),
          );
        }
      }

      setState(() {
        clients = loadedClients;
        isLoading = false;
      });
    } catch (e) {
      print('Error cargando clientes: $e');
      // Mostrar error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // ELIMINÉ LOS MÉTODOS DE ELIMINACIÓN
  // Future<void> _deleteClient(String clientId) async { ... }
  // void _confirmDeleteClient(ClientModel client) { ... }

  void _showClientDetails(ClientModel client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisualizacionClientesScreen(
          clientId: client.id,
          clientName: client.name,
          clientEmail: client.email,
          clientCode: client.code,
          clientPhone: client.phone.isNotEmpty ? client.phone : 'Sin teléfono',
          clientCity: client.city.isNotEmpty ? client.city : 'Sin ciudad',
          clientAddress: client.address.isNotEmpty
              ? client.address
              : 'Sin dirección',
          clientProfileImage: client.profileImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text(
          'Gestión de Clientes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadClientsFromFirebase,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clients.isEmpty
          ? const Center(
              child: Text(
                'No hay clientes disponibles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: client.profileImage.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                client.profileImage,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.blue.shade700,
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      );
                                    },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 24,
                              color: Colors.blue.shade700,
                            ),
                    ),
                    title: Text(
                      client.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (client.email.isNotEmpty)
                          Text(
                            client.email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        Text(
                          client.code,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton( // ← SOLO QUEDÓ EL BOTÓN DE VISUALIZAR
                      onPressed: () => _showClientDetails(client),
                      icon: const Icon(Icons.visibility_outlined),
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Modelo de datos para Cliente actualizado con todos los campos
class ClientModel {
  final String id;
  final String name;
  final String code;
  final String profileImage;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String password;

  ClientModel({
    required this.id,
    required this.name,
    required this.code,
    required this.profileImage,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    required this.password,
  });

  // Método para convertir desde Firestore
  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    return ClientModel(
      id: (data?['ID'] as String?) ?? doc.id,
      name: (data?['nombre'] as String?) ?? 'Sin nombre',
      code: (data?['ID'] as String?) ?? doc.id,
      profileImage: (data?['imagen_perfil'] as String?) ?? '',
      email: (data?['email'] as String?) ?? '',
      phone: (data?['telefono'] as String?) ?? '',
      city: (data?['ciudad'] as String?) ?? '',
      address: (data?['direccion'] as String?) ?? '',
      password: (data?['password'] as String?) ?? '',
    );
  }

  // Método para convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ID': id,
      'nombre': name,
      'email': email,
      'telefono': phone,
      'ciudad': city,
      'direccion': address,
      'imagen_perfil': profileImage,
      'password': password,
    };
  }
}