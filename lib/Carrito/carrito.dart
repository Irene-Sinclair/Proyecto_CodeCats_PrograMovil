import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proyecto_codecats/botton_navigator.dart'; 
import 'package:proyecto_codecats/Catalogo/catalogo.dart';
import 'package:proyecto_codecats/user_profile/User.dart';
import 'package:proyecto_codecats/Pantallas_Admin/panel_adm.dart';

// Modelo para los artículos del carrito
class CartItem {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagen;
  final double precio;
  final String talla;
  final int cantidad;
  final String categoria;
  final bool activo;

  CartItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagen,
    required this.precio,
    required this.talla,
    required this.cantidad,
    required this.categoria,
    required this.activo,
  });

  factory CartItem.fromFirestore(Map<String, dynamic> productData, {int cantidad = 1}) {
    return CartItem(
      id: productData['codigo'] ?? '',
      nombre: productData['nombre'] ?? 'Sin nombre',
      descripcion: productData['categoria'] ?? 'Sin descripción',
      imagen: productData['imagen'] ?? '',
      precio: (productData['precio'] ?? 0).toDouble(),
      talla: productData['talla'] ?? '',
      cantidad: cantidad,
      categoria: productData['categoria'] ?? '',
      activo: productData['activo'] ?? false,
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const PaymentScreen({Key? key, this.cartItems = const []}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'Transferencia';
  String shippingAddress = '';
  String userCity = '';
  String userName = '';
  String userPhone = '';
  
  // UID del usuario autenticado
  String? currentUserId;
  
  List<CartItem> firebaseCartItems = [];
  bool isLoading = true;
  String? errorMessage;
  int _currentIndex = 1; // Índice para Carrito

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      await _loadUserData();
      await _loadCartFromFirebase();
    } else {
      setState(() {
        errorMessage = 'Usuario no autenticado';
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    if (currentUserId == null) return;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Buscar los datos del cliente por UID
      DocumentSnapshot userDoc = await firestore
          .collection('Clients')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          shippingAddress = userData['direccion'] ?? '';
          userCity = userData['ciudad'] ?? '';
          userName = userData['nombre'] ?? 'Cliente';
          userPhone = userData['telefono'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadCartFromFirebase() async {
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // 1. Obtener los items del carrito para este usuario
      QuerySnapshot cartSnapshot = await firestore
          .collection('Carts')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      List<CartItem> loadedItems = [];

      // 2. Para cada item del carrito, obtener los datos del producto
      for (QueryDocumentSnapshot cartDoc in cartSnapshot.docs) {
        Map<String, dynamic> cartData = cartDoc.data() as Map<String, dynamic>;
        String productId = cartData['id_product'];
        
        // Contar cuántas veces aparece este producto (para la cantidad)
        int cantidad = cartSnapshot.docs
            .where((doc) => (doc.data() as Map<String, dynamic>)['id_product'] == productId)
            .length;

        // 3. Obtener los datos del producto desde la colección Products
        QuerySnapshot productSnapshot = await firestore
            .collection('Products')
            .where('codigo', isEqualTo: productId)
            .limit(1)
            .get();

        if (productSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> productData = productSnapshot.docs.first.data() as Map<String, dynamic>;
          
          // Solo agregar productos activos
          if (productData['activo'] == true) {
            CartItem item = CartItem.fromFirestore(productData, cantidad: cantidad);
            
            // Evitar duplicados
            if (!loadedItems.any((existingItem) => existingItem.id == item.id)) {
              loadedItems.add(item);
            }
          }
        }
      }

      setState(() {
        firebaseCartItems = loadedItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar el carrito: $e';
        isLoading = false;
      });
      print('Error loading cart: $e');
    }
  }

  Future<void> _removeItemFromCart(CartItem item) async {
    if (currentUserId == null) return;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Buscar y eliminar el item del carrito
      QuerySnapshot cartSnapshot = await firestore
          .collection('Carts')
          .where('id_user', isEqualTo: currentUserId)
          .where('id_product', isEqualTo: item.id)
          .limit(1)
          .get();

      if (cartSnapshot.docs.isNotEmpty) {
        await cartSnapshot.docs.first.reference.delete();
        
        // Recargar el carrito
        await _loadCartFromFirebase();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Artículo eliminado del carrito')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el artículo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar datos de Firebase si están disponibles, sino usar los pasados como parámetro
    final items = firebaseCartItems.isNotEmpty ? firebaseCartItems : widget.cartItems;
    final total = items.fold<double>(0.0, (sum, item) => sum + (item.precio * item.cantidad));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCartFromFirebase,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Tu carrito está vacío',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Sección de envío
                                _buildShippingSection(),
                                
                                Divider(height: 1, color: Colors.grey[300]),
                                
                                // Sección de pago
                                _buildPaymentSection(),
                                
                                Divider(height: 1, color: Colors.grey[300]),
                                
                                // Lista de artículos
                                _buildItemsSection(items),
                                
                                // Total
                                _buildTotalSection(total),
                              ],
                            ),
                          ),
                        ),
                        
                        // Botón de realizar pedido
                        _buildOrderButton(),
                      ],
                    ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
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
              // Ya estamos en carrito
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;

            case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminSettingsScreen()),
                  );
                  break;
          }
        },
        accessType: 'admin',
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Tu carrito',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      
    );
  }

  Widget _buildShippingSection() {
    // Mostrar dirección completa si existe
    String displayAddress = '';
    if (shippingAddress.isNotEmpty && userCity.isNotEmpty) {
      displayAddress = '$shippingAddress, $userCity';
    } else if (shippingAddress.isNotEmpty) {
      displayAddress = shippingAddress;
    } else {
      displayAddress = 'Añadir dirección de envío';
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIRECCION DE ENVÍO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              _showAddressDialog();
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayAddress,
                    style: TextStyle(
                      fontSize: 16,
                      color: displayAddress == 'Añadir dirección de envío' 
                          ? Colors.grey[600] 
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAGO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              _showPaymentMethodDialog();
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedPaymentMethod,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<CartItem> items) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de artículos
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ARTÍCULOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'DESCRIPCIÓN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PRECIO',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de artículos
          ...items.map((item) => _buildCartItem(item)),
        ],
      ),
    );
  }

 Widget _buildCartItem(CartItem item) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen del producto
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imagen,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Descripción
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoria,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  item.nombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (item.talla.isNotEmpty)
                  Text(
                    'Talla ${item.talla}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  'Código: ${item.id}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Precio y botón eliminar
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(item.precio * item.cantidad).toStringAsFixed(2)} L',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  _showDeleteItemDialog(item);
                },
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTotalSection(double total) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} L',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: firebaseCartItems.isEmpty ? null : () {
            _showConfirmationDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: firebaseCartItems.isEmpty ? Colors.grey : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            'Realizar pedido',
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

  void _showAddressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newAddress = shippingAddress;
        String newCity = userCity;
        return AlertDialog(
          title: Text('Dirección de envío'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => newAddress = value,
                decoration: InputDecoration(
                  hintText: 'Dirección',
                  border: OutlineInputBorder(),
                  labelText: 'Dirección',
                ),
                controller: TextEditingController(text: shippingAddress),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              TextField(
                onChanged: (value) => newCity = value,
                decoration: InputDecoration(
                  hintText: 'Ciudad',
                  border: OutlineInputBorder(),
                  labelText: 'Ciudad',
                ),
                controller: TextEditingController(text: userCity),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (newAddress.isNotEmpty && newCity.isNotEmpty && currentUserId != null) {
                  try {
                    // Actualizar en Firebase
                    await FirebaseFirestore.instance
                        .collection('Clients')
                        .doc(currentUserId)
                        .update({
                      'direccion': newAddress,
                      'ciudad': newCity,
                    });

                    setState(() {
                      shippingAddress = newAddress;
                      userCity = newCity;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dirección actualizada correctamente')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar la dirección: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                Navigator.pop(context);
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Método de pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Transferencia'),
                leading: Radio<String>(
                  value: 'Transferencia',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Contra Entrega'),
                leading: Radio<String>(
                  value: 'Contra Entrega',
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteItemDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar artículo'),
          content: Text('¿Estás seguro de que deseas eliminar "${item.nombre}" del carrito?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeItemFromCart(item);
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddressRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dirección requerida'),
          content: Text('No tienes una dirección agregada. ¿Deseas agregar una?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  // Método para mostrar la pantalla de confirmación
  void _showConfirmationDialog() {
    final total = firebaseCartItems.fold<double>(0.0, (sum, item) => sum + (item.precio * item.cantidad));
    String displayAddress = userCity.isNotEmpty ? '$shippingAddress, $userCity' : shippingAddress;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Pedido'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¿Estás seguro de realizar este pedido?'),
                SizedBox(height: 16),
                Text('Resumen del pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Artículos: ${firebaseCartItems.length}'),
                Text('Total: ${total.toStringAsFixed(2)} L'),
                Text('Método de pago: $selectedPaymentMethod'),
                Text('Dirección de envío: $displayAddress'),
                SizedBox(height: 16),
                Text('⚠️ Al confirmar, WhatsApp se abrirá automáticamente. Debes enviar el mensaje para finalizar tu compra.',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processOrder();
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Método para procesar el pedido
  Future<void> _processOrder() async {
    if (shippingAddress.isEmpty) {
      _showAddressRequiredDialog();
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final total = firebaseCartItems.fold<double>(0.0, (sum, item) => sum + (item.precio * item.cantidad));
      
      // 1. Crear el pedido en la colección Orders
      final orderData = {
        'user_id': currentUserId,
        'user_name': userName,
        'user_phone': userPhone,
        'items': firebaseCartItems.map((item) => {
          'id': item.id,
          'nombre': item.nombre,
          'precio': item.precio,
          'cantidad': item.cantidad,
          'talla': item.talla,
        }).toList(),
        'total': total,
        'payment_method': selectedPaymentMethod,
        'shipping_address': shippingAddress,
        'city': userCity,
        'status': 'pendiente',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Guardar el pedido en Firestore
      final orderRef = await firestore.collection('Orders').add(orderData);
      final orderId = orderRef.id;

      // 2. Desactivar los productos vendidos
      final batch = firestore.batch();
      for (final item in firebaseCartItems) {
        // Buscar el documento del producto por su código
        final productQuery = await firestore
            .collection('Products')
            .where('codigo', isEqualTo: item.id)
            .limit(1)
            .get();

        if (productQuery.docs.isNotEmpty) {
          final productDoc = productQuery.docs.first;
          batch.update(productDoc.reference, {'activo': false});
        }
      }

      // 3. ELIMINAR TODOS los productos del carrito de este usuario
      final cartItemsQuery = await firestore
          .collection('Carts')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      for (final cartDoc in cartItemsQuery.docs) {
        batch.delete(cartDoc.reference);
      }

      // Ejecutar todas las operaciones en lote
      await batch.commit();

      // 4. Enviar mensaje por WhatsApp
      await _sendWhatsAppMessage(orderId, total);

      // 5. Mostrar confirmación
      _showOrderSuccessDialog(orderId, total);

      // 6. Actualizar el estado local
      setState(() {
        firebaseCartItems.clear();
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para enviar mensaje por WhatsApp
  Future<void> _sendWhatsAppMessage(String orderId, double total) async {
    try {
      // Construir el mensaje con los detalles del pedido
      String message = '🚀 *NUEVO PEDIDO* - $orderId\n\n';
      message += '👤 *Cliente:* $userName\n\n';
      message += '🛒 *Artículos:*\n';
      
      for (final item in firebaseCartItems) {
        message += '• ${item.nombre} (Talla: ${item.talla}) - L${item.precio.toStringAsFixed(2)}\n';
      }
      
      message += '\n💰 *Total:* L${total.toStringAsFixed(2)}\n';
      message += '💳 *Método de pago:* $selectedPaymentMethod\n';
      message += '📦 *Dirección:* $shippingAddress, $userCity\n\n';
      

      // Codificar el mensaje para URL
      final encodedMessage = Uri.encodeComponent(message);
      
      // Número de WhatsApp
      final phoneNumber = '50432400069';
      
      // URLs para intentar
      final urlsToTry = [
        Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encodedMessage'),
        Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage'),
        Uri.parse('https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage'),
      ];

      bool whatsAppOpened = false;
      
      for (final url in urlsToTry) {
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
            whatsAppOpened = true;
            break;
          }
        } catch (e) {
          print('Error con URL $url: $e');
          continue;
        }
      }

      if (!whatsAppOpened) {
        // Mostrar aviso de que WhatsApp no está instalado
        _showWhatsAppNotInstalledDialog(message);
      }
      
    } catch (e) {
      print('Error al enviar mensaje por WhatsApp: $e');
      _showWhatsAppNotInstalledDialog(
        'Error al preparar mensaje. Pedido: $orderId - Cliente: $userName - Total: L${total.toStringAsFixed(2)}'
      );
    }
  }

  // Mostrar diálogo cuando WhatsApp no está instalado
  void _showWhatsAppNotInstalledDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('WhatsApp no encontrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No se encontró la aplicación de WhatsApp en tu dispositivo.'),
              SizedBox(height: 16),
              Text('Por favor, envía manualmente este mensaje al número: +504 3240-0069'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                ),
                child: SelectableText(
                  message,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // Método para mostrar diálogo de éxito
  void _showOrderSuccessDialog(String orderId, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('✅ Pedido Realizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu pedido #$orderId ha sido realizado exitosamente.'),
              SizedBox(height: 16),
              Text('💰 Total: L${total.toStringAsFixed(2)}'),
              Text('💳 Método de pago: $selectedPaymentMethod'),
              SizedBox(height: 16),
              
              Text(
                '📱 Se ha abierto WhatsApp con los detalles de tu pedido.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '⚠️ Por favor recuerda darle ENVIAR al mensaje para confirmar tu pedido.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Volver a la pantalla anterior
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}