// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { google } from "googleapis";


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
        const reservaDoc = await admin.firestore().collection("reservas").doc(reservaId).get();
  
        if (!reservaDoc.exists) {
          console.error("Reserva no encontrada con ID:", reservaId);
          return { success: false, error: "Reserva no encontrada" };
        }
  
        const reserva = reservaDoc.data();
  
        if (!reserva) {
          console.error("Datos de reserva indefinidos");
          return { success: false, error: "Datos de reserva inválidos" };
        }
  
        const cliente = reserva.cliente ?? "Sin nombre";
        const adultoResponsable = reserva.adultoResponsable ?? "Sin responsable";
        const telefono = reserva.telefono ?? "Sin teléfono";
        const fechaInicio = reserva.fecha;
        const horaFin = reserva.horaFin;
  
        if (!fechaInicio || !horaFin) {
          return { success: false, error: "Faltan datos de fecha u hora" };
        }
  
        const fechaFin = `${fechaInicio.split("T")[0]}T${horaFin}:00-03:00`;
  
        const evento = {
          summary: `Reserva: ${cliente}`,
          description: `Adulto Responsable: ${adultoResponsable}\nTeléfono: ${telefono}`,
          start: {
            dateTime: fechaInicio,
            timeZone: "America/Argentina/Buenos_Aires",
          },
          end: {
            dateTime: fechaFin,
            timeZone: "America/Argentina/Buenos_Aires",
          },
        };
  
        const response = await calendar.events.insert({
          calendarId,
          requestBody: evento,
        });
  
        return { success: true, eventId: response.data.id };
      } catch (error: any) {
        console.error("Error al crear evento:", error);
        return { success: false, error: error.message ?? "Error desconocido" };
      }
    }
  );
  
  