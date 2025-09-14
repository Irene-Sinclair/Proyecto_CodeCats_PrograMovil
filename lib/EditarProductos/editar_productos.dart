import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarProductoScreen extends StatefulWidget {
  final String productoId;

  const EditarProductoScreen({
    Key? key,
    required this.productoId,
  }) : super(key: key);

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _tallaController = TextEditingController();
  
  String? _categoriaSeleccionada;
  
  final List<String> _categorias = [
    'Ropa',
    'Zapatos',
    'Accesorios',
    'Pantalones',
    'Camisetas',
    'Vestidos',
    'Chaquetas'
  ];

  bool _isLoading = true;
  bool _guardando = false;
  Map<String, dynamic>? _productoData;

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    try {
      final doc = await _firestore.collection('Products').doc(widget.productoId).get();
      
      if (doc.exists) {
        setState(() {
          _productoData = doc.data()!;
          _nombreController.text = _productoData!['nombre'] ?? '';
          _precioController.text = _productoData!['precio']?.toString() ?? '';
          _tallaController.text = _productoData!['talla'] ?? '';
          _categoriaSeleccionada = _productoData!['categoria'];
          _isLoading = false;
        });
      } else {
        _mostrarError('Producto no encontrado');
      }
    } catch (error) {
      _mostrarError('Error al cargar producto: $error');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _guardando ? null : () => _cancelarEdicion(),
        ),
        title: const Text(
          'Editar producto',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de imagen
                    _buildImageField(),
                    const SizedBox(height: 24),
                    
                    // Campo nombre del producto
                    _buildTextField(
                      label: 'Nombre del Producto',
                      icon: Icons.shopping_bag_outlined,
                      controller: _nombreController,
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo talla (ahora es texto)
                    _buildTextField(
                      label: 'Talla',
                      icon: Icons.straighten,
                      controller: _tallaController,
                      hintText: 'Ej: M, L, 38, 40, etc.',
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo categoría
                    _buildDropdownField(
                      label: 'Categoría',
                      icon: Icons.category_outlined,
                      value: _categoriaSeleccionada,
                      items: _categorias,
                      hint: 'Seleccionar categoría',
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo precio
                    _buildTextField(
                      label: 'Precio',
                      icon: Icons.attach_money,
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            
            // Botones
            Column(
              children: [
                // Botón Guardar Cambios
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Botón Cancelar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: _guardando ? null : _cancelarEdicion,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Imagen del Producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: InkWell(
            onTap: _seleccionarImagen,
            borderRadius: BorderRadius.circular(8),
            child: _productoData?['imagen'] != null
                ? Image.network(
                    _productoData!['imagen'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  )
                : _buildPlaceholderImage(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 32,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Tocar para cambiar imagen',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[600]),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _seleccionarImagen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: const Text('Funcionalidad de selección de imagen por implementar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCambios() async {
    // Validar campos
    if (_nombreController.text.isEmpty ||
        _precioController.text.isEmpty ||
        _tallaController.text.isEmpty ||
        _categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar precio
    double? precio;
    try {
      precio = double.parse(_precioController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un precio válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      // Actualizar el producto en Firebase
      await _firestore.collection('Products').doc(widget.productoId).update({
        'nombre': _nombreController.text.trim(),
        'precio': precio,
        'talla': _tallaController.text.trim(),
        'categoria': _categoriaSeleccionada,
        // Mantener la imagen existente si no se cambia
        'imagen': _productoData?['imagen'] ?? 'https://via.placeholder.com/150/8B4513/FFFFFF?text=Producto',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto "${_nombreController.text}" actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _guardando = false;
      });
    }
  }

  void _cancelarEdicion() {
    // Mostrar diálogo de confirmación si hay cambios
    if (_hayCambios()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar cambios?'),
          content: const Text('Los cambios no guardados se perderán.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuar editando'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Cerrar pantalla
              },
              child: const Text(
                'Descartar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _hayCambios() {
    if (_productoData == null) return false;
    
    return _nombreController.text != _productoData!['nombre'] ||
           _tallaController.text != _productoData!['talla'] ||
           _categoriaSeleccionada != _productoData!['categoria'] ||
           _precioController.text != _productoData!['precio']?.toString();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _tallaController.dispose();
    super.dispose();
  }
}