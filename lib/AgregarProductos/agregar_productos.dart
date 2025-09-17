import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({Key? key}) : super(key: key);

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _tallaController = TextEditingController();

  String? _categoriaSeleccionada;
  File? _imagenSeleccionada;
  bool _isLoading = false;

  final List<String> _categorias = [
    'Camisetas',
    'Pantalones',
    'Zapatos',
    'Accesorios',
    'Vestidos',
    'Chaquetas'
  ];

  // ✅ Seleccionar imagen (Galería / Cámara)
  Future<void> _seleccionarImagen() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Método para elegir imagen
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _imagenSeleccionada = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Subir imagen a Firebase Storage
  Future<String?> _subirImagen() async {
    if (_imagenSeleccionada == null) return null;

    try {
      final String nombreArchivo =
          'producto_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageRef = _storage
          .ref()
          .child('productos')
          .child(_categoriaSeleccionada?.toLowerCase() ?? 'otros')
          .child(nombreArchivo);

      final UploadTask uploadTask = storageRef.putFile(
        _imagenSeleccionada!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  // ✅ Agregar producto a Firestore
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

    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una imagen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? imagenUrl = await _subirImagen();
      if (imagenUrl == null) throw Exception('Error al subir la imagen');

      final precio = double.tryParse(_precioController.text);
      if (precio == null) {
        throw Exception('El precio debe ser un número válido');
      }

      final productoData = {
        'nombre': _nombreController.text.trim(),
        'precio': precio,
        'talla': _tallaController.text.trim(),
        'categoria': _categoriaSeleccionada,
        'imagen': imagenUrl,
        'codigo': _generarCodigoUnico(),
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('Products').add(productoData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto agregado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error al agregar producto: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar producto: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _generarCodigoUnico() {
    final now = DateTime.now();
    return 'PROD-${now.millisecondsSinceEpoch}';
  }

  // ✅ Widgets auxiliares para campos
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          onChanged: onChanged,
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
        ),
      ),
    );
  }

  // ✅ Widget para imagen
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
        if (_imagenSeleccionada != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imagenSeleccionada!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _imagenSeleccionada = null;
                      });
                    },
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _seleccionarImagen,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 32, color: Colors.grey[400]),
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
                      onChanged: (value) {
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

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _tallaController.dispose();
    super.dispose();
  }
}
