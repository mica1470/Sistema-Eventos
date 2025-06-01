import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? errorMensaje;
  bool cargando = false;

  Future<void> _registrarUsuario() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!formKey.currentState!.validate()) return;

    setState(() {
      cargando = true;
      errorMensaje = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );
      Navigator.pop(context);
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
      appBar: AppBar(
        key: const Key('appBarRegistro'), // <- IDENTIFICADOR PARA TESTING
        backgroundColor: const Color(0xFFFDE047),
        foregroundColor: Colors.black,
        title: const Text('Registro de usuario'),
      ),
      body: Center(
        child: SingleChildScrollView(
          key: const Key('scrollRegistro'), // <- IDENTIFICADOR PARA TESTING
          child: Container(
            key: const Key(
                'formContainerRegistro'), // <- IDENTIFICADOR PARA TESTING
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
                  TextFormField(
                    key: const Key('inputCorreoRegistro'), // <- IDENTIFICADOR
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
                    key: const Key(
                        'inputContrasenaRegistro'), // <- IDENTIFICADOR
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
                      key:
                          const Key('mensajeErrorRegistro'), // <- IDENTIFICADOR
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (cargando)
                    const CircularProgressIndicator(
                      key: Key('cargandoRegistro'), // <- IDENTIFICADOR
                    )
                  else
                    ElevatedButton(
                      key: const Key(
                          'botonRegistrarUsuario'), // <- IDENTIFICADOR
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B81),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _registrarUsuario,
                      child: const Text(
                        "Registrar",
                        style: TextStyle(fontWeight: FontWeight.bold),
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
