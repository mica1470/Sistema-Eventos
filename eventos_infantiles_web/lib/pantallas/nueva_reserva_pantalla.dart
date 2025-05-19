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

  DateTime? fecha;
  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;
  String combo = 'SIMPLE';
  String estadoPago = 'Pendiente';

  bool cargando = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  Future<void> seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: fecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (seleccion != null) setState(() => fecha = seleccion);
  }

  Future<void> seleccionarHoraInicio() async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: horaInicio ?? TimeOfDay.now(),
    );
    if (seleccion != null) setState(() => horaInicio = seleccion);
  }

  Future<void> seleccionarHoraFin() async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: horaFin ?? TimeOfDay.now(),
    );
    if (seleccion != null) setState(() => horaFin = seleccion);
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
            children: [
              ElevatedButton(
                onPressed: seleccionarFecha,
                child: Text(fecha == null
                    ? 'Seleccionar Fecha'
                    : 'Fecha: ${fecha!.day}/${fecha!.month}/${fecha!.year}'),
              ),
              ElevatedButton(
                onPressed: seleccionarHoraInicio,
                child: Text(horaInicio == null
                    ? 'Hora Inicio'
                    : 'Inicio: ${horaInicio!.format(context)}'),
              ),
              ElevatedButton(
                onPressed: seleccionarHoraFin,
                child: Text(horaFin == null
                    ? 'Hora Fin'
                    : 'Fin: ${horaFin!.format(context)}'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: clienteController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del Cliente'),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              DropdownButtonFormField<String>(
                value: combo,
                items: ['COMBINADO', 'SIMPLE', 'COMPLETO']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => combo = val!),
                decoration: const InputDecoration(labelText: 'Combo'),
              ),
              DropdownButtonFormField<String>(
                value: estadoPago,
                items: ['Pendiente', 'Confirmado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => estadoPago = val!),
                decoration: const InputDecoration(labelText: 'Estado de pago'),
              ),
              TextFormField(
                controller: observacionesController,
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: guardarReserva,
                      child: Text(widget.reservaId != null
                          ? 'Actualizar Reserva'
                          : 'Crear Reserva'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
