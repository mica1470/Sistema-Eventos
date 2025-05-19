import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConfiguracionPantalla extends StatefulWidget {
  const ConfiguracionPantalla({super.key});

  @override
  State<ConfiguracionPantalla> createState() => _ConfiguracionPantallaState();
}

class _ConfiguracionPantallaState extends State<ConfiguracionPantalla> {
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController mensajePersonalizadoController =
      TextEditingController();
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
        final partes = (data['horaEnvio'] as String).split(':');
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

  Future<void> probarEnvio() async {
    final accountSid = 'AC2d7b0cbd60a938acbf133a2e2382bce5';
    final authToken = tokenController.text.trim();
    final mensaje = mensajePersonalizadoController.text.trim().isNotEmpty
        ? mensajePersonalizadoController.text.trim()
        : textoRecordatorioController.text.trim();

    final uri = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}';

    final response = await http.post(
      uri,
      headers: {
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'To': 'whatsapp:+5493884470452',
        'From': 'whatsapp:+14155238886',
        'Body': mensaje,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje enviado con éxito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: ${response.body}')),
      );
    }
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
              obscureText: true, // 🔒 oculta el token como una contraseña
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mensajePersonalizadoController,
              decoration: const InputDecoration(
                labelText: 'Mensaje personalizado (solo para prueba)',
                hintText: 'Este mensaje se enviará si lo completás',
              ),
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
