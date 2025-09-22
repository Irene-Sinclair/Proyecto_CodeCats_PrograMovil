import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_codecats/Pantallas_Admin/panel_adm.dart';
import 'package:proyecto_codecats/Carrito/carrito.dart';
import 'package:proyecto_codecats/user_profile/User.dart';
import 'package:proyecto_codecats/botton_navigator.dart';
import 'package:proyecto_codecats/Catalogo/descripcion.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modelo de Producto
class Product {
   String id;
   bool activo;
   String categoria;
   String codigo;
   String imagen;
   String nombre;
   double precio;
   String talla;

  Product({
    required this.id,
    required this.activo,
    required this.categoria,
    required this.codigo,
    required this.imagen,
    required this.nombre,
    required this.precio,
    required this.talla,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      activo: data['activo'] ?? false,
      categoria: data['categoria'] ?? '',
      codigo: data['codigo'] ?? '',
      imagen: data['imagen'] ?? '',
      nombre: data['nombre'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      talla: data['talla'] ?? '',
    );
  }
}

class CatalogScreen extends StatefulWidget {
  @override
  _CatalogScreenState createState() => _CatalogScreenState();
  
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  bool _showFilters = false;
  int _currentIndex = 0; // Índice para Inicio



  
  final List<String> _categories = [
    'Camisetas',
    'Pantalones',
    'Zapatos',
    'Accesorios',
    'Vestidos',
    'Chaquetas'
  ];

  String _getAccessType() {
  final email = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
  return email == 'sinclairmejia02@gmail.com' ? 'admin' : 'user';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
          
            // Barra de búsqueda
            _buildSearchBar(),
            
            // Header del catálogo con filtros
            _buildCatalogHeader(),
            
            // Filtros (si están visibles)
            if (_showFilters) _buildFilters(),
            
            // Grid de productos
            Expanded(
              child: _buildProductsGrid(),
            ),
          ],
        ),
      ),
     bottomNavigationBar: CustomBottomNavigation(
  currentIndex: _currentIndex,
  onTap: (index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminSettingsScreen()));
        break;
    }
  },
  accessType: _getAccessType(), // 👈 AQUÍ EL CAMBIO
),
    );
  }



  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {}); // Actualizar la búsqueda
          },
        ),
      ),
    );
  }

  Widget _buildCatalogHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Catálogo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Row(
              children: [
                Text(
                  'Filtros',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.tune,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Todos', ''),
              ..._categories.map((category) => _buildFilterChip(category, category)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Products')
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.black,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar productos'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron productos',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        List<Product> products = snapshot.data!.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) => _filterProduct(product))
            .toList();

        if (products.isEmpty) {
          return Center(
            child: Text(
              'No hay productos que coincidan con los filtros',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  childAspectRatio: 0.65, // Cambia de 0.75 a 0.65
  crossAxisSpacing: 12,   // Reduce de 16 a 12
  mainAxisSpacing: 12,    // Reduce de 16 a 12
),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
  }

  bool _filterProduct(Product product) {
    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty &&
        !product.nombre.toLowerCase().contains(_searchController.text.toLowerCase())) {
      return false;
    }

    // Filtrar por categoría
    if (_selectedCategory.isNotEmpty && product.categoria != _selectedCategory) {
      return false;
    }

    return true;
  }

Widget _buildProductCard(Product product) {
  return GestureDetector(
    onTap: () {
      // Navegar a la pantalla ProductDescription con solo el código del producto
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDescription(productCode: product.codigo),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto - altura fija o flexible
              Container(
                height: constraints.maxHeight * 0.6,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        product.imagen,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.grey[400],
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (product.talla.isNotEmpty)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Talla ${_limitText(product.talla, 10)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Información del producto
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Categoría y nombre
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _limitText(product.categoria, 10),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          _limitText(product.nombre, 15),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Precio y código
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _limitText('L. ${product.precio.toStringAsFixed(0)}', 10),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _limitText(product.codigo, 50),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

String _limitText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}