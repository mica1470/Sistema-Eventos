import 'package:flutter/material.dart';

class DashboardPantalla extends StatelessWidget {
  const DashboardPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Bienvenido al Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/nueva-reserva');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Reserva'),
      ),
    );
  }
}
