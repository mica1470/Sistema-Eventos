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

      // Navegar al Dashboard
      if (!mounted) {
        return; // para evitar errores si el widget ya no está en pantalla
      }
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
      backgroundColor: Colors.purple.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
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
                children: [
                  const Text(
                    "Acceso al sistema",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: emailController,
                    decoration:
                        const InputDecoration(labelText: "Correo electrónico"),
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
                      onPressed: _iniciarSesion,
                      child: const Text("Iniciar sesión"),
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
                    child: const Text('¿No tienes cuenta? Regístrate'),
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
