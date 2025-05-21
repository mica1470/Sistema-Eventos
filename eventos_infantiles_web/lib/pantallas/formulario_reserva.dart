import 'package:flutter/material.dart';
import 'servicio_reservas.dart';

class FormularioReserva extends StatefulWidget {
  final ServicioReservas servicioReservas;
  final Map<String, dynamic>? reservaExistente;
  final String? reservaId;

  const FormularioReserva({
    super.key,
    required this.servicioReservas,
    this.reservaExistente,
    this.reservaId,
  });

  @override
  State<FormularioReserva> createState() => _FormularioReservaState();
}

class _FormularioReservaState extends State<FormularioReserva> {
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

    cargarDiasDisponibles();
  }

  Future<void> cargarDiasDisponibles() async {
    final dias = await widget.servicioReservas.cargarDiasDisponibles();
    setState(() {
      diasDisponibles = dias;
    });
  }

  Future<void> guardarReserva() async {
    if (!formKey.currentState!.validate() ||
        fecha == null ||
        horaInicio == null ||
        horaFin == null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('La hora de fin debe ser posterior a la hora de inicio')),
      );
      return;
    }

    setState(() => cargando = true);

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

    try {
      await widget.servicioReservas.guardarReserva(
          reservaId: widget.reservaId, datosReserva: datosReserva);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => cargando = false);
    }
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

    final disponible =
        await widget.servicioReservas.estaFechaDisponible(seleccionFecha);
    if (!disponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese día ya está completo')),
      );
      return;
    }

    final horariosDisponiblesFiltrados = await widget.servicioReservas
        .obtenerHorariosDisponibles(seleccionFecha, horariosDisponibles);

    if (horariosDisponiblesFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay horarios disponibles en ese día')),
      );
      return;
    }

    final horarioSeleccionado = await showDialog<Map<String, TimeOfDay>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccione horario'),
        children: horariosDisponiblesFiltrados.map((horario) {
          final inicio = horario['inicio']!;
          final fin = horario['fin']!;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, horario),
            child: Text('${inicio.format(context)} - ${fin.format(context)}'),
          );
        }).toList(),
      ),
    );

    if (horarioSeleccionado == null) return;

    setState(() {
      fecha = seleccionFecha;
      horaInicio = horarioSeleccionado['inicio'];
      horaFin = horarioSeleccionado['fin'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return cargando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: clienteController,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  TextFormField(
                    controller: telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: seleccionarFechaYHorario,
                    child: Text(fecha == null || horaInicio == null
                        ? 'Seleccionar fecha y horario'
                        : 'Fecha: ${fecha!.day}/${fecha!.month}/${fecha!.year} - '
                            '${horaInicio!.format(context)} a ${horaFin!.format(context)}'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: combo,
                    decoration: const InputDecoration(labelText: 'Combo'),
                    items: ['SIMPLE', 'MEDIO', 'FULL']
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => combo = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: estadoPago,
                    decoration:
                        const InputDecoration(labelText: 'Estado de Pago'),
                    items: ['Pendiente', 'Pagado', 'Cancelado']
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => estadoPago = value);
                      }
                    },
                  ),
                  TextFormField(
                    controller: observacionesController,
                    decoration:
                        const InputDecoration(labelText: 'Observaciones'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: guardarReserva,
                    child: const Text('Guardar Reserva'),
                  ),
                ],
              ),
            ),
          );
  }
}
