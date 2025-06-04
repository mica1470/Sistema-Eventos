import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? errorMensaje;
  bool cargando = false;

  Future<void> _iniciarSesion() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!formKey.currentState!.validate()) return;

    setState(() {
      cargando = true;
      errorMensaje = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMensaje = e.message;
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _iniciarSesionConGoogle() async {
    setState(() {
      cargando = true;
      errorMensaje = null;
    });

    try {
      final googleProvider = GoogleAuthProvider();
      final credenciales =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
      final user = credenciales.user;

      // 🔒 Validar si el usuario ya existía
      final additionalInfo = credenciales.additionalUserInfo;
      final esNuevoUsuario = additionalInfo?.isNewUser ?? false;

      if (esNuevoUsuario) {
        // Si es nuevo, lo deslogueamos inmediatamente
        await FirebaseAuth.instance.currentUser?.delete();
        await FirebaseAuth.instance.signOut();

        setState(() {
          errorMensaje = 'El acceso con nuevas cuentas está deshabilitado.';
        });
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMensaje = e.message;
      });
    } catch (e) {
      setState(() {
        errorMensaje = 'Error inesperado: $e';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('login_scaffold'),
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          key: const Key('login_scroll_view'),
          child: Container(
            key: const Key('login_container'),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(blurRadius: 12, color: Colors.black12)
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                key: const Key('login_form'),
                children: [
                  Stack(
                    children: [
                      Text(
                        "Acceso al sistema",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 1
                            ..color = const Color.fromARGB(118, 66, 66, 66),
                        ),
                      ),
                      const Text(
                        "Acceso al sistema",
                        key: Key('titulo_login'),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B81),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('input_email'),
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico",
                    ),
                    validator: (valor) => valor != null && valor.contains('@')
                        ? null
                        : 'Ingrese un correo válido',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('input_password'),
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: "Contraseña"),
                    obscureText: true,
                    validator: (valor) => valor != null && valor.length >= 6
                        ? null
                        : 'Mínimo 6 caracteres',
                  ),
                  const SizedBox(height: 24),
                  if (errorMensaje != null)
                    Text(
                      errorMensaje!,
                      key: const Key('mensaje_error'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (cargando)
                    const CircularProgressIndicator(key: Key('loading_spinner'))
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          key: const Key('boton_login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDE047),
                            foregroundColor:
                                const Color.fromARGB(153, 66, 66, 66),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _iniciarSesion,
                          child: const Text(
                            "Iniciar sesión",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('boton_google_login'),
                          label: const Text('Iniciar sesión con Google'),
                          icon: const Icon(Icons.login),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _iniciarSesionConGoogle,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // TextButton(
                  //   key: const Key('link_registro'),
                  //   onPressed: () {
                  //     Navigator.pushNamed(context, '/registro');
                  //   },
                  //   child: Stack(
                  //     children: [
                  //       Text(
                  //         '¿No tienes cuenta? Regístrate',
                  //         style: TextStyle(
                  //           fontSize: 17,
                  //           fontWeight: FontWeight.w600,
                  //           foreground: Paint()
                  //             ..style = PaintingStyle.stroke
                  //             ..strokeWidth = 1
                  //             ..color = const Color.fromARGB(118, 66, 66, 66),
                  //         ),
                  //       ),
                  //       const Text(
                  //         '¿No tienes cuenta? Regístrate',
                  //         style: TextStyle(
                  //           fontSize: 17,
                  //           color: Color(0xFFA0D8EF),
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
