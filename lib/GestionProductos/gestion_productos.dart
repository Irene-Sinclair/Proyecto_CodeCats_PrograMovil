import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_codecats/AgregarProductos/agregar_productos.dart';
import 'package:proyecto_codecats/EditarProductos/editar_productos.dart';

class GestionProductosScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          'Gestión de Productos',
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
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          // Botón Agregar
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navegar a AgregarProductoScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgregarProductoScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Agregar',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de productos desde Firebase
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('Products').snapshots(),
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
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay productos registrados',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Presiona "Agregar" para crear el primero',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final productos = snapshot.data!.docs;

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: productos.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      final datos = producto.data() as Map<String, dynamic>;
                      final productoId = producto.id;
                      final bool estaActivo = datos['activo'] ?? false;

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: datos['imagen'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    datos['imagen'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage(datos['nombre'] ?? 'P');
                                    },
                                  ),
                                )
                              : _buildPlaceholderImage(datos['nombre'] ?? 'P'),
                        ),
                        title: Text(
                          datos['nombre'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: estaActivo ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Código: ${datos['codigo'] ?? 'Sin código'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Talla: ${datos['talla'] ?? 'Sin talla'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Precio: \$${datos['precio']?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            // Estado del producto
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: estaActivo ? Colors.green[50] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: estaActivo ? Colors.green : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    estaActivo ? Icons.check_circle : Icons.cancel,
                                    size: 12,
                                    color: estaActivo ? Colors.green : Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    estaActivo ? 'Activo' : 'Inactivo',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: estaActivo ? Colors.green : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón editar
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarProductoScreen(
                                      productoId: productoId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Botón eliminar
                            GestureDetector(
                              onTap: () {
                                _mostrarDialogoEliminar(
                                  context,
                                  datos['nombre'] ?? 'este producto',
                                  productoId,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildPlaceholderImage(String nombre) {
    return Container(
      color: Color(0xFF8B4513),
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'P',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoEliminar(BuildContext context, String nombreProducto, String productoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar producto'),
          content: Text('¿Estás seguro de que quieres eliminar "$nombreProducto"?\n\nEsta acción también lo eliminará de todos los carritos de compras.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Primero eliminar el producto de todos los carritos
                  await _eliminarProductoDeCarritos(productoId);
                  
                  // Luego eliminar el producto de la colección Products
                  await _firestore.collection('Products').doc(productoId).delete();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Producto "$nombreProducto" eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarProductoDeCarritos(String productoId) async {
    try {
      // Buscar todos los documentos en la colección Carts que tengan este producto
      QuerySnapshot carritosQuery = await _firestore
          .collection('Carts')
          .where('id_product', isEqualTo: productoId)
          .get();

      // Eliminar cada documento encontrado
      for (QueryDocumentSnapshot doc in carritosQuery.docs) {
        await doc.reference.delete();
      }

      print('Producto eliminado de ${carritosQuery.docs.length} carritos');
    } catch (error) {
      print('Error eliminando producto de carritos: $error');
      throw error; // Relanzar el error para manejarlo en el método principal
    }
  }
}