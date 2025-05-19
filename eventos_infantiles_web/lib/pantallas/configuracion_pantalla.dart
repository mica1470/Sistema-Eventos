import 'package:flutter/material.dart';

class ConfiguracionPantalla extends StatelessWidget {
  const ConfiguracionPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: const Center(
        child: Text(
          'Configuración del bot de WhatsApp',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
