import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> crearOActualizarEventoCalendario(String reservaId) async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('crearEventoCalendario');

  try {
    final result = await callable.call({'reservaId': reservaId});
    final data = result.data;

    if (data['success'] == true && data['eventId'] != null) {
      final eventId = data['eventId'];
      await FirebaseFirestore.instance
          .collection('reservas')
          .doc(reservaId)
          .update({'eventId': eventId});

      print(
          '✅ Evento ${data['created'] == true ? 'creado' : 'actualizado'} correctamente con ID: $eventId');
    } else {
      print('⚠️ Error al crear/actualizar el evento: ${data['error']}');
    }
  } catch (e) {
    print('❌ Error llamando la función: $e');
  }
}
