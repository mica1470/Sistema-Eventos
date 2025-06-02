// functions/src/index.ts
import * as functions from "firebase-functions";
import {google} from "googleapis";
import * as admin from "firebase-admin";
import * as path from "path";
import * as fs from "fs";

admin.initializeApp();

const SCOPES = ["https://www.googleapis.com/auth/calendar"];

const calendarId = "futurosheroes.pelotero@gmail.com"; // <- el correo del calendario

const getAuth = () => {
  const keyPath = path.join(__dirname, "../credentials/calendar-credentials.json");
  const keyFile = fs.readFileSync(keyPath, "utf-8");
  const credentials = JSON.parse(keyFile);

  const auth = new google.auth.JWT(
    credentials.client_email,
    undefined,
    credentials.private_key,
    SCOPES
  );

  return auth;
};

exports.crearEventoCalendario = functions.https.onCall(async (data, context) => {
  const auth = getAuth();
  const calendar = google.calendar({version: "v3", auth});
  // Datos manuales para prueba
  const cliente = "Juan Pérez";
  const adultoResponsable = "María López";
  const telefono = "123456789";
  const fechaInicio = "2025-06-10T10:00:00-03:00";
  const fechaFin = "2025-06-10T12:00:00-03:00";
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

  try {
    const response = await calendar.events.insert({
      calendarId,
      requestBody: evento,
    });

    return {success: true, eventId: response.data.id};
  } catch (error: any) {
    console.error("Error al crear evento:", error);
    return {success: false, error: error.message};
  }
});
