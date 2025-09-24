import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InformacionEmpresaScreen extends StatefulWidget {
  const InformacionEmpresaScreen({Key? key}) : super(key: key);

  @override
  _InformacionEmpresaScreenState createState() =>
      _InformacionEmpresaScreenState();
}

class _InformacionEmpresaScreenState extends State<InformacionEmpresaScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos editables
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _nombreBancoController = TextEditingController();
  final TextEditingController _numeroCuentaController = TextEditingController();


  String telefonoPedidos = '';
  List<Map<String, dynamic>> cuentasBanco = [];
  bool isLoading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _cargarInformacionEmpresa();
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _nombreBancoController.dispose();
    _numeroCuentaController.dispose();
    super.dispose();
  }

  Future<void> _cargarInformacionEmpresa() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('information')
          .doc('empresa_info')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          telefonoPedidos = data['telefono_pedidos'] ?? '';
          cuentasBanco = List<Map<String, dynamic>>.from(
              data['cuentas_banco'] ?? []);
          _telefonoController.text = telefonoPedidos;
          isLoading = false;
        });
      } else {
        // Crear documento inicial si no existe
        await _crearDocumentoInicial();
      }
    } catch (e) {
      print('Error al cargar información: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _crearDocumentoInicial() async {
    try {
      await _firestore.collection('information').doc('empresa_info').set({
        'telefono_pedidos': '',
        'cuentas_banco': [],
        'created_at': FieldValue.serverTimestamp(),
      });
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error al crear documento inicial: $e');
    }
  }

  Future<void> _guardarInformacion() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _firestore.collection('information').doc('empresa_info').update({
        'telefono_pedidos': _telefonoController.text.trim(),
        'cuentas_banco': cuentasBanco,
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        telefonoPedidos = _telefonoController.text.trim();
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Información actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoAgregarCuenta() {
    _nombreBancoController.clear();
    _numeroCuentaController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Agregar Cuenta Bancaria'),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreBancoController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Banco',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre del banco';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _numeroCuentaController,
                  decoration: InputDecoration(
                    labelText: 'Número de Cuenta',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el número de cuenta';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _agregarCuenta();
                Navigator.pop(context);
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _agregarCuenta() {
    if (_nombreBancoController.text.isNotEmpty &&
        _numeroCuentaController.text.isNotEmpty) {
      setState(() {
        cuentasBanco.add({
          'nombre_banco': _nombreBancoController.text.trim(),
          'numero_cuenta': _numeroCuentaController.text.trim(),
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      });
    }
  }

  void _eliminarCuenta(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar esta cuenta bancaria?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  cuentasBanco.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cuenta bancaria eliminada'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Sección del header de la empresa
              _buildCompanyHeader(),

              // Sección de información general
              _buildGeneralInfoSection(),

              // Sección de cuentas bancarias
              _buildBankAccountsSection(),

              // Botones de acción
              if (isEditing) _buildActionButtons(),
            ],
          ),
        ),
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
        'Información de la Empresa',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            isEditing ? Icons.close : Icons.edit,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              if (isEditing) {
                // Cancelar edición - restaurar valores originales
                _telefonoController.text = telefonoPedidos;
              }
              isEditing = !isEditing;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: DecorationImage(
              image: AssetImage('assets/img/logo.jpg'),
              fit: BoxFit.cover,
              ),
            ),
            ),

          SizedBox(height: 16),

          // Nombre de la empresa
          Text(
            'Americano Cruz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text(
                'Información General',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Teléfono para pedidos
          _buildEditableInfoItem(
            icon: Icons.phone_outlined,
            title: 'Teléfono para Pedidos',
            controller: _telefonoController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un número de teléfono';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección con botón agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Cuentas Bancarias',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              if (isEditing)
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: _mostrarDialogoAgregarCuenta,
                ),
            ],
          ),

          SizedBox(height: 16),

          // Lista de cuentas bancarias
          if (cuentasBanco.isEmpty)
            Center(
              child: Text(
                'No hay cuentas bancarias registradas',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            )
          else
            ...cuentasBanco.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> cuenta = entry.value;
              return _buildBankAccountItem(cuenta, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEditableInfoItem({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              isEditing
                  ? TextFormField(
                      controller: controller,
                      validator: validator,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    )
                  : Text(
                      controller.text.isEmpty 
                          ? 'Sin información' 
                          : controller.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: controller.text.isEmpty 
                            ? Colors.grey[500] 
                            : Colors.grey[600],
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccountItem(Map<String, dynamic> cuenta, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cuenta['nombre_banco'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (isEditing)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _eliminarCuenta(index),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Número: ${cuenta['numero_cuenta'] ?? ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isEditing = false;
                  _telefonoController.text = telefonoPedidos;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Cancelar'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _guardarInformacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}