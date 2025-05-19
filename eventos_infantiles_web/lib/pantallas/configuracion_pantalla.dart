import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConfiguracionPantalla extends StatefulWidget {
  const ConfiguracionPantalla({super.key});

  @override
  State<ConfiguracionPantalla> createState() => _ConfiguracionPantallaState();
}

class _ConfiguracionPantallaState extends State<ConfiguracionPantalla> {
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController textoRecordatorioController =
      TextEditingController();
  TimeOfDay horaEnvio = const TimeOfDay(hour: 9, minute: 0);
  String diaEnvio = '1 día antes';

  bool cargando = false;

  final List<String> opcionesDias = [
    '1 día antes',
    '2 días antes',
    '3 días antes',
  ];

  @override
  void initState() {
    super.initState();
    cargarConfiguracion();
  }

  Future<void> cargarConfiguracion() async {
    final doc = await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('bot')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      tokenController.text = data['token'] ?? '';
      textoRecordatorioController.text = data['textoRecordatorio'] ?? '';
      if (data['horaEnvio'] != null) {
        final hora = data['horaEnvio'] as String;
        final partes = hora.split(':');
        if (partes.length == 2) {
          horaEnvio = TimeOfDay(
              hour: int.parse(partes[0]), minute: int.parse(partes[1]));
        }
      }
      diaEnvio = data['diaEnvio'] ?? diaEnvio;
      setState(() {});
    }
  }

  Future<void> guardarConfiguracion() async {
    setState(() => cargando = true);
    await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('bot')
        .set({
      'token': tokenController.text.trim(),
      'textoRecordatorio': textoRecordatorioController.text.trim(),
      'horaEnvio': '${horaEnvio.hour}:${horaEnvio.minute}',
      'diaEnvio': diaEnvio,
    });
    setState(() => cargando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  Future<void> seleccionarHora() async {
    final seleccion =
        await showTimePicker(context: context, initialTime: horaEnvio);
    if (seleccion != null) {
      setState(() => horaEnvio = seleccion);
    }
  }

  void probarEnvio() {
    // Aquí agregar la lógica para probar el envío (opcional)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prueba de envío ejecutada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(labelText: 'Token / API Key'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textoRecordatorioController,
              decoration:
                  const InputDecoration(labelText: 'Texto del recordatorio'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Hora para enviar:'),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: seleccionarHora,
                  child: Text('${horaEnvio.format(context)}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: diaEnvio,
              items: opcionesDias
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => diaEnvio = val);
              },
              decoration: const InputDecoration(labelText: 'Día para enviar'),
            ),
            const SizedBox(height: 32),
            cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: guardarConfiguracion,
                    child: const Text('Guardar Configuración'),
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: probarEnvio,
              child: const Text('Probar envío'),
            ),
          ],
        ),
      ),
    );
  }
}
