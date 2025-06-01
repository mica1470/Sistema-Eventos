import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReservasPantalla extends StatelessWidget {
  const ReservasPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('pantalla_reservas'),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        key: const Key('barra_app_reservas'),
        backgroundColor: Colors.white,
        title: const Text(
          'Todas las Reservas',
          style: TextStyle(
            color: Color(0xFFA0D8EF),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            key: const Key('boton_nueva_reserva'),
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Reserva',
            color: const Color(0xFFFF6B81),
            onPressed: () {
              Navigator.pushNamed(context, '/nueva-reserva');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservas')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              key: Key('error_reservas'),
              child: Text('Error al cargar reservas'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              key: Key('cargando_reservas'),
              child: CircularProgressIndicator(),
            );
          }

          final reservas = snapshot.data!.docs;

          if (reservas.isEmpty) {
            return const Center(
              key: Key('sin_reservas'),
              child: Text('No hay reservas registradas'),
            );
          }

          return ListView.separated(
            key: const Key('lista_reservas'),
            itemCount: reservas.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final reserva = reservas[index].data() as Map<String, dynamic>;
              final id = reservas[index].id;
              final cliente = reserva['cliente'] ?? 'Cumpleañero desconocido';
              final adultoResponsable = reserva['adultoResponsable'] ??
                  'Adulto responsable desconocido';
              final telefono = reserva['telefono'] ?? 'Sin teléfono';
              final comboDulceAdultos =
                  reserva['comboDulceAdultos'] ?? 'Sin combo';
              final comboLunchAdultos =
                  reserva['comboLunchAdultos'] ?? 'Sin combo';
              final pinata = reserva['pinata'] ?? 'Sin piñata';
              final estadoPago = reserva['estadoPago'] ?? '';
              final fechaStr = reserva['fecha'] ?? '';
              final fecha = DateTime.tryParse(fechaStr) ?? DateTime.now();

              return Card(
                key: Key('tarjeta_reserva_$index'),
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  key: Key('list_tile_reserva_$index'),
                  leading: const Icon(Icons.event, color: Colors.black),
                  title: Text(
                    cliente,
                    key: Key('nombre_cliente_$index'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '• Adulto Responsable: $adultoResponsable\n'
                    '• Fecha: ${fecha.day}/${fecha.month}/${fecha.year}\n'
                    '• Telefono: $telefono\n'
                    '• Cantidad de niños: ${reserva['cantidadNinos'] ?? '-'}\n'
                    '• Cantidad de adultos: ${reserva['cantidadAdultos'] ?? '-'}\n'
                    '• Combo Lunch Adultos: $comboLunchAdultos\n'
                    '• Cantidad de Lunch Adultos: ${reserva['cantidadLunchAdultos'] ?? '-'}\n'
                    '• Combo Dulce Adultos: $comboDulceAdultos\n'
                    '• Cantidad de Dulce Adultos: ${reserva['cantidadDulceAdultos'] ?? '-'}\n'
                    '• Piñata: $pinata\n'
                    '• Estado de pago: $estadoPago\n'
                    '• Importe: ${reserva['importe'] ?? '-'}\n'
                    '• Descripción de pago: ${reserva['pagos'] ?? '-'}\n'
                    '• Solicitud Especial: ${reserva['solicitudEspecial'] ?? '-'}',
                    key: Key('detalle_reserva_$index'),
                  ),
                  trailing: PopupMenuButton<String>(
                    key: Key('menu_reserva_$index'),
                    onSelected: (value) {
                      if (value == 'editar') {
                        Navigator.pushNamed(
                          context,
                          '/editar-reserva',
                          arguments: {
                            'reservaId': id,
                            'reservaDatos': reserva,
                          },
                        );
                      } else if (value == 'eliminar') {
                        _confirmarEliminacion(context, id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextDialog) => AlertDialog(
        key: Key('dialogo_confirmar_eliminacion_$id'),
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que querés eliminar esta reserva?',
        ),
        actions: [
          TextButton(
            key: Key('boton_cancelar_eliminacion_$id'),
            onPressed: () => Navigator.pop(contextDialog, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFA0D8EF), // Azul pastel
            ),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: Key('boton_confirmar_eliminacion_$id'),
            onPressed: () => Navigator.pop(contextDialog, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B81), // Rosa coral
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('reservas').doc(id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva eliminada')),
        );
      }
    }
  }
}
