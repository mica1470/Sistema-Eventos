import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecordatoriosPantalla extends StatefulWidget {
  const RecordatoriosPantalla({super.key});

  @override
  State<RecordatoriosPantalla> createState() => _RecordatoriosPantallaState();
}

class _RecordatoriosPantallaState extends State<RecordatoriosPantalla> {
  Map<String, Map<String, dynamic>> borradosRecientemente = {};

  void restaurarRecordatorio(String id, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('recordatorios')
        .doc(id)
        .set(data);
    setState(() {
      borradosRecientemente.remove(id);
    });
  }

  Future<void> recalcularRecordatorios() async {
    final hoy = DateTime.now();
    final enTresDias = hoy.add(const Duration(days: 3));

    final snapshot = await FirebaseFirestore.instance
        .collection('reservas')
        .orderBy('fecha')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fecha = DateTime.tryParse(data['fecha'] ?? '');
      if (fecha == null) continue;

      if (fecha.isAfter(hoy.subtract(const Duration(seconds: 1))) &&
          fecha.isBefore(enTresDias.add(const Duration(seconds: 1)))) {
        await FirebaseFirestore.instance
            .collection('recordatorios')
            .doc(doc.id)
            .set(data);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordatorios actualizados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restaurar recordatorios',
            onPressed: recalcularRecordatorios,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recordatorios')
            .orderBy('fecha')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No hay recordatorios pendientes'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final fecha =
                  DateTime.tryParse(data['fecha'] ?? '') ?? DateTime.now();
              final cliente = data['cliente'] ?? 'Cliente desconocido';
              final combo = data['combo'] ?? 'Sin combo';
              final estado = data['estadoPago'] ?? 'Sin estado';

              return Card(
                margin: const EdgeInsets.all(10),
                color: Colors.orange[100],
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.deepOrange),
                  title: Text('Reserva para $cliente'),
                  subtitle: Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy – kk:mm').format(fecha)}\nEstado de pago: $estado\nCombo: $combo',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Eliminar recordatorio',
                    onPressed: () async {
                      final confirmacion = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('¿Eliminar recordatorio?'),
                          content: const Text('Esto lo borrará temporalmente.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmacion == true) {
                        borradosRecientemente[doc.id] = data;
                        await FirebaseFirestore.instance
                            .collection('recordatorios')
                            .doc(doc.id)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Recordatorio eliminado'),
                            action: SnackBarAction(
                              label: 'Restaurar',
                              onPressed: () {
                                restaurarRecordatorio(doc.id, data);
                              },
                            ),
                          ),
                        );
                      }
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
