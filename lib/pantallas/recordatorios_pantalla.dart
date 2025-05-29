// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecordatoriosPantalla extends StatefulWidget {
  const RecordatoriosPantalla({super.key});

  @override
  _RecordatoriosPantallaState createState() => _RecordatoriosPantallaState();
}

class _RecordatoriosPantallaState extends State<RecordatoriosPantalla> {
  // Mapa para almacenar recordatorios borrados temporalmente
  final Map<String, Map<String, dynamic>> borradosRecientemente = {};

  // Método para recalcular recordatorios próximos (3 días)
  Future<void> recalcularRecordatorios() async {
    final hoy = DateTime.now();
    final enTresDias = hoy.add(const Duration(days: 3));

    final snapshot = await FirebaseFirestore.instance
        .collection('reservas')
        .orderBy('fecha')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fechaStr = data['fecha'] as String? ?? '';
      final fecha = DateTime.tryParse(fechaStr);
      if (fecha == null) continue;

      if (fecha.isAfter(hoy.subtract(const Duration(seconds: 1))) &&
          fecha.isBefore(enTresDias.add(const Duration(seconds: 1)))) {
        await FirebaseFirestore.instance
            .collection('recordatorios')
            .doc(doc.id)
            .set(data);
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordatorios actualizados')),
    );
  }

  // Método para eliminar un recordatorio
  Future<void> eliminarRecordatorio(
      String id, Map<String, dynamic> data) async {
    // Guardar en borradosRecientemente para poder restaurar
    borradosRecientemente[id] = data;

    await FirebaseFirestore.instance
        .collection('recordatorios')
        .doc(id)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recordatorio eliminado'),
        action: SnackBarAction(
          label: 'Restaurar',
          onPressed: () {
            restaurarRecordatorio(id, data);
          },
        ),
      ),
    );
  }

  // Método para restaurar un recordatorio borrado
  Future<void> restaurarRecordatorio(
      String id, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('recordatorios')
        .doc(id)
        .set(data);

    if (!mounted) return;

    setState(() {
      borradosRecientemente.remove(id);
    });
  }

  String formatearFecha(String fechaStr) {
    final fecha = DateTime.tryParse(fechaStr);
    if (fecha == null) return 'Fecha inválida';
    return DateFormat('dd/MM/yyyy – kk:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar recordatorios',
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
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
              final fechaStr = data['fecha'] as String? ?? '';
              final cliente = data['cliente'] ?? 'Cumpleañero desconocido';
              final adultoResponsable =
                  data['adultoResponsable'] ?? 'Adulto desconocido';
              final telefono = data['telefono'] ?? 'Sin teléfono';
              final cantidadNinos = data['cantidadNinos'] ?? 'Sin combo';
              final cantidadAdultos = data['cantidadAdultos'] ?? 'Sin combo';
              final comboDulceAdultos =
                  data['comboDulceAdultos'] ?? 'Sin combo';
              final cantidadLunchAdultos =
                  data['cantidadLunchAdultos'] ?? 'Sin combo';
              final comboLunchAdultos =
                  data['comboLunchAdultos'] ?? 'Sin combo';
              final pinata = data['pinata'] ?? 'Sin piñata';
              final estado = data['estadoPago'] ?? 'Sin estado';
              final importe = data['importe'] ?? 'Sin importe';
              final pagos = data['pagos'] ?? 'Sin detalles de pago';
              final solicitudEspecial =
                  data['solicitudEspecial'] ?? 'Sin solicitud especial';

              return Card(
                margin: const EdgeInsets.all(10),
                color: Colors.orange[100],
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.deepOrange),
                  title: Text('Reserva para $cliente'),
                  subtitle: Text('Fecha: ${formatearFecha(fechaStr)}\n'
                      'Adulto Responsable: $adultoResponsable\n'
                      'Teléfono: $telefono\n'
                      'Cantidad de Niños: $cantidadNinos\n'
                      'Cantidad de Adultos: $cantidadAdultos\n'
                      'Combo Dulce Adultos: $comboDulceAdultos\n'
                      'Combo Lunch Adultos: $comboLunchAdultos\n'
                      'Cantidad: $cantidadLunchAdultos\n'
                      'Piñata: $pinata\n'
                      'Estado de Pago: $estado\n'
                      'Importe: $importe\n'
                      'Detalle de pago: $pagos\n'
                      'Solicitud Especial: $solicitudEspecial'),
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
                        await eliminarRecordatorio(doc.id, data);
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
