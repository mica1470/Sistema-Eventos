import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pantallas/login_pantalla.dart';
import 'pantallas/dashboard_pantalla.dart'; // nuevo import
import 'firebase_options.dart';
import 'pantallas/nueva_reserva_pantalla.dart'; // nuevo import
import 'pantallas/stock_pantalla.dart';
import 'pantallas/configuracion_pantalla.dart';

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
      title: 'Eventos Infantiles',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
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
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPantalla(),
        '/dashboard': (context) => const DashboardPantalla(),
        '/nueva-reserva': (context) => const NuevaReservaPantalla(),
        '/editar-reserva': (context) {
          final settings = ModalRoute.of(context)!.settings;
          return NuevaReservaPantalla.fromRouteSettings(settings);
        },
        '/stock': (context) => const StockPantalla(),
        '/configuracion': (context) => const ConfiguracionPantalla(),
      },
    );
  }
}
