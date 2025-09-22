import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDescription extends StatefulWidget {
  final String productCode;

  const ProductDescription({Key? key, required this.productCode})
    : super(key: key);

  @override
  _ProductDescriptionState createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  String? errorMessage;
  bool isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Buscar el producto por codigo
      QuerySnapshot productSnapshot = await firestore
          .collection('Products')
          .where('codigo', isEqualTo: widget.productCode)
          .limit(1)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        setState(() {
          productData =
              productSnapshot.docs.first.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Producto no encontrado';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar el producto: $e';
        isLoading = false;
      });
      print('Error loading product: $e');
    }
  }

  Future<void> _addToCart() async {
  // Verificar si el usuario esta autenticado
  final User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    _showCustomSnackbar(
      'Debes iniciar sesión para agregar productos al carrito',
      Colors.orange,
    );
    return;
  }

  setState(() {
    isAddingToCart = true;
  });

  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Verificar si el producto ya esta en el carrito del usuario
    QuerySnapshot cartQuery = await firestore
        .collection('Carts')
        .where('id_product', isEqualTo: widget.productCode)
        .where('id_user', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (cartQuery.docs.isNotEmpty) {
      setState(() {
        isAddingToCart = false;
      });
      
      _showCustomSnackbar('Ya tienes este producto en tu carrito', Colors.blue);
      return;
    }

    // Agregar el producto al carrito si no existe
    await firestore.collection('Carts').add({
      'id_product': widget.productCode,
      'id_user': currentUser.uid,
      'fechaAgregado': FieldValue.serverTimestamp(),
    });

    setState(() {
      isAddingToCart = false;
    });

    _showCustomSnackbar('¡Producto agregado al carrito!', Colors.green);
  } catch (e) {
    setState(() {
      isAddingToCart = false;
    });

    _showCustomSnackbar('Error al agregar al carrito', Colors.red);
    print('Error adding to cart: $e');
  }
}

  void _showCustomSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.red
                  ? Icons.error
                  : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';

    if (price is double) {
      // Si es decimal, mostrar 2 decimales
      if (price % 1 != 0) {
        return price.toStringAsFixed(2);
      }
      // Si es entero, mostrar sin decimales
      return price.toStringAsFixed(0);
    }

    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Contenedor blanco para el header
          Container(
            color: Colors.white,
            child: SafeArea(
              child: Container(
                height: 60,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Botón de regresar
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Título centrado
                    Expanded(
                      child: Text(
                        'Descripción',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Botón de refrescar
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.black, size: 24),
                      onPressed: _loadProductData,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: isLoading
                      ? _buildLoadingState()
                      : errorMessage != null
                      ? _buildErrorState()
                      : productData == null
                      ? _buildEmptyState()
                      : _buildProductContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          !isLoading && errorMessage == null && productData != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    final String imageUrl = productData?['imagen'] ?? '';

    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[100]!, Colors.white],
            ),
          ),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                )
              : _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.image_outlined,
              color: Colors.grey[400],
              size: 48,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Imagen no disponible',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
          SizedBox(height: 24),
          Text(
            'Cargando producto...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          ),
          SizedBox(height: 24),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProductData,
            icon: Icon(Icons.refresh),
            label: Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Producto no encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent() {
    final bool isActive = productData!['activo'] ?? false;
    final double price = (productData!['precio'] ?? 0).toDouble();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado y nombre
          _buildProductHeader(isActive),

          // Sección de precio destacada
          _buildPriceSection(price),

          // Detalles del producto
          _buildDetailsSection(),

          SizedBox(height: 100), // Espacio para el botón flotante
        ],
      ),
    );
  }

  Widget _buildProductHeader(bool isActive) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado del producto
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? Colors.green[300]! : Colors.red[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green[700] : Colors.red[700],
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  isActive ? 'Disponible' : 'No disponible',
                  style: TextStyle(
                    color: isActive ? Colors.green[700] : Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Nombre del producto
          Text(
            productData!['nombre'] ?? 'Sin nombre',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),

          SizedBox(height: 8),

          // Categoría con icono
          Row(
            children: [
              Icon(Icons.category_outlined, size: 16, color: Colors.grey[500]),
              SizedBox(width: 6),
              Text(
                productData!['categoria'] ?? 'Sin categoría',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double price) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Colors.grey[800]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precio',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Incluye impuestos',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'L.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              SizedBox(width: 4),
              Text(
                _formatPrice(price),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey[700]),
              SizedBox(width: 8),
              Text(
                'Detalles del Producto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Talla si existe
          if (productData!['talla'] != null &&
              productData!['talla'].toString().isNotEmpty)
            _buildDetailRow(
              Icons.straighten,
              'Talla',
              productData!['talla'].toString(),
            ),

          // Código del producto
          _buildDetailRow(Icons.qr_code, 'Código', widget.productCode),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool isActive = productData?['activo'] ?? false;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentUser == null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Inicia sesión para agregar productos al carrito',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (!isActive || isAddingToCart) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.black : Colors.grey[400],
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isActive ? 4 : 0,
                  shadowColor: Colors.black.withOpacity(0.3),
                ),
                child: isAddingToCart
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Agregando...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? Icons.add_shopping_cart : Icons.block,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isActive
                                ? 'Agregar al Carrito'
                                : 'Producto No Disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
