import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecordatoriosPantalla extends StatefulWidget {
  const RecordatoriosPantalla({super.key});

  @override
  State<RecordatoriosPantalla> createState() => _RecordatoriosPantallaState();
}

class _RecordatoriosPantallaState extends State<RecordatoriosPantalla> {
  final Set<String> ocultos = {}; // IDs de reservas ocultas

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final enTresDias = hoy.add(const Duration(days: 3));

    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservas')
            .orderBy('fecha') // debe estar en formato ISO
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reservasFiltradas = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fechaStr = data['fecha'] ?? '';
            final fecha = DateTime.tryParse(fechaStr);
            if (fecha == null || ocultos.contains(doc.id)) return false;

            return (fecha.isAtSameMomentAs(hoy) || fecha.isAfter(hoy)) &&
                (fecha.isBefore(enTresDias) ||
                    fecha.isAtSameMomentAs(enTresDias));
          }).toList();

          if (reservasFiltradas.isEmpty) {
            return const Center(
                child: Text('No hay reservas próximas a vencer'));
          }

          return ListView.builder(
            itemCount: reservasFiltradas.length,
            itemBuilder: (context, index) {
              final doc = reservasFiltradas[index];
              final data = doc.data() as Map<String, dynamic>;
              final fecha = DateTime.tryParse(data['fecha']) ?? DateTime.now();
              final combo = data['combo'] ?? 'Sin combo';
              final estado = data['estadoPago'] ?? 'Sin estado';

              return Card(
                margin: const EdgeInsets.all(10),
                color: Colors.orange[100],
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.deepOrange),
                  title: Text(
                      'Reserva para ${data['cliente'] ?? 'Cliente desconocido'}'),
                  subtitle: Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy – kk:mm').format(fecha)}\nEstado de pago: $estado\nCombo: $combo',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Ocultar este recordatorio',
                    onPressed: () {
                      setState(() {
                        ocultos.add(doc.id);
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
