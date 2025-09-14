import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({Key? key}) : super(key: key);

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _tallaController = TextEditingController();
  
  String? _categoriaSeleccionada;
  
  final List<String> _categorias = [
    'Camisetas',
    'Pantalones', 
    'Zapatos',
    'Accesorios',
    'Vestidos',
    'Chaquetas'
  ];

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agregar producto',
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
                    _buildImageField(),
                    const SizedBox(height: 24),
                    
                    _buildTextField(
                      label: 'Nombre del Producto',
                      icon: Icons.shopping_bag_outlined,
                      controller: _nombreController,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      label: 'Talla',
                      icon: Icons.straighten,
                      controller: _tallaController,
                      hintText: 'Ej: M, L, 38, 40, etc.',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildDropdownField(
                      label: 'Categoría',
                      icon: Icons.category_outlined,
                      value: _categoriaSeleccionada,
                      items: _categorias,
                      hint: 'Seleccionar categoría',
                      onChanged: (String? value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
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
            
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _agregarProducto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Agregar Producto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
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
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: InkWell(
            onTap: _seleccionarImagen,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tocar para agregar imagen',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
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

  Future<void> _agregarProducto() async {
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

  setState(() {
    _isLoading = true;
  });

  try {
    print('Intentando agregar producto...');
    
    // Convertir precio a número
    final precio = double.tryParse(_precioController.text);
    if (precio == null) {
      throw Exception('El precio debe ser un número válido');
    }

    // Datos del producto
    final productoData = {
      'nombre': _nombreController.text.trim(),
      'precio': precio,
      'talla': _tallaController.text.trim(),
      'categoria': _categoriaSeleccionada,
      'imagen': 'https://via.placeholder.com/150/8B4513/FFFFFF?text=Producto',
      'codigo': _generarCodigoUnico(),
      'activo': true,
    };

    print('Datos del producto: $productoData');
    
    // Crear el producto en Firebase
    final docRef = await _firestore.collection('Products').add(productoData);
    print('Producto agregado con ID: ${docRef.id}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto agregado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
    
  } catch (error) {
    print('Error al agregar producto: $error');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al agregar producto: ${error.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
    
  } finally {
    print('Finalizando proceso de agregar producto');
    setState(() {
      _isLoading = false;
    });
  }
}

  String _generarCodigoUnico() {
    // Generar un código único basado en timestamp
    final now = DateTime.now();
    return 'PROD-${now.millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _tallaController.dispose();
    super.dispose();
  }
}