import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NuevaReservaPantalla extends StatefulWidget {
  final Map<String, dynamic>? reservaExistente;
  final String? reservaId;
  const NuevaReservaPantalla(
      {super.key, this.reservaExistente, this.reservaId});
  factory NuevaReservaPantalla.fromRouteSettings(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    return NuevaReservaPantalla(
      reservaId: args != null ? args['reservaId'] as String? : null,
      reservaExistente:
          args != null ? args['reservaDatos'] as Map<String, dynamic>? : null,
    );
  }
  @override
  State<NuevaReservaPantalla> createState() => _NuevaReservaPantallaState();
}

class _NuevaReservaPantallaState extends State<NuevaReservaPantalla> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();
  Map<DateTime, bool> diasDisponibles = {};
  DateTime? fecha;
  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;
  String combo = 'SIMPLE';
  String estadoPago = 'Pendiente';
  bool cargando = false;
  final List<Map<String, TimeOfDay>> horariosDisponibles = [
    {
      'inicio': const TimeOfDay(hour: 14, minute: 0),
      'fin': const TimeOfDay(hour: 16, minute: 0),
    },
    {
      'inicio': const TimeOfDay(hour: 17, minute: 0),
      'fin': const TimeOfDay(hour: 19, minute: 0),
    },
  ];
  @override
  void initState() {
    super.initState();
    cargarDiasDisponibles();
    if (widget.reservaExistente != null) {
      final r = widget.reservaExistente!;
      clienteController.text = r['cliente'] ?? '';
      telefonoController.text = r['telefono'] ?? '';
      observacionesController.text = r['observaciones'] ?? '';
      combo = r['combo'] ?? 'SIMPLE';
      estadoPago = r['estadoPago'] ?? 'Pendiente';
      final fechaStr = r['fecha'] ?? '';
      fecha = DateTime.tryParse(fechaStr);
      if (fecha != null) {
        horaInicio = TimeOfDay(hour: fecha!.hour, minute: fecha!.minute);
      }
      final horaFinStr = r['horaFin'] ?? '00:00';
      final partes = horaFinStr.split(':');
      if (partes.length == 2) {
        horaFin = TimeOfDay(
          hour: int.tryParse(partes[0]) ?? 0,
          minute: int.tryParse(partes[1]) ?? 0,
        );
      }
    }
  }

  Future<void> cargarDiasDisponibles() async {
    final ahora = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: ahora.toIso8601String())
        .get();
    final conteoPorDia = <DateTime, int>{};
    for (var doc in snapshot.docs) {
      final fechaReserva = DateTime.tryParse(doc['fecha']);
      if (fechaReserva == null) continue;
      final dia =
          DateTime(fechaReserva.year, fechaReserva.month, fechaReserva.day);
      conteoPorDia[dia] = (conteoPorDia[dia] ?? 0) + 1;
    }
    final nuevosDias = <DateTime, bool>{};
    for (int i = 0; i <= 365; i++) {
      final dia = DateTime(ahora.year, ahora.month, ahora.day + i);
      final cantidad = conteoPorDia[dia] ?? 0;
      nuevosDias[dia] = cantidad < 2;
    }
    if (!mounted) return;
    setState(() {
      diasDisponibles = nuevosDias;
    });
  }

  Future<void> guardarReserva() async {
    if (!formKey.currentState!.validate() ||
        fecha == null ||
        horaInicio == null ||
        horaFin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }
    final fechaInicioDT = DateTime(fecha!.year, fecha!.month, fecha!.day,
        horaInicio!.hour, horaInicio!.minute);
    final fechaFinDT = DateTime(
        fecha!.year, fecha!.month, fecha!.day, horaFin!.hour, horaFin!.minute);
    if (!fechaFinDT.isAfter(fechaInicioDT)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('La hora de fin debe ser posterior a la hora de inicio')),
      );
      return;
    }
    setState(() => cargando = true);
    try {
      final datosReserva = {
        'cliente': clienteController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'combo': combo,
        'estadoPago': estadoPago,
        'fecha': fechaInicioDT.toIso8601String(),
        'horaFin':
            '${horaFin!.hour.toString().padLeft(2, '0')}:${horaFin!.minute.toString().padLeft(2, '0')}',
        'observaciones': observacionesController.text.trim(),
      };
      final reservasRef = FirebaseFirestore.instance.collection('reservas');
      if (widget.reservaId != null) {
        await reservasRef.doc(widget.reservaId).update(datosReserva);
      } else {
        await reservasRef.add({
          ...datosReserva,
          'creado': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => cargando = false);
    }
  }

  Future<bool> estaFechaDisponible(DateTime date) async {
    final fechaInicio = DateTime(date.year, date.month, date.day);
    final fechaFin = fechaInicio.add(const Duration(days: 1));
    final reservas = await FirebaseFirestore.instance
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: fechaInicio.toIso8601String())
        .where('fecha', isLessThan: fechaFin.toIso8601String())
        .get();
    return reservas.docs.length < 2;
  }

  Future<void> seleccionarFechaYHorario() async {
    final ahora = DateTime.now();
    final seleccionFecha = await showDatePicker(
      context: context,
      initialDate: fecha ?? ahora,
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
      selectableDayPredicate: (dia) {
        return diasDisponibles[dia] ?? true;
      },
    );
    if (seleccionFecha == null) return;
    final disponible = await estaFechaDisponible(seleccionFecha);
    if (!disponible) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese día ya está completo')),
      );
      return;
    }
    final fechaInicio =
        DateTime(seleccionFecha.year, seleccionFecha.month, seleccionFecha.day);
    final fechaFin = fechaInicio.add(const Duration(days: 1));
    final reservas = await FirebaseFirestore.instance
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: fechaInicio.toIso8601String())
        .where('fecha', isLessThan: fechaFin.toIso8601String())
        .get();
    final horariosOcupados = reservas.docs
        .map((doc) {
          final f = DateTime.tryParse(doc['fecha']);
          return f != null ? TimeOfDay(hour: f.hour, minute: f.minute) : null;
        })
        .whereType<TimeOfDay>()
        .toList();
    final horariosDisponiblesFiltrados = horariosDisponibles.where((h) {
      return !horariosOcupados.any((hora) =>
          hora.hour == h['inicio']!.hour && hora.minute == h['inicio']!.minute);
    }).toList();
    if (horariosDisponiblesFiltrados.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese día ya está completo')),
      );
      return;
    }
    final horarioElegido = await showDialog<Map<String, TimeOfDay>>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Seleccionar horario'),
          children: horariosDisponiblesFiltrados.map((horario) {
            final texto =
                '${horario['inicio']!.format(context)} - ${horario['fin']!.format(context)}';
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, horario),
              child: Text(texto),
            );
          }).toList(),
        );
      },
    );
    if (horarioElegido != null) {
      setState(() {
        fecha = seleccionFecha;
        horaInicio = horarioElegido['inicio'];
        horaFin = horarioElegido['fin'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.reservaId != null ? 'Editar Reserva' : 'Nueva Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: seleccionarFechaYHorario,
                icon: const Icon(Icons.event),
                label: Text(fecha == null ||
                        horaInicio == null ||
                        horaFin == null
                    ? 'Seleccionar Fecha y Horario'
                    : 'Fecha: ${fecha!.day}/${fecha!.month}/${fecha!.year} | ${horaInicio!.format(context)} - ${horaFin!.format(context)}'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: clienteController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del Cliente'),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: combo,
                items: ['COMBINADO', 'SIMPLE', 'COMPLETO']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => combo = val!),
                decoration: const InputDecoration(labelText: 'Combo'),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: estadoPago,
                items: ['Pendiente', 'Confirmado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => estadoPago = val!),
                decoration: const InputDecoration(labelText: 'Estado de pago'),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: observacionesController,
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 3,
              ),
              const SizedBox(height: 36),
              Center(
                child: cargando
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: guardarReserva,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
