import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventos_infantiles_web/pantallas/crearEventoReserva.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

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
            key: const Key('boton_descargar_pdf_reservas'),
            icon: const Icon(Icons.download),
            tooltip: 'Descargar PDF',
            color: const Color(0xFFFF6B81),
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('reservas')
                  .orderBy('fecha', descending: false)
                  .get();
              final reservas = snapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
              await _generarPdf(reservas);
            },
          ),
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
            .orderBy('fecha', descending: false)
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
      await eliminarEventoCalendario(id);
      await FirebaseFirestore.instance.collection('reservas').doc(id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva eliminada')),
        );
      }
    }
  }

  Future<void> _generarPdf(List<Map<String, dynamic>> reservas) async {
    final pdf = pw.Document();

    // Cargar fuentes
    final poppinsRegularData =
        await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    final poppinsBoldData =
        await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
    final poppinsRegular = pw.Font.ttf(poppinsRegularData.buffer.asByteData());
    final poppinsBold = pw.Font.ttf(poppinsBoldData.buffer.asByteData());
    final emojiFontData =
        await rootBundle.load('assets/fonts/NotoColorEmoji-Regular.ttf');
    final emojiFont = pw.Font.ttf(emojiFontData.buffer.asByteData());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              'Listado de Reservas',
              style: pw.TextStyle(font: poppinsBold, fontSize: 20),
            ),
            pw.SizedBox(height: 20),
            ...reservas.map((reserva) {
              DateTime fecha;
              final dynamic fechaRaw = reserva['fecha'];
              if (fechaRaw is Timestamp) {
                fecha = fechaRaw.toDate();
              } else if (fechaRaw is String) {
                fecha = DateTime.tryParse(fechaRaw) ?? DateTime.now();
              } else {
                fecha = DateTime.now();
              }

              final horario = DateFormat.Hm().format(fecha);

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 5),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Cumpleañero/a: ${reserva['cliente'] ?? ''}',
                          style: pw.TextStyle(
                            font: poppinsBold,
                            fontSize: 13,
                            fontFallback: [emojiFont],
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                            'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                            style: pw.TextStyle(
                              font: poppinsBold,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text('Horario: $horario',
                            style: pw.TextStyle(
                              font: poppinsBold,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text(
                            'Adulto Responsable: ${reserva['adultoResponsable'] ?? ''}',
                            style: pw.TextStyle(
                              font: poppinsBold,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text('Teléfono: ${reserva['telefono'] ?? ''}',
                            style: pw.TextStyle(
                              font: poppinsRegular,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text(
                            'Cantidad de Niños: ${reserva['cantidadNinos'] ?? '-'} | Adultos: ${reserva['cantidadAdultos'] ?? '-'}',
                            style: pw.TextStyle(
                              font: poppinsRegular,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text(
                            'Combo Lunch Adultos: ${reserva['comboLunchAdultos'] ?? '-'}  | Cantidad: ${reserva['cantidadLunchAdultos'] ?? '0'}',
                            style: pw.TextStyle(
                              font: poppinsRegular,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text(
                            'Combo Dulce Adultos: ${reserva['comboDulceAdultos'] ?? '-'}  | Cantidad: ${reserva['cantidadDulceAdultos'] ?? '0'}',
                            style: pw.TextStyle(
                              font: poppinsRegular,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text('Piñata: ${reserva['pinata'] ?? 'No'}',
                            style: pw.TextStyle(
                              font: poppinsRegular,
                              fontSize: 11,
                              fontFallback: [emojiFont],
                            )),
                        pw.Text(
                            'Estado de pago: ${reserva['estadoPago'] ?? ''}',
                            style: pw.TextStyle(
                                font: poppinsBold,
                                fontSize: 11,
                                fontFallback: [emojiFont],
                                color: PdfColors.green800)),
                        pw.Text('Importe: ${reserva['importe'] ?? ''}',
                            style: pw.TextStyle(
                                font: poppinsRegular,
                                fontSize: 11,
                                fontFallback: [emojiFont])),
                        pw.Text(
                            'Descripcion de pago: ${reserva['pagos'] ?? ''}',
                            style: pw.TextStyle(
                                font: poppinsRegular,
                                fontSize: 11,
                                fontFallback: [emojiFont])),
                        pw.Text(
                            'Solicitud Especial: ${(reserva['solicitudEspecial'] == null || reserva['solicitudEspecial'].toString().trim().isEmpty) ? 'Ninguna' : reserva['solicitudEspecial']}',
                            style: pw.TextStyle(
                              font: poppinsRegular,
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    // Guardar PDF y abrir en nueva pestaña (Flutter Web)
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download =
          'Listado_Reservas_${DateFormat('yyyy_MM').format(DateTime.now())}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
