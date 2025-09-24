import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class RegistrarsePage extends StatefulWidget {
  const RegistrarsePage({super.key});
  @override
  State<RegistrarsePage> createState() => _RegistrarsePageState();
}

class _RegistrarsePageState extends State<RegistrarsePage> {
  // Color de marca
  static const Color kBrand = Color(0xFF843772);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstCtrl = TextEditingController();
  final TextEditingController _lastCtrl  = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl  = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  // Referencia a Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // -------- Validaciones --------
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
    final re = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ\s-]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Solo letras y guiones';
    return null;
  }

  String? _validateLast(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu apellido';
    final re = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ\s-]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Solo letras y guiones';
    return null;
  }

  bool _isGmail(String s) =>
      RegExp(r'^[\w\.\-\+]+@gmail\.com$').hasMatch(s.trim());

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
    if (!_isGmail(v.trim())) return 'Usa un correo @gmail.com';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
    if (v.length < 7) return 'Mínimo 7 caracteres';
    final hasUpper   = RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(v);
    final hasLower   = RegExp(r'[a-záéíóúñ]').hasMatch(v);
    final hasSpecial = RegExp(r'[^A-Za-z0-9\s]').hasMatch(v);
    if (!hasUpper)   return 'Incluye al menos una MAYÚSCULA';
    if (!hasLower)   return 'Incluye al menos una minúscula';
    if (!hasSpecial) return 'Incluye al menos un carácter especial';
    return null;
  }

  // -------- Registro Email/Password + Firestore + Verificación --------
  Future<void> _registerEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      // Crear usuario en Authentication
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      
      // Nombre completo = Nombre + Apellido
      final fullName = '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}'.trim();
      
      // Actualizar display name en Authentication
      await cred.user?.updateDisplayName(fullName);

      // Crear documento en Firestore con UID como ID del documento
      await _firestore.collection('Clients').doc(cred.user!.uid).set({
        'ciudad': '', // Valor por defecto
        'direccion': '', // Valor por defecto
        'email': _emailCtrl.text.trim(),
        'imagen_perfil': '', // Cadena vacía por defecto
        'nombre': fullName,
        'password': _passCtrl.text, 
        'telefono': '', // Valor por defecto
        'uid': cred.user!.uid, // Guardar también el UID como campo
        'fecha_creacion': FieldValue.serverTimestamp(), // Fecha de creación
      });

      // ENVIAR VERIFICACIÓN DE CORREO
      await cred.user!.sendEmailVerification();

      if (!mounted) return;

      // Aviso y cierre de sesión
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te enviamos un correo de verificación. Revisa tu bandeja y confirma tu cuenta para continuar. Es posible que el correo este en la carpeta de SPAM.'),
          duration: Duration(seconds: 4),
        ),
      );
      await FirebaseAuth.instance.signOut();

      // Devolver al Login el email para auto-rellenar
      final result = {
        'status': 'registered',
        'email': _emailCtrl.text.trim(),
      };

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Ocurrió un error: ${e.code}';
      if (e.code == 'email-already-in-use') {
        msg = 'Ese email ya está registrado (${e.code})';
      } else if (e.code == 'invalid-email') {
        msg = 'Email inválido (${e.code})';
      } else if (e.code == 'weak-password') {
        msg = 'La contraseña es muy débil (${e.code})';
      } else if (e.code == 'operation-not-allowed') {
        msg = 'Email/Password no habilitado en Firebase (${e.code})';
      } else if (e.code == 'too-many-requests') {
        msg = 'Demasiados intentos. Inténtalo más tarde.';
      } else if (e.code == 'network-request-failed') {
        msg = 'Sin conexión. Verifica tu internet.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Crear cuenta'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/img/logo.jpg',
                    height: 84,
                    width: 84,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Regístrate para comenzar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kBrand, // título morado
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nombre
                          TextFormField(
                            controller: _firstCtrl,
                            decoration: const InputDecoration(
                              hintText: 'nombre',
                              hintStyle: TextStyle(color: kBrand),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: kBrand),
                            ),
                            style: const TextStyle(color: kBrand),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 12),
                          // Apellido
                          TextFormField(
                            controller: _lastCtrl,
                            decoration: const InputDecoration(
                              hintText: 'apellido',
                              hintStyle: TextStyle(color: kBrand),
                              prefixIcon: Icon(Icons.badge_outlined,
                                  color: kBrand),
                            ),
                            style: const TextStyle(color: kBrand),
                            validator: _validateLast,
                          ),
                          const SizedBox(height: 12),
                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'email (@gmail.com)',
                              hintStyle: TextStyle(color: kBrand),
                              prefixIcon:
                                  Icon(Icons.alternate_email, color: kBrand),
                            ),
                            style: const TextStyle(color: kBrand),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),
                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure1,
                            decoration: InputDecoration(
                              hintText: 'password',
                              hintStyle: const TextStyle(color: kBrand),
                              prefixIcon:
                                  const Icon(Icons.lock_outline, color: kBrand),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure1 = !_obscure1),
                                icon: Icon(
                                  _obscure1
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: kBrand,
                                ),
                              ),
                            ),
                            style: const TextStyle(color: kBrand),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 12),
                          // Confirm Password
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscure2,
                            decoration: InputDecoration(
                              hintText: 'confirm password',
                              hintStyle: const TextStyle(color: kBrand),
                              prefixIcon:
                                  const Icon(Icons.verified_user_outlined,
                                      color: kBrand),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
                                icon: Icon(
                                  _obscure2
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: kBrand,
                                ),
                              ),
                            ),
                            style: const TextStyle(color: kBrand),
                            validator: (v) => v != _passCtrl.text
                                ? 'Las contraseñas no coinciden'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          // Botón principal (mismo estilo que login)
                          ElevatedButton(
                            onPressed: _loading ? null : _registerEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _loading ? 'Creando...' : 'Registrarme',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(color: kBrand),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
