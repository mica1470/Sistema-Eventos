import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registro_pantalla.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // 🪄 Gris claro
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white, // 🎨 Blanco
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(blurRadius: 12, color: Colors.black12)
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
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
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: "Contraseña"),
                    obscureText: true,
                    validator: (valor) => valor != null && valor.length >= 6
                        ? null
                        : 'Mínimo 6 caracteres',
                  ),
                  const SizedBox(height: 24),
                  if (errorMensaje != null)
                    Text(errorMensaje!,
                        style: const TextStyle(color: Colors.red)),
                  if (cargando)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFDE047), // 🍓 Rosa coral
                        foregroundColor: const Color.fromARGB(153, 66, 66, 66),
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
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegistroPantalla()),
                      );
                    },
                    child: Stack(
                      children: [
                        Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 1
                              ..color = const Color.fromARGB(
                                  118, 66, 66, 66), // borde gris oscuro
                          ),
                        ),
                        const Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(
                            fontSize: 17,
                            color: Color(0xFFA0D8EF), // azul pastel
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
