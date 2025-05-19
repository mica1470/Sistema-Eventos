import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NuevaReservaPantalla extends StatefulWidget {
  const NuevaReservaPantalla({super.key});

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
  String combo = 'TRUGUITO';
  String estadoPago = 'pendiente';

  bool cargando = false;

  Future<void> guardarReserva() async {
    if (!formKey.currentState!.validate() ||
        fecha == null ||
        horaInicio == null ||
        horaFin == null) return;

    setState(() => cargando = true);

    try {
      final fechaEvento = DateTime(
        fecha!.year,
        fecha!.month,
        fecha!.day,
        horaInicio!.hour,
        horaInicio!.minute,
      );

      await FirebaseFirestore.instance.collection('reservas').add({
        'cliente': clienteController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'combo': combo,
        'estadoPago': estadoPago,
        'fecha': fechaEvento.toIso8601String(),
        'horaFin': '${horaFin!.hour}:${horaFin!.minute}',
        'observaciones': observacionesController.text.trim(),
        'creado': FieldValue.serverTimestamp(),
      });

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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (seleccion != null) setState(() => fecha = seleccion);
  }

  Future<void> seleccionarHoraInicio() async {
    final seleccion =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (seleccion != null) setState(() => horaInicio = seleccion);
  }

  Future<void> seleccionarHoraFin() async {
    final seleccion =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (seleccion != null) setState(() => horaFin = seleccion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Reserva')),
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
                items: ['TRUGUITO', 'SIMPLE', 'COMPLETO']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => combo = val!),
                decoration: const InputDecoration(labelText: 'Combo'),
              ),
              DropdownButtonFormField<String>(
                value: estadoPago,
                items: ['pendiente', 'confirmado']
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
                      child: const Text('Guardar Reserva'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
