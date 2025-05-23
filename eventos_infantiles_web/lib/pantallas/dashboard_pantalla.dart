import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'dart:html' as html;

class DashboardPantalla extends StatefulWidget {
  const DashboardPantalla({super.key});

  @override
  State<DashboardPantalla> createState() => _DashboardPantallaState();
}

class _DashboardPantallaState extends State<DashboardPantalla> {
  bool mostrarTodasLasReservas = false;
  bool mostrarTodoElStock = false;
  String filtroReservas = 'Recientes'; // O 'Próximas a vencer'
  List<Map<String, dynamic>> reservasVisibles = [];
  // Contador de reservas próximas a vencer en 3 días
  int reservasProximasAVencer = 0;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esEscritorio = ancho >= 800;

    final tituloStyle = GoogleFonts.poppins(
      fontSize: esEscritorio ? 28 : 20,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final cardTituloStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      fontSize: esEscritorio ? 18 : 16,
      color: Colors.black87,
    );
    final cardTextoStyle = GoogleFonts.poppins(
      fontSize: esEscritorio ? 16 : 14,
      color: Colors.grey[800],
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(151, 253, 223, 71),
        elevation: 2,
        title: Row(
          children: [
            Image.asset(
              '../assets/imagen.jpg',
              height: 40,
            ),
            const SizedBox(width: 12),
            Text(
              'Futuros Héroes',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          // StreamBuilder para contar reservas próximas a vencer en 3 días
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('reservas').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(); // nada mientras carga
              }

              final hoy = DateTime.now();
              final tresDiasDespues = hoy.add(const Duration(days: 3));
              final reservas = snapshot.data!.docs;
              final proximasAVencer = reservas.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fechaStr = data['fecha'] ?? '';
                DateTime? fecha = DateTime.tryParse(fechaStr);
                if (fecha == null) return false;
                // La reserva vence si la fecha está entre hoy y 3 días adelante (inclusive)
                return fecha.isAfter(hoy.subtract(const Duration(days: 1))) &&
                    fecha
                        .isBefore(tresDiasDespues.add(const Duration(days: 1)));
              }).length;

              if (proximasAVencer == 0) return const SizedBox();

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active_rounded,
                        color: Colors.black87),
                    onPressed: () {
                      Navigator.pushNamed(context, '/recordatorios');
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      constraints: const BoxConstraints(minWidth: 20),
                      child: Text(
                        '${reservas.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[50],
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color.fromARGB(151, 253, 223, 71), // Amarillo suave
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('../assets/imagen.jpg'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Futuros Héroes',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.add_box_rounded,
              text: 'Nueva Reserva',
              context: context,
              route: '/nueva-reserva',
            ),
            _buildMenuItem(
              icon: Icons.list_alt_rounded,
              text: 'Reservas',
              context: context,
              route: '/reservas',
            ),
            _buildMenuItem(
              icon: Icons.inventory_2_rounded,
              text: 'Stock',
              context: context,
              route: '/stock',
            ),
            _buildMenuItem(
              icon: Icons.calendar_today_rounded,
              text: 'Calendario',
              context: context,
              route: '/calendario',
            ),
            _buildMenuItem(
              icon: Icons.notifications_active_rounded,
              text: 'Recordatorios',
              context: context,
              route: '/recordatorios',
            ),
            _buildMenuItem(
              icon: Icons.settings_rounded,
              text: 'Configuración',
              context: context,
              route: '/configuracion',
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '© 2025 Futuros Héroes',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📅 Reservas', style: tituloStyle),
              Row(
                children: [
                  DropdownButton<String>(
                    value: filtroReservas,
                    style: GoogleFonts.poppins(color: Colors.black87),
                    items: const [
                      DropdownMenuItem(
                        value: 'Recientes',
                        child: Text('Recientes'),
                      ),
                      DropdownMenuItem(
                        value: 'Próximas a vencer',
                        child: Text('Próximas a vencer'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          filtroReservas = value;
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Descargar reservas visibles en PDF',
                    onPressed: reservasVisibles.isEmpty
                        ? null
                        : () => _generarPdf(reservasVisibles),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReservasGrid(cardTituloStyle, cardTextoStyle),
          TextButton(
            onPressed: () {
              setState(() {
                mostrarTodasLasReservas = !mostrarTodasLasReservas;
              });
            },
            child: Text(mostrarTodasLasReservas
                ? 'Ocultar algunas reservas'
                : 'Ver todas las reservas'),
          ),
          const SizedBox(height: 24),
          Text('📦 Ítems de stock recientes', style: tituloStyle),
          const SizedBox(height: 12),
          _buildStockReciente(cardTituloStyle, cardTextoStyle),
          TextButton(
            onPressed: () {
              setState(() {
                mostrarTodoElStock = !mostrarTodoElStock;
              });
            },
            child: Text(mostrarTodoElStock
                ? 'Ocultar algunos ítems'
                : 'Ver todo el stock'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/nueva-reserva'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Reserva'),
        backgroundColor: const Color(0xFFA0D8EF),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required BuildContext context,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: Icon(icon, color: Colors.pinkAccent),
          title: Text(text, style: GoogleFonts.poppins(fontSize: 16)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }

  Widget _buildReservasGrid(TextStyle tituloStyle, TextStyle textoStyle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        DateTime soloFecha(DateTime fecha) {
          return DateTime(fecha.year, fecha.month, fecha.day);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reservas')
              .orderBy('fecha', descending: true)
              .limit(mostrarTodasLasReservas ? 100 : 4)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              reservasVisibles = [];
              return const Text('No hay reservas registradas');
            }

            final hoy = soloFecha(DateTime.now());
            final fechaLimite = hoy.add(const Duration(days: 3));
            final reservasSinFiltrar = snapshot.data!.docs;

            final reservasFiltradas = reservasSinFiltrar.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dynamic fechaRaw = data['fecha'];
              DateTime? fecha;

              if (fechaRaw is Timestamp) {
                fecha = fechaRaw.toDate();
              } else if (fechaRaw is String) {
                fecha = DateTime.tryParse(fechaRaw);
              }

              if (fecha == null) return false;

              if (filtroReservas == 'Próximas a vencer') {
                final fechaSoloDia = soloFecha(fecha);
                return fechaSoloDia
                        .isAfter(hoy.subtract(const Duration(days: 1))) &&
                    fechaSoloDia
                        .isBefore(fechaLimite.add(const Duration(days: 1)));
              }

              return true;
            }).toList();

            // Actualizo la lista para el PDF:
            reservasVisibles = reservasFiltradas.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Map<String, dynamic> copia = Map.from(data);
              copia['id'] = doc.id;
              return copia;
            }).toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reservasFiltradas.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500, // El ancho máximo de cada tarjeta
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio:
                    1.6, // Puedes ajustar este valor a 1.6 o 2 según lo que necesites
              ),
              itemBuilder: (context, index) {
                final data = reservasFiltradas[index].data();
                if (data is! Map<String, dynamic>) {
                  return Card(
                    color: Colors.red.shade100,
                    child: Center(
                      child:
                          Text('Datos inválidos en reserva', style: textoStyle),
                    ),
                  );
                }
                final reserva = data;
                final id = reservasFiltradas[index].id;
                final dynamic fechaRaw = reserva['fecha'];
                DateTime fecha;
                final fechaReserva = reserva['fecha'] is Timestamp
                    ? (reserva['fecha'] as Timestamp).toDate()
                    : DateTime.tryParse(reserva['fecha']) ?? DateTime.now();
                final horario = DateFormat.Hm().format(fechaReserva);

                if (fechaRaw is Timestamp) {
                  fecha = fechaRaw.toDate();
                } else if (fechaRaw is String) {
                  fecha = DateTime.tryParse(fechaRaw) ?? DateTime.now();
                } else {
                  fecha = DateTime.now();
                }

                return GestureDetector(
                  onTap: () {
                    _mostrarOpcionesReserva(context, id, reserva);
                  },
                  child: Card(
                    color: const Color(0xFFA0D8EF),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: ${reserva['cliente'] ?? ''}',
                              style: tituloStyle),
                          const SizedBox(height: 8),
                          Text(
                              'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                              style: textoStyle),
                          Text('Horario: $horario', style: textoStyle),
                          Text('Combo: ${reserva['combo'] ?? ''}',
                              style: textoStyle),
                          Flexible(
                            child: Text(
                              'Observaciones: ${reserva['observaciones'] ?? 'Ninguna'}',
                              style: textoStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('Estado de pago: ${reserva['estadoPago'] ?? ''}',
                              style: textoStyle),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _generarPdf(List<Map<String, dynamic>> reservas) async {
    final pdf = pw.Document();

    final titulo = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
    final subtitulo =
        pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    const normal = pw.TextStyle(fontSize: 14);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text('Listado de Reservas', style: titulo),
            pw.SizedBox(height: 20),
            ...reservas.map((reserva) {
              DateTime fecha;
              final dynamic fechaRaw = reserva['fecha'];
              if (fechaRaw is Timestamp) {
                fecha = fechaRaw.toDate();
              } else if (fechaRaw is String) {
                fecha = DateTime.tryParse(fechaRaw) ?? DateTime.now();
              } else {
                fecha = DateTime.now();
              }
              final fechaReserva = reserva['fecha'] is Timestamp
                  ? (reserva['fecha'] as Timestamp).toDate()
                  : DateTime.tryParse(reserva['fecha']) ?? DateTime.now();

              final horario = DateFormat.Hm().format(fechaReserva);
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.blue50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Reserva ID: ${reserva['id'] ?? ''}',
                        style: subtitulo),
                    pw.SizedBox(height: 6),
                    pw.Text('Cliente: ${reserva['cliente'] ?? ''}',
                        style: normal),
                    pw.Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                        style: normal),
                    pw.Text('Horario: $horario', style: normal),
                    pw.Text('Combo: ${reserva['combo'] ?? ''}', style: normal),
                    pw.Text(
                        'Observaciones: ${reserva['observaciones'] ?? 'Ninguna'}',
                        style: normal),
                    pw.Text('Estado de pago: ${reserva['estadoPago'] ?? ''}',
                        style: normal),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    // Para Flutter web: abrir el pdf en otra pestaña
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  void _mostrarOpcionesReserva(
      BuildContext contextPadre, String id, Map<String, dynamic> reserva) {
    showModalBottomSheet(
      context: contextPadre,
      builder: (contextModal) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar reserva'),
              onTap: () {
                Navigator.pop(contextModal);
                Navigator.pushNamed(
                  contextPadre,
                  '/editar-reserva',
                  arguments: {
                    'reservaId': id,
                    'reservaDatos': reserva,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Eliminar reserva'),
              onTap: () async {
                Navigator.pop(contextModal);
                final confirmar = await showDialog<bool>(
                  context: contextPadre,
                  builder: (contextDialog) => AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content:
                        const Text('¿Seguro que querés eliminar esta reserva?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(contextDialog, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(contextDialog, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (!mounted) return;

                if (confirmar == true) {
                  await FirebaseFirestore.instance
                      .collection('reservas')
                      .doc(id)
                      .delete();
                  if (!mounted) return;
                  // Usa contextPadre para el SnackBar, no el contextModal
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(contextPadre).showSnackBar(
                    const SnackBar(content: Text('Reserva eliminada')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStockReciente(TextStyle tituloStyle, TextStyle textoStyle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stock')
              .orderBy('ultimaModificacion', descending: true)
              .limit(mostrarTodoElStock ? 100 : 4)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text(
                  'No hay actualizaciones recientes en el stock.');
            }

            final items = snapshot.data!.docs;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final data = items[index].data();
                if (data is! Map<String, dynamic>) {
                  return Card(
                    color: const Color.fromARGB(167, 255, 107, 129),
                    child: Center(
                      child:
                          Text('Datos inválidos en stock', style: textoStyle),
                    ),
                  );
                }

                final item = data;
                return Card(
                  color: const Color.fromARGB(167, 255, 107, 129),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nombre: ${item['nombre'] ?? ''}',
                            style: tituloStyle),
                        const SizedBox(height: 8),
                        Text(
                            'Categoría: ${item['categoria'] ?? 'Sin categoría'}',
                            style: textoStyle),
                        Text('Cantidad: ${item['cantidad'] ?? 0}',
                            style: textoStyle),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
