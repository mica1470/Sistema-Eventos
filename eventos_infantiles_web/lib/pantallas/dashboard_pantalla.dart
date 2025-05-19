import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardPantalla extends StatelessWidget {
  const DashboardPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: Text('Menú',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Reservas'),
              onTap: () {
                Navigator.pop(context);
                // Ya estás en reservas (dashboard), si querés puedes recargar o algo.
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                    context, '/configuracion'); // Define esta ruta
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Stock'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/stock'); // Define esta ruta
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          double childAspectRatio = 3 / 2;

          if (constraints.maxWidth >= 900) {
            crossAxisCount = 3;
            childAspectRatio = 4 / 3;
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 2;
            childAspectRatio = 3 / 2;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservas')
                .orderBy('fecha')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final reservas = snapshot.data!.docs;
              if (reservas.isEmpty) {
                return const Center(child: Text('No hay reservas registradas'));
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: reservas.length,
                  itemBuilder: (context, index) {
                    final reserva =
                        reservas[index].data()! as Map<String, dynamic>;

                    final fechaStr = reserva['fecha'] ?? '';
                    DateTime fecha =
                        DateTime.tryParse(fechaStr) ?? DateTime.now();

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cliente: ${reserva['cliente'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                                'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
                            Text(
                                'Hora inicio: ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'),
                            Text('Hora fin: ${reserva['horaFin'] ?? ''}'),
                            const SizedBox(height: 8),
                            Text('Combo: ${reserva['combo'] ?? ''}'),
                            Text('Estado pago: ${reserva['estadoPago'] ?? ''}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
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
