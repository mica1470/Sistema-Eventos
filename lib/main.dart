import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pantallas/login_pantalla.dart';
import 'pantallas/registro_pantalla.dart';
import 'pantallas/dashboard_pantalla.dart'; // nuevo import
import 'pantallas/reservaspantalla.dart'; // nuevo import
import 'pantallas/nueva_reserva_pantalla.dart'; // nuevo import
import 'pantallas/stock_pantalla.dart';
import 'pantallas/recordatorios_pantalla.dart';
import 'pantallas/configuracion_pantalla.dart';
import 'pantallas/calendario_pantalla.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EventosInfantilesApp());
}

class EventosInfantilesApp extends StatelessWidget {
  const EventosInfantilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futuros Heroes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFDE047), // amarillo suave
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA0D8EF), // celeste claro
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPantalla(),
        '/registro': (context) => const RegistroPantalla(),
        '/dashboard': (context) => const DashboardPantalla(),
        '/reservas': (context) => const ReservasPantalla(),
        '/nueva-reserva': (context) => const NuevaReservaPantalla(),
        '/editar-reserva': (context) {
          final settings = ModalRoute.of(context)!.settings;
          return NuevaReservaPantalla.fromRouteSettings(settings);
        },
        '/recordatorios': (context) => const RecordatoriosPantalla(),
        '/stock': (context) => const StockPantalla(),
        '/calendario': (context) => const CalendarioPantalla(),
        '/configuracion': (context) => const ConfiguracionPantalla(),
      },
    );
  }
}
