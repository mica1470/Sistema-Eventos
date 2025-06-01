// ignore_for_file: library_private_types_in_public_api, avoid_web_libraries_in_flutter, unnecessary_to_list_in_spreads
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class CalendarioPantalla extends StatefulWidget {
  const CalendarioPantalla({super.key});

  @override
  _CalendarioPantallaState createState() => _CalendarioPantallaState();
}

class _CalendarioPantallaState extends State<CalendarioPantalla> {
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  DateTime _diaSeleccionado = DateTime.now();
  List<Map<String, dynamic>> _reservasDelDia = [];
  CalendarFormat _formatoCalendario = CalendarFormat.month;
  DateTime _diaEnfocado = DateTime.now();

  DateTime _limpiarFecha(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = _limpiarFecha(_diaSeleccionado);
    _cargarReservas();
  }

  void _cargarReservas() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('reservas').get();
    Map<DateTime, List<Map<String, dynamic>>> eventos = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final rawFecha = data['fecha'];

      DateTime fecha;

      if (rawFecha is Timestamp) {
        fecha = rawFecha.toDate();
      } else if (rawFecha is String) {
        fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
      } else {
        continue;
      }

      final fechaKey = _limpiarFecha(fecha);

      if (!eventos.containsKey(fechaKey)) {
        eventos[fechaKey] = [];
      }

