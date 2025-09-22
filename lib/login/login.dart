import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registrarse.dart';
import '../Catalogo/catalogo.dart';
import 'terminos_servicio.dart';
import 'politicas_privacidad.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _forgotEmailCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;

  static const Color kBrand = Color(0xFF843772);

  bool _isGmail(String s) =>
      RegExp(r'^[\w\.\-\+]+@gmail\.com$').hasMatch(s.trim());

  void _clearAll() {
    _emailCtrl.clear();
    _passCtrl.clear();
    setState(() {
      _obscure = true;
      _remember = false;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _forgotEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passCtrl.text,
      );

      // 🔒 Bloquear acceso si NO ha verificado el correo
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        // (Opcional) reenviar verificación
        try { await user.sendEmailVerification(); } catch (_) {}

        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes verificar tu correo. Te reenviamos el email de verificación.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return; // no avanzar
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _remember);
      if (!mounted) return;
      _clearAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CatalogScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudo iniciar sesión (${e.code})';
      if (e.code == 'invalid-email') msg = 'Email inválido (${e.code})';
      if (e.code == 'user-not-found') {
        msg = 'Usuario no existe. Corrobora o regístrate. (${e.code})';
      }
      if (e.code == 'wrong-password') msg = 'Contraseña incorrecta (${e.code})';
      if (e.code == 'operation-not-allowed') {
        msg = 'Método no habilitado en Firebase (${e.code})';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Función para mostrar el diálogo de recuperación de contraseña
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Recuperar contraseña',
            style: TextStyle(color: kBrand),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa tu correo electrónico para restablecer tu contraseña'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _forgotEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  if (!_isGmail(v.trim())) {
                    return 'Debe ser un correo @gmail.com válido';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = _forgotEmailCtrl.text.trim();
                if (email.isEmpty || !_isGmail(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa un correo @gmail válido'),
                    ),
                  );
                  return;
                }
                
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Te enviamos un correo para restablecer tu contraseña'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111111), Color(0xFF3A3A3A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/img/logo.jpg',
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AMERICANO CRUZ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card
                    Card(
                      elevation: 10,
                      color: Colors.white,
                      shadowColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Iniciar sesión',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _LoginPageState.kBrand,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Email @gmail
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: kBrand,
                                  ),
                                  hintText: 'example@gmail.com',
                                  hintStyle: TextStyle(color: kBrand),
                                ),
                                style: const TextStyle(color: kBrand),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Ingresa tu correo @gmail';
                                  }
                                  if (_isGmail(v.trim())) return null;
                                  return 'Debe ser un correo @gmail.com válido';
                                },
                              ),
                              const SizedBox(height: 12),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: kBrand,
                                  ),
                                  hintText: 'password',
                                  hintStyle: const TextStyle(color: kBrand),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: kBrand,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: kBrand),
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 8),
                              // Checkbox "Recordarme"
                              Row(
                                children: [
                                  Checkbox(
                                    value: _remember,
                                    onChanged: (v) =>
                                        setState(() => _remember = v ?? false),
                                    activeColor: kBrand,
                                  ),
                                  const Text(
                                    'Recordarme',
                                    style: TextStyle(color: kBrand),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),
                              // Botón "¿Olvidaste tu contraseña?" centrado
                              Center(
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(color: kBrand),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white, // texto blanco
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _loading ? 'Entrando…' : 'Iniciar sesión',
                                ),
                              ),

                              const SizedBox(height: 10),
                              Row(
                                children: const [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'o',
                                      style: TextStyle(color: kBrand),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () async {
                                  _clearAll();
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegistrarsePage(),
                                    ),
                                  );
                                  // Si Registro devolvió datos, auto-rellenamos email y avisamos
                                  if (result is Map &&
                                      result['status'] == 'registered') {
                                    final mail =
                                        (result['email'] as String?) ?? '';
                                    if (mounted) {
                                      setState(() {
                                        _emailCtrl.text = mail;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '¡Registro exitoso! Verifica tu correo y luego inicia sesión.',
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    _clearAll();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  side: const BorderSide(
                                    color: kBrand,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  foregroundColor: kBrand,
                                ),
                                child: const Text(
                                  'Crear cuenta nueva',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // RichText con navegación a las pantallas
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Al continuar, aceptas nuestros ',
                          ),
                          TextSpan(
                            text: 'Términos de Servicio',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TermsOfServiceScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
