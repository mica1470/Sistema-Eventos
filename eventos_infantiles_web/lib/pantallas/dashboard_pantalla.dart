import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardPantalla extends StatefulWidget {
  const DashboardPantalla({super.key});

  @override
  State<DashboardPantalla> createState() => _DashboardPantallaState();
}

class _DashboardPantallaState extends State<DashboardPantalla> {
  bool mostrarTodasLasReservas = false;
  bool mostrarTodoElStock = false;
  String filtroReservas = 'Recientes'; // O 'Próximas a vencer'

  // Contador de reservas próximas a vencer en 3 días
  int reservasProximasAVencer = 0;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esEscritorio = ancho >= 800;

    final tituloStyle = TextStyle(
      fontSize: esEscritorio ? 28 : 20,
      fontWeight: FontWeight.bold,
    );
    final cardTituloStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: esEscritorio ? 20 : 16,
    );
    final cardTextoStyle = TextStyle(
      fontSize: esEscritorio ? 18 : 14,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Infantiles'),
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

              // Filtrar reservas con fecha dentro de los próximos 3 días
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
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      // Navegar a la pantalla de recordatorios o mostrar diálogo
                      Navigator.pushNamed(context, '/recordatorios');
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$proximasAVencer',
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration:
                  BoxDecoration(color: Color.fromARGB(129, 214, 165, 223)),
              child: Text('Menú',
                  style: TextStyle(
                      color: Color.fromARGB(255, 51, 46, 46), fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Nueva Reserva'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/nueva-reserva');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Stock'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/stock');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Recordatorios'),
              onTap: () {
                Navigator.pushNamed(context, '/recordatorios');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/configuracion');
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('📅 Reservas recientes', style: tituloStyle),
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
        onPressed: () {
          Navigator.pushNamed(context, '/nueva-reserva');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Reserva'),
      ),
    );
  }

  Widget _buildReservasGrid(TextStyle tituloStyle, TextStyle textoStyle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reservas')
              .orderBy('fecha', descending: true)
              .limit(mostrarTodasLasReservas ? 100 : 4)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No hay reservas registradas');
            }

            final reservas = snapshot.data!.docs;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reservas.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final data = reservas[index].data();
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
                final id = reservas[index].id;

                final fechaStr = reserva['fecha'] ?? '';
                DateTime fecha = DateTime.tryParse(fechaStr) ?? DateTime.now();

                return GestureDetector(
                  onTap: () {
                    _mostrarOpcionesReserva(id, reserva);
                  },
                  child: Card(
                    color: Colors.blue[50],
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: ${reserva['cliente'] ?? ''}',
                              style: tituloStyle),
                          const SizedBox(height: 8),
                          Text(
                              'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                              style: textoStyle),
                          Text('Combo: ${reserva['combo'] ?? ''}',
                              style: textoStyle),
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

  void _mostrarOpcionesReserva(String id, Map<String, dynamic> reserva) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar reserva'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
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
                Navigator.pop(context);
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content:
                        const Text('¿Seguro que querés eliminar esta reserva?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  await FirebaseFirestore.instance
                      .collection('reservas')
                      .doc(id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
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
                    color: Colors.red.shade100,
                    child: Center(
                      child:
                          Text('Datos inválidos en stock', style: textoStyle),
                    ),
                  );
                }

                final item = data;
                return Card(
                  color: Colors.amber[50],
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