      eventos[fechaKey]!.add({...data, 'id': doc.id});
    }

    setState(() {
      _eventos = eventos;
      _reservasDelDia = _eventos[_diaSeleccionado] ?? [];
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _diaSeleccionado = _limpiarFecha(selectedDay);
      _diaEnfocado = focusedDay;
      _reservasDelDia = _eventos[_diaSeleccionado] ?? [];
    });
  }

  Future<void> _generarPdf() async {
    final pdf = pw.Document();

    // Cargar fuentes
    final poppinsRegularData =
        await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    final poppinsBoldData =
        await rootBundle.load('assets/fonts/Poppins-Bold.ttf');

    final poppinsRegular = pw.Font.ttf(poppinsRegularData.buffer.asByteData());
    final poppinsBold = pw.Font.ttf(poppinsBoldData.buffer.asByteData());

    final mesActual = _diaEnfocado.month;
    final anioActual = _diaEnfocado.year;
    final primerDiaMes = DateTime(anioActual, mesActual, 1);
    final primerDiaSemana = primerDiaMes.weekday % 7;

    final diasDelMes = DateUtils.getDaysInMonth(anioActual, mesActual);
    final semanas = <List<pw.Widget>>[];
    int diaActual = 1 - primerDiaSemana;

    // Construcción del calendario
    while (diaActual <= diasDelMes) {
      final semana = <pw.Widget>[];
      for (int i = 0; i < 7; i++) {
        if (diaActual < 1 || diaActual > diasDelMes) {
          semana.add(pw.Expanded(child: pw.Container()));
        } else {
          final fecha = DateTime(anioActual, mesActual, diaActual);
          final eventos = _eventos[_limpiarFecha(fecha)] ?? [];
          semana.add(
            pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.all(2),
                padding: const pw.EdgeInsets.all(4),
                height: 85,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.pink400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '$diaActual',
                      style: pw.TextStyle(
                        font: poppinsBold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    ...eventos.map((evento) => pw.Text(
                          '• ${evento['cliente']} - ${DateFormat.Hm().format(DateTime.tryParse(evento['fecha']) ?? DateTime.now())} \n- Adulto: ${evento['adultoResponsable']}',
                          style: pw.TextStyle(
                            font: poppinsRegular,
                            fontSize: 10,
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        }
        diaActual++;
      }
      semanas.add(semana);
    }

    // Página 1: Calendario
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Calendario de Reservas - ${DateFormat.yMMMM('es').format(primerDiaMes)}',
                style: pw.TextStyle(font: poppinsBold, fontSize: 20),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                    .map((d) => pw.Expanded(
                          child: pw.Text(
                            d,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: poppinsBold,
                              fontSize: 14,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              pw.Divider(),
              ...semanas.map((semana) => pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: semana,
                  )),
            ],
          );
        },
      ),
    );

    // Página 2: Listado de reservas del mes
    final reservasListado = <Map<String, dynamic>>[];

    for (int dia = 1; dia <= diasDelMes; dia++) {
      final fecha = DateTime(anioActual, mesActual, dia);
      final eventos = _eventos[_limpiarFecha(fecha)] ?? [];

      for (final evento in eventos) {
        reservasListado.add({
          'fecha': DateTime.tryParse(evento['fecha']),
          'cliente': evento['cliente'],
          'adultoResponsable': evento['adultoResponsable'],
          'telefono': evento['telefono'],
          'cantidadNinos': evento['cantidadNinos'],
          'cantidadAdultos': evento['cantidadAdultos'],
          'comboDulceAdultos': evento['comboDulceAdultos'],
          'comboLunchAdultos': evento['comboLunchAdultos'],
          'pinata': evento['pinata'],
          'estadoPago': evento['estadoPago'],
          'solicitudEspecial': evento['solicitudEspecial'],
        });
      }
    }

    reservasListado.removeWhere((reserva) => reserva['fecha'] == null);

    reservasListado.sort((a, b) {
      final fechaA = a['fecha'] as DateTime;
      final fechaB = b['fecha'] as DateTime;
      return fechaA.compareTo(fechaB);
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Listado de Reservas - ${DateFormat.yMMMM('es').format(primerDiaMes)}',
                style: pw.TextStyle(font: poppinsBold, fontSize: 22),
              ),
              pw.SizedBox(height: 20),
              ...reservasListado.map((evento) {
                final fecha = evento['fecha'] as DateTime;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 14),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.pink400),
                    borderRadius: pw.BorderRadius.circular(8),
                    color: PdfColors.pink50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cumpleañero/a: ${evento['cliente']}',
                        style: pw.TextStyle(
                          font: poppinsBold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)} |  Hora: ${DateFormat.Hm().format(fecha)}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'Adulto Responsable: ${evento['adultoResponsable']}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'Teléfono: ${evento['telefono']}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'Niños: ${evento['cantidadNinos']}  |  Adultos: ${evento['cantidadAdultos']}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'Combo Lunch Adultos: ${evento['comboLunchAdultos']}  |  Cantidad: ${evento['cantidadLunchAdultos']}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'Combo Dulce Adultos: ${evento['comboDulceAdultos']}   |  Cantidad: ${evento['cantidadDulceAdultos']}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'Piñata: ${evento['pinata']}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'Estado de pago: ${evento['estadoPago']}',
                        style: pw.TextStyle(
                          font: poppinsBold,
                          fontSize: 12,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text('Importe: ${evento['importe'] ?? '0'}',
                          style: pw.TextStyle(
                            font: poppinsBold,
                            fontSize: 12,
                          )),
                      pw.Text(
                          'Descripcion de pago: ${evento['pagos'] ?? 'Sin descripción'}',
                          style: pw.TextStyle(
                            font: poppinsBold,
                            fontSize: 12,
                          )),
                      pw.Text(
                        'Solicitud Especial: ${(evento['solicitudEspecial'] == null || evento['solicitudEspecial'].toString().trim().isEmpty) ? 'Ninguna' : evento['solicitudEspecial']}',
                        style: pw.TextStyle(font: poppinsRegular, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    // Guardar PDF
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'Calendario_Reservas_${mesActual}_$anioActual.pdf';

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('calendarioPantalla'),
      backgroundColor: const Color(0xFFF3F4F6), // Fondo gris claro
      appBar: AppBar(
        title: const Text('Calendario de Reservas'),
        backgroundColor: const Color(0xFFFDE047), // Amarillo suave
        foregroundColor: Colors.black87,
        leading: IconButton(
          key: const Key('calendarioPantallaBackButton'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/dashboard');
          },
        ),
        actions: [
          IconButton(
            key: const Key('calendarioPantallaExportPdfButton'),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _generarPdf,
            color: const Color(0xFFFF6B81), // Rosa coral para icono PDF
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            key: const Key('calendarioPantallaTableCalendar'),
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _diaEnfocado,
            calendarFormat: _formatoCalendario,
            onFormatChanged: (nuevoFormato) {
              setState(() {
                _formatoCalendario = nuevoFormato;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _diaEnfocado = focusedDay;
              });
            },
            selectedDayPredicate: (day) => isSameDay(day, _diaSeleccionado),
            eventLoader: (day) => _eventos[_limpiarFecha(day)] ?? [],
            onDaySelected: _onDaySelected,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
              CalendarFormat.twoWeeks: '2 semanas',
              CalendarFormat.week: 'Semana',
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Color(0xFFFF6B81), // Rosa coral
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color(0xFFA0D8EF), // Amarillo suave para hoy
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(
                    255, 228, 95, 115), // Rosa coral oscuro para selección
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: const TextStyle(
                color: Color(0xFFFF6B81), // Amarillo suave encabezados
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: const Color(0xFFFF6B81), // Rosa coral
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.white),
              leftChevronIcon:
                  const Icon(Icons.chevron_left, color: Color(0xFFFF6B81)),
              rightChevronIcon:
                  const Icon(Icons.chevron_right, color: Color(0xFFFF6B81)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            key: const Key('calendarioPantallaReservasDelDia'),
            child: _reservasDelDia.isEmpty
                ? const Center(child: Text('No hay reservas para este día'))
                : ListView.builder(
                    key: const Key('calendarioPantallaReservasListView'),
                    itemCount: _reservasDelDia.length,
                    itemBuilder: (context, index) {
                      final reserva = _reservasDelDia[index];
                      final fecha = reserva['fecha'] is Timestamp
                          ? (reserva['fecha'] as Timestamp).toDate()
                          : DateTime.tryParse(reserva['fecha']) ??
                              DateTime.now();

                      return Card(
                        key: Key('tarjeta_reserva_$index'),
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: ListTile(
                          key: Key('list_tile_reserva_$index'),
                          title: Text('Cumpleañero: ${reserva['cliente']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B81))),
                          subtitle: Text(
                              '\nAdulto Responsable: ${reserva['adultoResponsable'] ?? 'Sin nombre'}\nHorario: ${DateFormat.Hm().format(fecha)}\nTelefono: ${reserva['telefono'] ?? ''}\nCantidad de niños: ${reserva['cantidadNinos'] ?? '-'}\nCantidad de adultos: ${reserva['cantidadAdultos'] ?? '-'}\nCombo Lunch Adultos: ${reserva['comboLunchAdultos'] ?? '-'} - Cantidad: ${reserva['cantidadLunchAdultos']} \nCombo Dulce Adultos: ${reserva['comboDulceAdultos'] ?? '-'} - Cantidad: ${reserva['cantidadDulceAdultos']} \nPiñata: ${reserva['pinata'] ?? '-'}\nEstado de pago:  ${reserva['estadoPago']}\nImporte: ${reserva['importe'] ?? '-'} \nDescripcion de pago: ${reserva['pagos'] ?? '-'}\nSolicitud Especial: ${(reserva['solicitudEspecial'] == null || reserva['solicitudEspecial'].toString().trim().isEmpty) ? 'Ninguna' : reserva['solicitudEspecial']}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.event_note,
                              color: Color(0xFFA0D8EF)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
