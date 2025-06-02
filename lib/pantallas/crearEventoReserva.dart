import 'package:cloud_functions/cloud_functions.dart';

Future<void> crearEventoCalendario(String reservaId) async {
  try {
    final callable =
        FirebaseFunctions.instance.httpsCallable('crearEventoCalendario');
    final result = await callable.call({'reservaId': reservaId});
    if (result.data['success'] == true) {
      print("Evento creado con ID: ${result.data['eventId']}");
    } else {
      print("Error al crear evento: ${result.data['error']}");
    }
  } catch (e) {
    print("Excepción al llamar función: $e");
  }
}
