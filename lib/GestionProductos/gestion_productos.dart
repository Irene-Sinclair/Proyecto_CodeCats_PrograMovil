import 'package:flutter/material.dart';
import 'package:proyecto_codecats/AgregarProductos/agregar_productos.dart';
import 'package:proyecto_codecats/EditarProductos/editar_productos.dart';

class GestionProductosScreen extends StatelessWidget {
  // Lista de productos ficticios
  final List<Map<String, String>> productos = [
    {
      'id': '1',
      'nombre': 'Producto 1',
      'codigo': '1101',
      'imagen': 'https://via.placeholder.com/50x50/8B4513/FFFFFF?text=P1'
    },
    {
      'id': '2',
      'nombre': 'Producto 2',
      'codigo': '1102',
      'imagen': 'https://via.placeholder.com/50x50/8B4513/FFFFFF?text=P2'
    },
    {
      'id': '3',
      'nombre': 'Producto 3',
      'codigo': '1103',
      'imagen': 'https://via.placeholder.com/50x50/8B4513/FFFFFF?text=P3'
    },
    {
      'id': '4',
      'nombre': 'Producto 4',
      'codigo': '1104',
      'imagen': 'https://via.placeholder.com/50x50/8B4513/FFFFFF?text=P4'
    },
    {
      'id': '5',
      'nombre': 'Producto 5',
      'codigo': '1105',
      'imagen': 'https://via.placeholder.com/50x50/8B4513/FFFFFF?text=P5'
    },
  ];

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
          
          // Lista de productos
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: productos.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final producto = productos[index];
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          producto['imagen']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Color(0xFF8B4513),
                              child: Center(
                                child: Text(
                                  'P${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    title: Text(
                      producto['nombre']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Código: ${producto['codigo']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón editar
                        GestureDetector(
                          onTap: () {
                            // Descomenta cuando tengas EditarProductoScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditarProductoScreen(
                                  productoId: producto['id']!,
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
                            _mostrarDialogoEliminar(context, producto['nombre']!);
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminar(BuildContext context, String nombreProducto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar producto'),
          content: Text('¿Estás seguro de que quieres eliminar "$nombreProducto"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Producto "$nombreProducto" eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
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
}

