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
        title: const Text(
          'Stock',
          style: TextStyle(
            color: Color(0xFFFF6B81), // Amarillo suave
            fontWeight: FontWeight.bold,
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
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
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
                  title: Text(data['nombre'] ?? ''),
                  subtitle: Text(
                    'Categoría: ${data['categoria'] ?? ''} - Cantidad: ${data['cantidad'] ?? 0}',
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => StockDialog(doc: doc),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      stockCollection.doc(doc.id).delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B81), // Rosa coral
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const StockDialog(),
          );
        },
        child: const Icon(Icons.add),
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
      backgroundColor: Colors.white,
      title: Text(
        widget.doc == null ? 'Nuevo ítem' : 'Editar ítem',
        style: const TextStyle(
          color: Color(0xFFA0D8EF), // Amarillo suave
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
                controller: nombreController,
                decoration: const InputDecoration(
                    labelText: 'Nombre del combo/artículo'),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
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
                      controller: nuevaCategoriaController,
                      decoration: const InputDecoration(
                        hintText: 'Agregar nueva categoría',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: agregarNuevaCategoria,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
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
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFA0D8EF), // Azul pastel
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
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
