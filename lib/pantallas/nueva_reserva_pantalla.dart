import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NuevaReservaPantalla extends StatefulWidget {
  final Map<String, dynamic>? reservaExistente;
  final String? reservaId;
  const NuevaReservaPantalla(
      {super.key, this.reservaExistente, this.reservaId});
  factory NuevaReservaPantalla.fromRouteSettings(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    return NuevaReservaPantalla(
      reservaId: args != null ? args['reservaId'] as String? : null,
      reservaExistente:
          args != null ? args['reservaDatos'] as Map<String, dynamic>? : null,
    );
  }
  @override
  State<NuevaReservaPantalla> createState() => _NuevaReservaPantallaState();
}

class _NuevaReservaPantallaState extends State<NuevaReservaPantalla> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController adultoResponsableController =
      TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController cantidadNinosController = TextEditingController();
  final TextEditingController cantidadAdultosController =
      TextEditingController();
  final TextEditingController comboLunchAdultosController =
      TextEditingController();
  final TextEditingController comboDulceAdultosController =
      TextEditingController();
  final TextEditingController solicitudEspecialController =
      TextEditingController();
  String pinata = 'No';
  Map<DateTime, bool> diasDisponibles = {};
  DateTime? fecha;
  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;
  String estadoPago = 'Pendiente';
  List<String> horariosOcupados = [];
  List<String> combos = []; // Importante que esté vacío al inicio
  bool cargando = false;
  List<String> combosLunchAdultos = [];
  List<String> combosDulceAdultos = [];
  String? comboLunchAdultosSeleccionado;
  String? comboDulceAdultosSeleccionado;

  final List<Map<String, TimeOfDay>> horariosDisponibles = [
    {
      'inicio': const TimeOfDay(hour: 13, minute: 0),
      'fin': const TimeOfDay(hour: 16, minute: 0),
    },
    {
      'inicio': const TimeOfDay(hour: 17, minute: 0),
      'fin': const TimeOfDay(hour: 20, minute: 0),
    },
  ];

  @override
  @override
  void initState() {
    super.initState();
    cargarDiasDisponibles();

    if (widget.reservaExistente != null) {
      final r = widget.reservaExistente!;
      clienteController.text = r['cliente'] ?? '';
      adultoResponsableController.text = r['adultoResponsable'] ?? '';
      telefonoController.text = r['telefono'] ?? '';
      cantidadNinosController.text = r['cantidadNinos']?.toString() ?? '';
      cantidadAdultosController.text = r['cantidadAdultos']?.toString() ?? '';
      comboLunchAdultosSeleccionado = r['comboLunchAdultos'] ?? '';
      comboDulceAdultosSeleccionado = r['comboDulceAdultos'] ?? '';
      solicitudEspecialController.text = r['solicitudEspecial'] ?? '';
      pinata = r['pinata'] ?? 'No';
      estadoPago = r['estadoPago'] ?? 'Pendiente';
      final fechaStr = r['fecha'] ?? '';
      fecha = DateTime.tryParse(fechaStr);
      if (fecha != null) {
        horaInicio = TimeOfDay(hour: fecha!.hour, minute: fecha!.minute);
      }
      final horaFinStr = r['horaFin'] ?? '00:00';
      final partes = horaFinStr.split(':');
      if (partes.length == 2) {
        horaFin = TimeOfDay(
          hour: int.tryParse(partes[0]) ?? 0,
          minute: int.tryParse(partes[1]) ?? 0,
        );
      }
    }
    cargarCombosDesdePrefs(
        'combosLunchAdultos', (lista) => combosLunchAdultos = lista);
    cargarCombosDesdePrefs(
        'combosDulceAdultos', (lista) => combosDulceAdultos = lista);
  }

  Future<void> cargarCombosDesdePrefs(
      String key, void Function(List<String>) setLista) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(key);
    setState(() {
      final opciones = lista ?? ['Agregar nuevo'];
      if (!opciones.contains('Agregar nuevo')) {
        opciones.add('Agregar nuevo');
      }
      setLista(opciones);
    });
  }

  void agregarNuevoCombo(
    String prefsKey,
    List<String> lista,
    void Function(String) onNuevoValor,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar nueva opción'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nueva opción'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevo = controller.text.trim();
              if (nuevo.isNotEmpty) {
                setState(() {
                  lista.insert(lista.length - 1, nuevo);
                  onNuevoValor(nuevo); // Actualiza el seleccionado
                });

                final prefs = await SharedPreferences.getInstance();
                prefs.setStringList(prefsKey,
                    lista.where((e) => e != 'Agregar nuevo').toList());

                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  DateTime normalizarFecha(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  DateTime? obtenerPrimeraFechaDisponible(Map<DateTime, bool> diasDisponibles) {
    final ahora = normalizarFecha(DateTime.now());
    for (int i = 0; i <= 365; i++) {
      final dia = ahora.add(Duration(days: i));
      final diaNormalizado = normalizarFecha(dia);
      if (diasDisponibles[diaNormalizado] == true) {
        return diaNormalizado;
      }
    }
    return null;
  }

  Future<void> cargarDiasDisponibles() async {
    final ahora = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: ahora.toIso8601String())
        .get();
    final conteoPorDia = <DateTime, Set<String>>{};

    for (var doc in snapshot.docs) {
      final fechaReserva = DateTime.tryParse(doc['fecha']);
      if (fechaReserva == null) continue;
      final horaInicio =
          TimeOfDay(hour: fechaReserva.hour, minute: fechaReserva.minute);

      final dia =
          DateTime(fechaReserva.year, fechaReserva.month, fechaReserva.day);

      // Representar el horario como string para compararlo fácilmente
      final horarioStr = '${horaInicio.hour}:${horaInicio.minute}';

      conteoPorDia[dia] = conteoPorDia[dia] ?? <String>{};
      conteoPorDia[dia]!.add(horarioStr);
    }

    final nuevosDias = <DateTime, bool>{};
    for (int i = 0; i <= 365; i++) {
      final dia = normalizarFecha(ahora.add(Duration(days: i)));
      final ocupados = conteoPorDia[dia] ?? <String>{};
      nuevosDias[dia] = ocupados.length < horariosDisponibles.length;
    }
    if (!mounted) return;
    setState(() {
      diasDisponibles = nuevosDias;
    });
  }

  Future<void> guardarReserva() async {
    if (!formKey.currentState!.validate()) {
      // Si el formulario no es válido, no hacemos nada.
      return;
    }
    if (fecha == null || horaInicio == null || horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, seleccione fecha y horario')),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final fechaHora = DateTime(
        fecha!.year,
        fecha!.month,
        fecha!.day,
        horaInicio!.hour,
        horaInicio!.minute,
      );

      final reservaData = {
        'cliente': clienteController.text,
        'adultoResponsable': adultoResponsableController.text,
        'telefono': telefonoController.text,
        'cantidadNinos': int.tryParse(cantidadNinosController.text) ?? 0,
        'cantidadAdultos': int.tryParse(cantidadAdultosController.text) ?? 0,
        'comboLunchAdultos': comboLunchAdultosSeleccionado ?? '',
        'comboDulceAdultos': comboDulceAdultosSeleccionado ?? '',
        'pinata': pinata,
        'solicitudEspecial': solicitudEspecialController.text,
        'estadoPago': estadoPago,
        'fecha': fechaHora.toIso8601String(),
        'horaFin':
            '${horaFin!.hour.toString().padLeft(2, '0')}:${horaFin!.minute.toString().padLeft(2, '0')}',
        'timestamp': FieldValue.serverTimestamp(),
      };

      final reservasCollection =
          FirebaseFirestore.instance.collection('reservas');

      if (widget.reservaId != null) {
        // Editar reserva existente
        await reservasCollection.doc(widget.reservaId).update(reservaData);
      } else {
        // Crear nueva reserva
        await reservasCollection.add(reservaData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva guardada con éxito')),
      );
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar reserva: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<bool> estaFechaDisponible(DateTime date) async {
    final fechaInicio = DateTime(date.year, date.month, date.day);
    final fechaFin = fechaInicio.add(const Duration(days: 1));
    final reservas = await FirebaseFirestore.instance
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: fechaInicio.toIso8601String())
        .where('fecha', isLessThan: fechaFin.toIso8601String())
        .get();
    return reservas.docs.length < 2;
  }

  Future<void> seleccionarFechaYHorario() async {
    final ahora = DateTime.now();

    DateTime? fechaInicial = obtenerPrimeraFechaDisponible(diasDisponibles);

    if (fechaInicial == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay fechas disponibles en el próximo año')),
      );
      return;
    }

    final seleccionFecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
      selectableDayPredicate: (dia) =>
          diasDisponibles[normalizarFecha(dia)] ?? false,
    );

    if (!mounted || seleccionFecha == null) return;

    final fechaInicio =
        DateTime(seleccionFecha.year, seleccionFecha.month, seleccionFecha.day);
    final fechaFin = fechaInicio.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('reservas')
        .where('fecha', isGreaterThanOrEqualTo: fechaInicio.toIso8601String())
        .where('fecha', isLessThan: fechaFin.toIso8601String())
        .get();

    if (!mounted) return;

    final horariosReservados = snapshot.docs
        .where((doc) => widget.reservaId == null || doc.id != widget.reservaId)
        .map((doc) {
          final f = DateTime.tryParse(doc['fecha']);
          return f != null ? TimeOfDay(hour: f.hour, minute: f.minute) : null;
        })
        .whereType<TimeOfDay>()
        .toList();

    final horariosDisponiblesFiltrados = horariosDisponibles.where((horario) {
      return !horariosReservados.any((ocupado) =>
          ocupado.hour == horario['inicio']!.hour &&
          ocupado.minute == horario['inicio']!.minute);
    }).toList();

    if (horariosDisponiblesFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay horarios disponibles para este día')),
      );
      return;
    }

    final seleccionado = await showDialog<Map<String, TimeOfDay>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar horario'),
        children: horariosDisponiblesFiltrados.map((horario) {
          final label =
              '${horario['inicio']!.format(context)} - ${horario['fin']!.format(context)}';
          return SimpleDialogOption(
            child: Text(label),
            onPressed: () => Navigator.pop(context, horario),
          );
        }).toList(),
      ),
    );

    if (!mounted || seleccionado == null) return;

    setState(() {
      fecha = seleccionFecha;
      horaInicio = seleccionado['inicio'];
      horaFin = seleccionado['fin'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.reservaId != null ? 'Editar Reserva' : 'Nueva Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: seleccionarFechaYHorario,
                icon: const Icon(Icons.event),
                label: Text(fecha == null ||
                        horaInicio == null ||
                        horaFin == null
                    ? 'Seleccionar Fecha y Horario'
                    : 'Fecha: ${fecha!.day}/${fecha!.month}/${fecha!.year} | ${horaInicio!.format(context)} - ${horaFin!.format(context)}'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: clienteController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del Cumpleañero'),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: adultoResponsableController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Adulto Responsable',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: cantidadNinosController,
                decoration:
                    const InputDecoration(labelText: 'Cantidad de Niños'),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: cantidadAdultosController,
                decoration:
                    const InputDecoration(labelText: 'Cantidad de Adultos'),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              // Campo para agregar nuevo combo
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: comboLunchAdultosSeleccionado,
                      onChanged: (valor) {
                        if (valor == 'Agregar nuevo') {
                          agregarNuevoCombo(
                            'combosLunchAdultos',
                            combosLunchAdultos,
                            (nuevoValor) {
                              setState(() {
                                comboLunchAdultosSeleccionado = nuevoValor;
                              });
                            },
                          );
                        } else {
                          setState(() {
                            comboLunchAdultosSeleccionado = valor;
                          });
                        }
                      },
                      items: combosLunchAdultos
                          .map((combo) => DropdownMenuItem(
                                value: combo,
                                child: Text(combo),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Combo Lunch para Adultos',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Seleccione un Combo Lunch para Adultos'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: comboDulceAdultosSeleccionado,
                      onChanged: (valor) {
                        if (valor == 'Agregar nuevo') {
                          agregarNuevoCombo(
                            'combosDulceAdultos',
                            combosDulceAdultos,
                            (nuevoValor) {
                              setState(() {
                                comboDulceAdultosSeleccionado = nuevoValor;
                              });
                            },
                          );
                        } else {
                          setState(() {
                            comboDulceAdultosSeleccionado = valor;
                          });
                        }
                      },
                      items: combosDulceAdultos
                          .map((combo) => DropdownMenuItem(
                                value: combo,
                                child: Text(combo),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Combo Dulce para Adultos',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Seleccione un Combo Dulce para Adultos'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: estadoPago,
                items: ['Pendiente', 'Confirmado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => estadoPago = val!),
                decoration: const InputDecoration(labelText: 'Estado de pago'),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('¿Incluye Piñata?'),
                value: pinata == 'Sí',
                onChanged: (valor) {
                  setState(() {
                    pinata = valor ? 'Sí' : 'No';
                  });
                },
              ),

              const SizedBox(height: 24),
              TextFormField(
                controller: solicitudEspecialController,
                decoration:
                    const InputDecoration(labelText: 'Solicitud Especial'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              Center(
                child: cargando
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: guardarReserva,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    clienteController.dispose();
    adultoResponsableController.dispose();
    telefonoController.dispose();
    super.dispose();
  }
}
