import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServicioReservas {
  final CollectionReference reservasRef =
      FirebaseFirestore.instance.collection('reservas');

  Future<Map<DateTime, bool>> cargarDiasDisponibles() async {
    final ahora = DateTime.now();

    final snapshot = await reservasRef
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

    return nuevosDias;
  }

  Future<void> guardarReserva({
    required String? reservaId,
    required Map<String, dynamic> datosReserva,
  }) async {
    if (reservaId != null) {
      await reservasRef.doc(reservaId).update(datosReserva);
    } else {
      await reservasRef.add({
        ...datosReserva,
        'creado': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> estaFechaDisponible(DateTime date) async {
    final fechaInicio = DateTime(date.year, date.month, date.day);
    final fechaFin = fechaInicio.add(const Duration(days: 1));

    final reservas = await reservasRef
        .where('fecha', isGreaterThanOrEqualTo: fechaInicio.toIso8601String())
        .where('fecha', isLessThan: fechaFin.toIso8601String())
        .get();

    return reservas.docs.length < 2;
  }

  Future<List<Map<String, TimeOfDay>>> obtenerHorariosDisponibles(
      DateTime fecha, List<Map<String, TimeOfDay>> horariosBase) async {
    final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fechaFin = fechaInicio.add(const Duration(days: 1));

    final reservas = await reservasRef
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

    final horariosDisponiblesFiltrados = horariosBase.where((h) {
      return !horariosOcupados.any((hora) =>
          hora.hour == h['inicio']!.hour && hora.minute == h['inicio']!.minute);
    }).toList();

    return horariosDisponiblesFiltrados;
  }
}
