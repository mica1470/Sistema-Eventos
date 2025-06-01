import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockPantalla extends StatelessWidget {
  const StockPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final stockCollection = FirebaseFirestore.instance.collection('stock');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Gris claro
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Semantics(
          label: 'Sección Stock - título',
          child: const Text(
            'Stock',
            key: Key('stockPantalla_appBar_title'),
            style: TextStyle(
              color: Color(0xFFFF6B81), // Amarillo suave
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stockCollection
            .orderBy('ultimaModificacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(key: Key('stockPantalla_loading')),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            key: const Key('stockPantalla_listaItems'),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  key: Key('stockPantalla_item_${doc.id}'),
                  title: Text(data['nombre'] ?? '',
                      key: Key('stockPantalla_item_${doc.id}_nombre')),
                  subtitle: Text(
                    'Categoría: ${data['categoria'] ?? ''} - Cantidad: ${data['cantidad'] ?? 0}',
                    key: Key('stockPantalla_item_${doc.id}_detalle'),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => StockDialog(doc: doc),
                    );
                  },
                  trailing: IconButton(
                    key: Key('stockPantalla_item_${doc.id}_btnEliminar'),
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          key: const Key('stockPantalla_confirmDialog'),
                          title: const Text('Confirmar eliminación',
                              key: Key('stockPantalla_confirmDialog_titulo')),
                          content: const Text(
                              '¿Desea eliminar este ítem del stock?',
                              key:
                                  Key('stockPantalla_confirmDialog_contenido')),
                          actions: [
                            TextButton(
                              key: const Key(
                                  'stockPantalla_confirmDialog_btnCancelar'),
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              key: const Key(
                                  'stockPantalla_confirmDialog_btnEliminar'),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await stockCollection.doc(doc.id).delete();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('stockPantalla_btnAgregar'),
        backgroundColor: const Color(0xFFFF6B81), // Rosa coral
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const StockDialog(),
          );
        },
        child: const Icon(Icons.add, key: Key('stockPantalla_btnAgregar_icon')),
      ),
    );
  }
}

class StockDialog extends StatefulWidget {
  final DocumentSnapshot? doc;

  const StockDialog({super.key, this.doc});

  @override
  State<StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<StockDialog> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final cantidadController = TextEditingController();
  String? categoriaSeleccionada;
  final nuevaCategoriaController = TextEditingController();

  final List<String> categoriasBase = ['Comida', 'Cotillón', 'Decoración'];
  List<String> categorias = [];

  @override
  void initState() {
    super.initState();
    categorias = List.from(categoriasBase);
    if (widget.doc != null) {
      final data = widget.doc!.data() as Map<String, dynamic>;
      nombreController.text = data['nombre'] ?? '';
      cantidadController.text = data['cantidad']?.toString() ?? '';
      categoriaSeleccionada = data['categoria'];
      if (!categorias.contains(categoriaSeleccionada)) {
        categorias.add(categoriaSeleccionada!);
      }
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    cantidadController.dispose();
    nuevaCategoriaController.dispose();
    super.dispose();
  }

  void agregarNuevaCategoria() {
    final nueva = nuevaCategoriaController.text.trim();
    if (nueva.isNotEmpty && !categorias.contains(nueva)) {
      setState(() {
        categorias.add(nueva);
        categoriaSeleccionada = nueva;
        nuevaCategoriaController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockCollection = FirebaseFirestore.instance.collection('stock');

    return AlertDialog(
      key: const Key('stockDialog_alertDialog'),
      backgroundColor: Colors.white,
      title: Text(
        widget.doc == null ? 'Nuevo ítem' : 'Editar ítem',
        key: const Key('stockDialog_titulo'),
        style: const TextStyle(
          color: Color(0xFFA0D8EF), // Azul pastel
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('stockDialog_inputNombre'),
                controller: nombreController,
                decoration: const InputDecoration(
                    labelText: 'Nombre del combo/artículo'),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('stockDialog_dropdownCategoria'),
                decoration: const InputDecoration(labelText: 'Categoría'),
                value: categoriaSeleccionada,
                items: categorias
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    categoriaSeleccionada = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleccione una categoría' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('stockDialog_inputNuevaCategoria'),
                      controller: nuevaCategoriaController,
                      decoration: const InputDecoration(
                        hintText: 'Agregar nueva categoría',
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('stockDialog_btnAgregarCategoria'),
                    icon: const Icon(Icons.add),
                    onPressed: agregarNuevaCategoria,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('stockDialog_inputCantidad'),
                controller: cantidadController,
                decoration:
                    const InputDecoration(labelText: 'Cantidad disponible'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Ingrese una cantidad';
                  final cantidad = int.tryParse(value);
                  if (cantidad == null || cantidad < 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('stockDialog_btnCancelar'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFA0D8EF), // Azul pastel
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('stockDialog_btnGuardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B81), // Rosa coral
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final nombre = nombreController.text.trim();
              final categoria = categoriaSeleccionada!;
              final cantidad = int.parse(cantidadController.text.trim());
              final ahora = Timestamp.now();

              if (widget.doc == null) {
                await stockCollection.add({
                  'nombre': nombre,
                  'categoria': categoria,
                  'cantidad': cantidad,
                  'ultimaModificacion': ahora,
                });
              } else {
                await stockCollection.doc(widget.doc!.id).update({
                  'nombre': nombre,
                  'categoria': categoria,
                  'cantidad': cantidad,
                  'ultimaModificacion': ahora,
                });
              }

              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
