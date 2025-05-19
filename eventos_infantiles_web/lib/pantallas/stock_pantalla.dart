import 'package:flutter/material.dart';

class StockPantalla extends StatelessWidget {
  const StockPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: const Center(
        child: Text(
          'Listado y edición de stock disponible',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
