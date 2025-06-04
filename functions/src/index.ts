// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { google } from "googleapis";
import * as pubsub from "firebase-functions/v1/pubsub";
// Inicializa Firebase Admin SDK

admin.initializeApp();
// Configura el ID del calendario de Google
const calendarId = "futurosheroes.pelotero@gmail.com"; 

const auth = new google.auth.GoogleAuth({
    credentials: require("../credentials/calendar-credentials.json"),
    scopes: ["https://www.googleapis.com/auth/calendar"],
  });
  
exports.crearEventoCalendario = functions.https.onCall(
    async (request: functions.https.CallableRequest<{ reservaId: string }>) => {
      const calendar = google.calendar({ version: "v3", auth });
      const reservaId = request.data.reservaId;
  
      if (!reservaId) {
        return { success: false, error: "Falta el ID de la reserva" };
      }
  
      try {
        const reservaRef = admin.firestore().collection("reservas").doc(reservaId);
        const reservaDoc = await reservaRef.get();
  
        if (!reservaDoc.exists) {
          return { success: false, error: "Reserva no encontrada" };
        }
  
        const reserva = reservaDoc.data();
  
        if (!reserva) {
          return { success: false, error: "Datos de reserva inválidos" };
        }
  
        const cliente = reserva.cliente ?? "Sin nombre";
        const fechaInicio = reserva.fecha;
        const horaFin = reserva.horaFin;
  
        if (!fechaInicio || !horaFin) {
          return { success: false, error: "Faltan datos de fecha u hora" };
        }
  
        const fechaFin = `${fechaInicio.split("T")[0]}T${horaFin}:00-03:00`;
  
        const evento = {
          summary: `Reserva: ${cliente}`,
          description: `Adulto Responsable: ${reserva['adultoResponsable'] ?? 'Sin nombre'}\nHorario: ${new Date(fechaInicio).toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' })}\nTelefono: ${reserva['telefono'] ?? ''}\nCantidad de niños: ${reserva['cantidadNinos'] ?? '-'}\nCantidad de adultos: ${reserva['cantidadAdultos'] ?? '-'}\nCombo Lunch Adultos: ${reserva['comboLunchAdultos'] ?? '-'} - Cantidad: ${reserva['cantidadLunchAdultos']} \nCombo Dulce Adultos: ${reserva['comboDulceAdultos'] ?? '-'} - Cantidad: ${reserva['cantidadDulceAdultos']} \nPiñata: ${reserva['pinata'] ?? '-'}\nEstado de pago:  ${reserva['estadoPago']}\nImporte: ${reserva['importe'] ?? '-'} \nDescripcion de pago: ${reserva['pagos'] ?? '-'}\nSolicitud Especial: ${(reserva['solicitudEspecial'] == null || reserva['solicitudEspecial'].toString().trim() === '') ? 'Ninguna' : reserva['solicitudEspecial']}`,
          start: {
            dateTime: fechaInicio,
            timeZone: "America/Argentina/Buenos_Aires",
          },
          end: {
            dateTime: fechaFin,
            timeZone: "America/Argentina/Buenos_Aires",
          },
        };
  
        let eventId: string | undefined = reserva.eventId;
  
        if (eventId) {
          // Si existe, intentamos actualizar
          try {
            const updateResponse = await calendar.events.update({
              calendarId,
              eventId,
              requestBody: evento,
            });
            return { success: true, eventId: updateResponse.data.id, updated: true };
          } catch (error: any) {
            // Si falla la actualización (por ejemplo si el evento fue eliminado en Google Calendar)
            console.warn("No se pudo actualizar el evento, se creará uno nuevo:", error.message);
          }
        }
  
        // Crear nuevo evento
        const createResponse = await calendar.events.insert({
          calendarId,
          requestBody: evento,
        });
  
        eventId = createResponse.data.id ?? undefined;
  
        // Guardar el eventId en Firestore
        await reservaRef.update({ eventId });
  
        return { success: true, eventId, created: true };
      } catch (error: any) {
        console.error("Error al crear/actualizar evento:", error);
        return { success: false, error: error.message ?? "Error desconocido" };
      }
    }
  );
 
export const eliminarReservasVencidas = pubsub
  .schedule('every day 00:00')
  .timeZone('America/Argentina/Buenos_Aires')
    .onRun(async () => {
    const db = admin.firestore();
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0); // Ignora la hora: solo fecha
  
    const snapshot = await db.collection('reservas')
      .where('fecha', '<', hoy.toISOString())
      .get();
  
    const batch = db.batch();
  
    snapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });
  
    await batch.commit();
  
    console.log(`Reservas vencidas eliminadas: ${snapshot.size}`);
    return null;
    });


    export const eliminarEventoCalendario = functions.https.onCall(
      async (request: functions.https.CallableRequest<{ reservaId: string }>) => {
        const calendar = google.calendar({ version: "v3", auth });
        const reservaId = request.data.reservaId;
    
        if (!reservaId) {
          return { success: false, error: "Falta el ID de la reserva" };
        }
    
        try {
          const reservaRef = admin.firestore().collection("reservas").doc(reservaId);
          const reservaDoc = await reservaRef.get();
    
          if (!reservaDoc.exists) {
            return { success: false, error: "Reserva no encontrada" };
          }
    
          const reserva = reservaDoc.data();
    
          if (!reserva || !reserva.eventId) {
            return { success: false, error: "Evento no encontrado o no existe" };
          }
    
          await calendar.events.delete({
            calendarId,
            eventId: reserva.eventId,
          });
    
          // Eliminar eventId del documento Firestore
          await reservaRef.update({ eventId: admin.firestore.FieldValue.delete() });
    
          return { success: true, message: "Evento eliminado correctamente" };
        } catch (error: any) {
          console.error("Error al eliminar evento:", error);
          return { success: false, error: error.message ?? "Error desconocido" };
        }
      }
    );
    