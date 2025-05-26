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

    final mesActual = _diaEnfocado.month;
    final anioActual = _diaEnfocado.year;
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    final eventosMes = _eventos.entries.where((entry) {
      final fecha = entry.key;
      return fecha.month == mesActual && fecha.year == anioActual;
    }).toList();

    if (eventosMes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay reservas este mes para imprimir.')),
      );
      return;
    }

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Reservas para el mes',
              style: const pw.TextStyle(fontSize: 24),
            ),
          ),
          ...eventosMes.map((entry) {
            final fecha = entry.key;
            final reservas = entry.value;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(DateFormat.yMMMMd('es').format(fecha),
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Column(
                  children: reservas.map((reserva) {
                    final fechaReserva = reserva['fecha'] is Timestamp
                        ? (reserva['fecha'] as Timestamp).toDate()
                        : DateTime.tryParse(reserva['fecha']) ?? DateTime.now();

                    final horario = DateFormat.Hm().format(fechaReserva);

                    return pw.Bullet(
                      text:
                          '${reserva['cliente'] ?? 'Sin nombre'} - $horario\nTelefono: ${reserva['telefono'] ?? ''}\nCombo Lunch Adultos: ${reserva['comboLunchAdultos'] ?? '-'}\nCombo Dulce Adultos: ${reserva['comboDulceAdultos'] ?? '-'}\nPiñata: ${reserva['pinata'] ?? '-'}\nEstado de pago: ${reserva['estadoPago'] ?? '-'}\nSolicitud Especial: ${reserva['solicitudEspecial'] ?? 'Ninguna'}',
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ),
    );

    final bytes = await pdf.save();

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'reservas_mes.pdf';

    html.document.body!.append(anchor);
    anchor.click();

    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Fondo gris claro
      appBar: AppBar(
        title: const Text('Calendario de Reservas'),
        backgroundColor: const Color(0xFFFDE047), // Amarillo suave
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/dashboard');
          },
        ),
        actions: [
          IconButton(
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
            child: _reservasDelDia.isEmpty
                ? const Center(child: Text('No hay reservas para este día'))
                : ListView.builder(
                    itemCount: _reservasDelDia.length,
                    itemBuilder: (context, index) {
                      final reserva = _reservasDelDia[index];
                      final fecha = reserva['fecha'] is Timestamp
                          ? (reserva['fecha'] as Timestamp).toDate()
                          : DateTime.tryParse(reserva['fecha']) ??
                              DateTime.now();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: ListTile(
                          title: Text(
                              'Cumpleañero: ${reserva['cliente']}' ??
                                  'Cliente sin nombre',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B81))),
                          subtitle: Text(
                            '\nHorario: ${DateFormat.Hm().format(fecha)}\nTelefono: ${reserva['telefono'] ?? ''}\nCombo Lunch Adultos: ${reserva['comboLunchAdultos'] ?? '-'}\nCombo Dulce Adultos: ${reserva['comboDulceAdultos'] ?? '-'}\nPiñata: ${reserva['pinata'] ?? '-'}\nEstado de pago: ${reserva['estadoPago'] ?? '-'}\nSolicitud Especial: ${reserva['solicitudEspecial'] ?? 'Ninguna'}',
                          ),
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
