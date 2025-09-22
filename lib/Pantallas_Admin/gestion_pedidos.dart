import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GestionPedidosScreen extends StatefulWidget {
  GestionPedidosScreen({Key? key}) : super(key: key);

  @override
  _GestionPedidosScreenState createState() => _GestionPedidosScreenState();
}

class _GestionPedidosScreenState extends State<GestionPedidosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gestión de Pedidos',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por código de pedido...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500]),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          
          // Lista de pedidos desde Firebase
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('Orders')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay pedidos registrados',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Los pedidos aparecerán aquí',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final pedidos = snapshot.data!.docs;

                  // Filtrar pedidos según el texto de búsqueda
                  final pedidosFiltrados = pedidos.where((pedido) {
                    if (_searchText.isEmpty) return true;
                    
                    final pedidoId = pedido.id;
                    final datos = pedido.data() as Map<String, dynamic>;
                    final String userName = datos['user_name'] ?? '';
                    
                    // Buscar por ID de pedido (completo o parcial)
                    return pedidoId.toLowerCase().contains(_searchText.toLowerCase()) ||
                           userName.toLowerCase().contains(_searchText.toLowerCase());
                  }).toList();

                  if (pedidosFiltrados.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No se encontraron pedidos',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Intenta con otro término de búsqueda',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: pedidosFiltrados.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final pedido = pedidosFiltrados[index];
                      final datos = pedido.data() as Map<String, dynamic>;
                      final pedidoId = pedido.id;
                      final String estado = datos['status'] ?? 'pendiente';
                      final String userName = datos['user_name'] ?? 'Cliente';
                      final double total = (datos['total'] ?? 0).toDouble();
                      final Timestamp? createdAt = datos['created_at'] as Timestamp?;
                      final List<dynamic> items = datos['items'] ?? [];

                      // Formatear fecha
                      String fechaFormateada = 'Fecha no disponible';
                      if (createdAt != null) {
                        fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate());
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getColorByEstado(estado),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Icon(
                              _getIconByEstado(estado),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido: ${pedidoId.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cliente: $userName',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              'Total: L${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Fecha: $fechaFormateada',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Artículos: ${items.length}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            // Estado del pedido
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getColorByEstado(estado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getColorByEstado(estado),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getIconByEstado(estado),
                                    size: 12,
                                    color: _getColorByEstado(estado),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _getTextoEstado(estado),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: _getColorByEstado(estado),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                        onTap: () {
                          _mostrarDetallesPedido(context, pedidoId, datos);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función para obtener color según el estado
  Color _getColorByEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.amber;
    }
  }

  // Función para obtener icono según el estado
  IconData _getIconByEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      case 'pendiente':
      default:
        return Icons.access_time;
    }
  }

  // Función para obtener texto formateado del estado
  String _getTextoEstado(String estado) {
    return estado[0].toUpperCase() + estado.substring(1);
  }

  // Función para mostrar detalles del pedido
  void _mostrarDetallesPedido(BuildContext context, String pedidoId, Map<String, dynamic> datos) {
    final String estado = datos['status'] ?? 'pendiente';
    final String userName = datos['user_name'] ?? 'Cliente';
    final String userPhone = datos['user_phone'] ?? 'No especificado';
    final double total = (datos['total'] ?? 0).toDouble();
    final Timestamp? createdAt = datos['created_at'] as Timestamp?;
    final String metodoPago = datos['payment_method'] ?? 'No especificado';
    final String direccion = datos['shipping_address'] ?? 'No especificada';
    final List<dynamic> items = datos['items'] ?? [];

    String fechaFormateada = 'Fecha no disponible';
    if (createdAt != null) {
      fechaFormateada = DateFormat('dd/MM/yyyy HH:mm:ss').format(createdAt.toDate());
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles del Pedido'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información del pedido
                _buildInfoItem('ID del Pedido', pedidoId),
                _buildInfoItem('Cliente', userName),
                if (userPhone.isNotEmpty) _buildInfoItem('Teléfono', userPhone),
                _buildInfoItem('Fecha', fechaFormateada),
                _buildInfoItem('Total', 'L${total.toStringAsFixed(2)}'),
                _buildInfoItem('Método de Pago', metodoPago),
                _buildInfoItem('Dirección', direccion),
                
                // Estado
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getColorByEstado(estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getColorByEstado(estado)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIconByEstado(estado), size: 16, color: _getColorByEstado(estado)),
                      SizedBox(width: 6),
                      Text(
                        _getTextoEstado(estado),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _getColorByEstado(estado),
                        ),
                      ),
                    ],
                  ),
                ),

                // Artículos
                SizedBox(height: 20),
                Text(
                  'Artículos (${items.length}):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                ...items.map((item) {
                  final Map<String, dynamic> itemData = item as Map<String, dynamic>;
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemData['nombre'] ?? 'Sin nombre',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 2),
                              Text('Talla: ${itemData['talla'] ?? 'N/A'}'),
                              Text('Cantidad: ${itemData['cantidad'] ?? 1}'),
                            ],
                          ),
                        ),
                        Text(
                          'L${(itemData['precio'] ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
            // Mostrar opciones según el estado actual
            if (estado == 'pendiente') ...[
              TextButton(
                onPressed: () => _cambiarEstadoPedido(context, pedidoId, 'completado'),
                child: Text('Marcar como Completado', style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () => _cancelarPedido(context, pedidoId, datos),
                child: Text('Cancelar Pedido', style: TextStyle(color: Colors.red)),
              ),
            ],
            if (estado == 'completado') ...[
              TextButton(
                onPressed: () => _cancelarPedido(context, pedidoId, datos),
                child: Text('Cancelar Pedido', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      )
    );
  }

  Future<void> _cambiarEstadoPedido(BuildContext context, String pedidoId, String nuevoEstado) async {
    try {
      await _firestore.collection('Orders').doc(pedidoId).update({
        'status': nuevoEstado,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado del pedido actualizado a ${_getTextoEstado(nuevoEstado)}'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context); // Cerrar el diálogo de detalles
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para cancelar pedido y reactivar productos

Future<void> _cancelarPedido(BuildContext context, String pedidoId, Map<String, dynamic> datos) async {
  try {
    // 1. Cambiar estado del pedido a "cancelado"
    await _firestore.collection('Orders').doc(pedidoId).update({
      'status': 'cancelado',
    });

    // 2. Reactivar todos los productos del pedido
    final List<dynamic> items = datos['items'] ?? [];
    
    for (var item in items) {
      final Map<String, dynamic> itemData = item as Map<String, dynamic>;
      final String productNombre = itemData['nombre'] ?? '';
      
      print('Intentando reactivar producto: $productNombre');
      
      if (productNombre.isNotEmpty) {
        try {
          // Buscar el producto por nombre
          final querySnapshot = await _firestore
              .collection('Products')
              .where('nombre', isEqualTo: productNombre)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            for (final doc in querySnapshot.docs) {
              await _firestore.collection('Products').doc(doc.id).update({
                'activo': true,
              });
              print('✓ Producto reactivado: $productNombre (ID: ${doc.id})');
            }
          } else {
            print('✗ No se encontró producto con nombre: $productNombre');
          }
        } catch (e) {
          print('Error al reactivar producto $productNombre: $e');
        }
      } else {
        print('Nombre de producto vacío en el item: $itemData');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido cancelado y productos reactivados'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context); // Cerrar el diálogo de detalles
  } catch (error) {
    print('Error detallado: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al cancelar pedido: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}