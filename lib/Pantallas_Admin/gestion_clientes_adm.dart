import 'package:flutter/material.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  List<ClientModel> clients = [
    ClientModel(
      id: '1',
      name: 'Cliente 1',
      code: 'Código:11101',
      profileImage: 'https://via.placeholder.com/50',
    ),
    ClientModel(
      id: '2',
      name: 'Cliente 2',
      code: 'Código:11101',
      profileImage: 'https://via.placeholder.com/50',
    ),
    ClientModel(
      id: '3',
      name: 'Cliente 3',
      code: 'Código:11101',
      profileImage: 'https://via.placeholder.com/50',
    ),
  ];

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
      // Implementar consulta a Firestore
      // Simular carga por ahora
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error cargando clientes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteClient(String clientId) async {
    // No se usa más, eliminado
  }

  void _showClientDetails(ClientModel client) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Demo ver info del cliente')));
  }

  void _confirmDeleteClient(ClientModel client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Cliente'),
          content: Text(
            '¿Estás seguro de que deseas eliminar a ${client.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteClient(client.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
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
                      child: ClipOval(
                        child: client.profileImage.isNotEmpty
                            ? Image.network(
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
                              )
                            : Icon(
                                Icons.person,
                                size: 24,
                                color: Colors.blue.shade700,
                              ),
                      ),
                    ),
                    title: Text(
                      client.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      client.code,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showClientDetails(client),
                          icon: const Icon(Icons.visibility_outlined),
                          color: Colors.grey.shade600,
                        ),
                        IconButton(
                          onPressed: () => _confirmDeleteClient(client),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Modelo de datos para Cliente
class ClientModel {
  final String id;
  final String name;
  final String code;
  final String profileImage;

  ClientModel({
    required this.id,
    required this.name,
    required this.code,
    required this.profileImage,
  });
}
