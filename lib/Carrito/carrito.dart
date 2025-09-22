import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proyecto_codecats/botton_navigator.dart'; 
import 'package:proyecto_codecats/Catalogo/catalogo.dart';
import 'package:proyecto_codecats/user_profile/User.dart';
import 'package:proyecto_codecats/Pantallas_Admin/panel_adm.dart';

// ===== Modelo para los artículos del carrito =====
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
      id: (productData['codigo'] ?? '').toString(),
      nombre: (productData['nombre'] ?? 'Sin nombre').toString(),
      descripcion: (productData['categoria'] ?? 'Sin descripción').toString(),
      imagen: (productData['imagen'] ?? '').toString(),
      precio: (productData['precio'] ?? 0).toDouble(),
      talla: (productData['talla'] ?? '').toString(),
      cantidad: cantidad,
      categoria: (productData['categoria'] ?? '').toString(),
      activo: productData['activo'] ?? false,
    );
  }
}

// ===== Pantalla de pago =====
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

  // Puedes parametrizar estos dos si luego agregas opciones dinámicas:
  String shippingMethod = 'Entrega';
  String shippingOption = 'Envios Tegucigalpa';

  // Costo de envío (puedes hacerlo dinámico más adelante)
  final double deliveryFee = 80.00;

  // UID del usuario autenticado
  String? currentUserId;

  List<CartItem> firebaseCartItems = [];
  bool isLoading = true;
  String? errorMessage;
  int _currentIndex = 1; // Índice para Carrito

  // ===== Helpers de validación obligatoria =====
  bool get _hasRequiredContactInfo =>
      userPhone.trim().isNotEmpty &&
      userCity.trim().isNotEmpty &&
      shippingAddress.trim().isNotEmpty;

  List<String> _getMissingFields() {
    final missing = <String>[];
    if (userPhone.trim().isEmpty) missing.add('Celular');
    if (userCity.trim().isEmpty) missing.add('Ciudad');
    if (shippingAddress.trim().isEmpty) missing.add('Dirección');
    return missing;
  }

  bool _validateContactAndAddress() {
    final missing = _getMissingFields();
    if (missing.isEmpty) return true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Información requerida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Para continuar con tu pedido, completa los siguientes campos:'),
              const SizedBox(height: 8),
              ...missing.map((m) => Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              )),
              const SizedBox(height: 12),
              const Text(
                'Puedes completar celular, ciudad y dirección desde el cuadro de “Dirección de envío”.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddressDialog(); // 👉 ahora incluye Celular también
              },
              child: const Text('Completar ahora'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
    return false;
  }
  // ===== Fin helpers =====

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
          shippingAddress = (userData['direccion'] ?? '').toString();
          userCity = (userData['ciudad'] ?? '').toString();
          userName = (userData['nombre'] ?? 'Cliente').toString();
          userPhone = (userData['telefono'] ?? '').toString();
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
        String productId = (cartData['id_product'] ?? '').toString();

        // Contar cuántas veces aparece este producto (para la cantidad)
        int cantidad = cartSnapshot.docs
            .where((doc) => ((doc.data() as Map<String, dynamic>)['id_product'] ?? '').toString() == productId)
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
          const SnackBar(content: Text('Artículo eliminado del carrito')),
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
    final subtotal = items.fold<double>(0.0, (sum, item) => sum + (item.precio * item.cantidad));
    final totalConEnvio = subtotal + (items.isNotEmpty ? deliveryFee : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCartFromFirebase,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
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

                                // Aviso si falta info requerida
                                if (!_hasRequiredContactInfo)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Para realizar el pedido debes tener registrado: Celular, Ciudad y Dirección.',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                Divider(height: 24, color: Colors.grey[300]),

                                // Sección de pago
                                _buildPaymentSection(),

                                Divider(height: 24, color: Colors.grey[300]),

                                // Lista de artículos
                                _buildItemsSection(items),

                                // Total
                                _buildTotalSection(subtotal, totalConEnvio),
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
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DIRECCION DE ENVÍO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showAddressDialog,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAGO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showPaymentMethodDialog,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Transferencia / Contra Entrega / Otros',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de artículos
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: const [
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              padding: const EdgeInsets.only(left: 12),
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
                    style: const TextStyle(
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDeleteItemDialog(item),
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

  Widget _buildTotalSection(double subtotal, double totalConEnvio) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Subtotal',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              // valor a la derecha abajo
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Text(
                '${subtotal.toStringAsFixed(2)} L',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Entrega',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              Text(
                '${(firebaseCartItems.isNotEmpty ? deliveryFee : 0).toStringAsFixed(2)} L',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              // valor a la derecha abajo
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Text(
                '${totalConEnvio.toStringAsFixed(2)} L',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderButton() {
    final canTap = firebaseCartItems.isNotEmpty; // habilitación por carrito
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: !canTap
              ? null
              : () {
                  // Validación obligatoria ANTES de abrir confirmación
                  if (!_validateContactAndAddress()) return;
                  _showConfirmationDialog();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: !canTap ? Colors.grey : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text(
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

  // ===== DIÁLOGO ahora con CELULAR + DIRECCIÓN + CIUDAD =====
  void _showAddressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newAddress = shippingAddress;
        String newCity = userCity;
        String newPhone = userPhone;
        final phoneCtrl = TextEditingController(text: userPhone);
        final addrCtrl = TextEditingController(text: shippingAddress);
        final cityCtrl = TextEditingController(text: userCity);

        return AlertDialog(
          title: const Text('Dirección de envío'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneCtrl,
                  onChanged: (v) => newPhone = v,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Celular',
                    border: OutlineInputBorder(),
                    labelText: 'Celular',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addrCtrl,
                  onChanged: (v) => newAddress = v,
                  decoration: const InputDecoration(
                    hintText: 'Dirección',
                    border: OutlineInputBorder(),
                    labelText: 'Dirección',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityCtrl,
                  onChanged: (v) => newCity = v,
                  decoration: const InputDecoration(
                    hintText: 'Ciudad',
                    border: OutlineInputBorder(),
                    labelText: 'Ciudad',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (currentUserId != null &&
                    newPhone.trim().isNotEmpty &&
                    newAddress.trim().isNotEmpty &&
                    newCity.trim().isNotEmpty) {
                  try {
                    // Normalizar solo dígitos para guardar
                    final digits = newPhone.replaceAll(RegExp(r'[^0-9]'), '');

                    // Actualizar en Firebase
                    await FirebaseFirestore.instance
                        .collection('Clients')
                        .doc(currentUserId)
                        .update({
                      'telefono': digits,
                      'direccion': newAddress.trim(),
                      'ciudad': newCity.trim(),
                    });

                    setState(() {
                      userPhone = digits;
                      shippingAddress = newAddress.trim();
                      userCity = newCity.trim();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Información de envío actualizada')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar la información: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completa Celular, Dirección y Ciudad'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
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
          title: const Text('Método de pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Transferencia'),
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
                title: const Text('Contra Entrega'),
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
              ListTile(
                title: const Text('Otros'),
                leading: Radio<String>(
                  value: 'Otros',
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
              child: const Text('Cerrar'),
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
          title: const Text('Eliminar artículo'),
          content: Text('¿Estás seguro de que deseas eliminar "${item.nombre}" del carrito?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeItemFromCart(item);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
          title: const Text('Información requerida'),
          content: const Text('Debes registrar tu celular, ciudad y dirección para continuar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddressDialog();
              },
              child: const Text('Completar ahora'),
            ),
          ],
        );
      },
    );
  }

  // Pantalla de confirmación
  void _showConfirmationDialog() {
    if (!_validateContactAndAddress()) return; // seguridad
    final subtotal = firebaseCartItems.fold<double>(0.0, (sum, item) => sum + (item.precio * item.cantidad));
    final total = subtotal + deliveryFee;
    String displayAddress = userCity.isNotEmpty ? '$shippingAddress, $userCity' : shippingAddress;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Pedido'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿Estás seguro de realizar este pedido?'),
                const SizedBox(height: 16),
                const Text('Resumen del pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Artículos: ${firebaseCartItems.length}'),
                Text('Subtotal: ${subtotal.toStringAsFixed(2)} L'),
                Text('Envío: ${deliveryFee.toStringAsFixed(2)} L'),
                Text('Total: ${total.toStringAsFixed(2)} L'),
                Text('Método de pago: $selectedPaymentMethod'),
                Text('Dirección de envío: $displayAddress'),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ Al confirmar, WhatsApp se abrirá automáticamente. Debes enviar el mensaje para finalizar tu compra.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processOrder();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Procesamiento del pedido
  Future<void> _processOrder() async {
    if (!_hasRequiredContactInfo) {
      _validateContactAndAddress();
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final subtotal = firebaseCartItems.fold<double>(0.0, (sum, item) => sum + (item.precio * item.cantidad));
      final total = subtotal + deliveryFee;

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
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'payment_method': selectedPaymentMethod,
        'shipping_address': shippingAddress,
        'city': userCity,
        'shipping_method': shippingMethod,
        'shipping_option': shippingOption,
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

      // 3. Eliminar TODOS los productos del carrito de este usuario
      final cartItemsQuery = await firestore
          .collection('Carts')
          .where('id_user', isEqualTo: currentUserId)
          .get();

      for (final cartDoc in cartItemsQuery.docs) {
        batch.delete(cartDoc.reference);
      }

      // Ejecutar todas las operaciones en lote
      await batch.commit();

      // 4. Enviar mensaje por WhatsApp con el formato solicitado
      await _sendWhatsAppMessage(orderId, subtotal, deliveryFee, subtotal + deliveryFee);

      // 5. Mostrar confirmación
      _showOrderSuccessDialog(orderId, subtotal + deliveryFee);

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

  // ===== WhatsApp con formato solicitado (sin enlace de seguimiento) =====
  Future<void> _sendWhatsAppMessage(String orderId, double subtotal, double envio, double total) async {
    try {
      // Normalizar teléfono con +504 si hace falta (para impresión)
      String phonePrinted = userPhone;
      if (!phonePrinted.startsWith('+504')) {
        final onlyDigits = phonePrinted.replaceAll(RegExp(r'[^0-9]'), '');
        phonePrinted = '+504$onlyDigits';
      }

      // Construir el mensaje con los bloques exactos
      String message = "";
      message += "ID DEL PEDIDO #$orderId\n\n";
      message += "https://www.instagram.com/americanoscruz/\n\n"; // 👉 enlace solicitado
      message += "========================================\n";
      message += "➜ DETALLES DEL PEDIDO\n";

      for (final item in firebaseCartItems) {
        final codigo = (item.id.isEmpty) ? 'null' : item.id;
        message += "${item.cantidad}x ${item.nombre} (Cód: $codigo) - L ${item.precio.toStringAsFixed(2)}/unid\n";
      }

      message += "\n========================================\n";
      message += "➜ DATOS DEL CLIENTE\n";
      message += "Nombre: $userName\n";
      message += "Teléfono: $phonePrinted\n";
      message += "Dirección: $shippingAddress\n";

      message += "\n========================================\n";
      message += "➜ DETALLES DE ENVÍO\n";
      message += "Método: $shippingMethod\n";
      message += "Opción: $shippingOption \n";

      message += "\n========================================\n";
      message += "➜ VALORES Y MÉTODO DE PAGO\n";
      final cantidadArticulos = firebaseCartItems.fold<int>(0, (sum, it) => sum + it.cantidad);
      message += "$cantidadArticulos artículos: L ${subtotal.toStringAsFixed(2)}\n";
      message += "Entrega: L ${envio.toStringAsFixed(2)}\n";
      message += "Método de pago: $selectedPaymentMethod\n";
      message += "Total: L ${total.toStringAsFixed(2)}\n";

      message += "\n========================================\n";
      message += "➜ CUENTAS\n";
      message += "Banco BAC: 751407741\n";
      message += "Banco Ficohsa: 200020534167\n";

      message += "\n========================================\n";
      message += "Generado por el catalogo de Americano Cruz"; // 👉 pie solicitado

      // Codificar mensaje para URL
      final encodedMessage = Uri.encodeComponent(message);

      // Número destino de WhatsApp (tienda)
      final phoneNumber = '50432400069';

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
          title: const Text('WhatsApp no encontrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No se encontró la aplicación de WhatsApp en tu dispositivo.'),
              const SizedBox(height: 16),
              const Text('Por favor, envía manualmente este mensaje al número: +504 3240-0069'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                ),
                child: SelectableText(
                  message,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo de éxito
  void _showOrderSuccessDialog(String orderId, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('✅ Pedido Realizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu pedido #$orderId ha sido realizado exitosamente.'),
              const SizedBox(height: 16),
              Text('💰 Total: L${total.toStringAsFixed(2)}'),
              Text('💳 Método de pago: $selectedPaymentMethod'),
              const SizedBox(height: 16),
              const Text(
                '📱 Se ha abierto WhatsApp con los detalles de tu pedido.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
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
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
