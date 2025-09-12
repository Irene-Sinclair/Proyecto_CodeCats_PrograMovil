import 'package:flutter/material.dart';

// Producto
class Producto {
  final String id;
  String nombre;
  String talla;
  String categoria;
  double precio;
  String? imagenUrl;

  Producto({
    required this.id,
    required this.nombre,
    required this.talla,
    required this.categoria,
    required this.precio,
    this.imagenUrl,
  });
}

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
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  
  String? _tallaSeleccionada;
  String? _categoriaSeleccionada;
  Producto? _producto;
  
  final List<String> _tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _categorias = [
    'Ropa',
    'Zapatos',
    'Accesorios',
    'Pantalones',
    'Camisetas',
    'Vestidos',
    'Chaquetas'
  ];

  // Lista de productos simulada
  final List<Producto> _productosSimulados = [
    Producto(
      id: '1',
      nombre: 'Camiseta Básica',
      talla: 'M',
      categoria: 'Ropa',
      precio: 25.99,
    ),
    Producto(
      id: '2',
      nombre: 'Jeans Clásicos',
      talla: 'L',
      categoria: 'Pantalones',
      precio: 89.99,
    ),
    Producto(
      id: '3',
      nombre: 'Zapatillas Deportivas',
      talla: 'XL',
      categoria: 'Zapatos',
      precio: 129.99,
    ),
    Producto(
      id: '4',
      nombre: 'Vestido de Verano',
      talla: 'S',
      categoria: 'Vestidos',
      precio: 45.50,
    ),
    Producto(
      id: '5',
      nombre: 'Chaqueta de Cuero',
      talla: 'L',
      categoria: 'Chaquetas',
      precio: 199.99,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  void _cargarProducto() {
    // Buscar el producto por ID
    try {
      _producto = _productosSimulados.firstWhere(
        (producto) => producto.id == widget.productoId,
      );
      
      // Cargar los datos en los controladores
      _nombreController.text = _producto!.nombre;
      _precioController.text = _producto!.precio.toString();
      _tallaSeleccionada = _producto!.talla;
      _categoriaSeleccionada = _producto!.categoria;
      
      setState(() {});
    } catch (e) {
      // Si no se encuentra el producto, mostrar error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_producto == null) {
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
          onPressed: () => Navigator.pop(context),
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
                    
                    // Campo talla
                    _buildDropdownField(
                      label: 'Talla',
                      icon: Icons.straighten,
                      value: _tallaSeleccionada,
                      items: _tallas,
                      hint: 'Seleccionar talla',
                      onChanged: (value) {
                        setState(() {
                          _tallaSeleccionada = value;
                        });
                      },
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
                    onPressed: _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
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
                    onPressed: _cancelarEdicion,
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

  void _guardarCambios() {
    // Validar campos
    if (_nombreController.text.isEmpty ||
        _precioController.text.isEmpty ||
        _tallaSeleccionada == null ||
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

    // Actualizar el producto en la lista
    _producto!.nombre = _nombreController.text;
    _producto!.talla = _tallaSeleccionada!;
    _producto!.categoria = _categoriaSeleccionada!;
    _producto!.precio = precio;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Producto "${_producto!.nombre}" actualizado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );

    // Regresar a la pantalla anterior
    Navigator.pop(context, _producto);
  }

  void _cancelarEdicion() {
    // Mostrar diálogo de confirmación si hay cambios
    if (_hayaCambios()) {
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

  bool _hayaCambios() {
    if (_producto == null) return false;
    
    return _nombreController.text != _producto!.nombre ||
           _tallaSeleccionada != _producto!.talla ||
           _categoriaSeleccionada != _producto!.categoria ||
           _precioController.text != _producto!.precio.toString();
  }

 
  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }
}