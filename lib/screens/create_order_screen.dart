import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controladores
  final TextEditingController _habitacionController = TextEditingController();
  final TextEditingController _pabellonController = TextEditingController();
  final TextEditingController _observacionController = TextEditingController();

  DateTime? _fechaBajada;
  DateTime? _fechaSubida;

  List<dynamic> _prendas = [];
  final Map<int, int> _cantidades = {}; // ID Prenda -> Cantidad
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPrendas();
  }

  Future<void> _loadPrendas() async {
    final prendas = await _apiService.getPrendas();
    if (mounted) {
      setState(() {
        _prendas = prendas;
        _isLoading = false;
        // Inicializar cantidades en 0
        for (var p in _prendas) {
          _cantidades[p['id']] = 0;
        }
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaBajada == null || _fechaSubida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar las fechas')),
      );
      return;
    }

    // Verificar que haya al menos una prenda
    final prendasSeleccionadas = _cantidades.entries.where((e) => e.value > 0);
    if (prendasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos una prenda')),
      );
      return;
    }

    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pedido'),
        content: Text(
          '¿Desea enviar la orden con ${prendasSeleccionadas.length} tipos de prendas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    // Preparar Data JSON
    final Map<String, dynamic> prendasMap = {};
    for (var entry in _cantidades.entries) {
      prendasMap[entry.key.toString()] = entry.value;
    }

    final orderData = {
      'fecha_bajada': DateFormat('yyyy-MM-dd').format(_fechaBajada!),
      'fecha_subida': DateFormat('yyyy-MM-dd').format(_fechaSubida!),
      'habitacion': _habitacionController.text,
      'pabellon': _pabellonController.text,
      'observacion': _observacionController.text,
      'prendas': prendasMap,
    };

    final success = await _apiService.createOrden(orderData);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context); // Volver al Dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Orden creada exitosamente!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la orden. Intente nuevamente.'),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBajada) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isBajada) {
          _fechaBajada = picked;
        } else {
          _fechaSubida = picked;
        }
      });
    }
  }

  // ... class definition ...

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BackgroundWrapper(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Nueva Orden'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          color: Colors.white.withValues(alpha: 0.95),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Sección Fechas
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Bajada Actual'),
                        subtitle: Text(
                          _fechaBajada == null
                              ? 'Seleccionar'
                              : DateFormat('dd-MM-yyyy').format(_fechaBajada!),
                        ),
                        leading: const Icon(Icons.arrow_downward),
                        onTap: () => _selectDate(context, true),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Subida Próxima'),
                        subtitle: Text(
                          _fechaSubida == null
                              ? 'Seleccionar'
                              : DateFormat('dd-MM-yyyy').format(_fechaSubida!),
                        ),
                        leading: const Icon(Icons.arrow_upward),
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Sección Ubicación
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _habitacionController,
                        decoration: const InputDecoration(
                          labelText: 'Habitación',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _pabellonController,
                        decoration: const InputDecoration(
                          labelText: 'Pabellón',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Prendas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                // Lista Dinámica de Prendas
                ..._prendas.map((prenda) {
                  final id = prenda['id'];
                  final nombre = prenda['nombre'];
                  // final desc = prenda['descripcion'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              nombre,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_cantidades[id]! > 0) {
                                  _cantidades[id] = _cantidades[id]! - 1;
                                }
                              });
                            },
                          ),
                          Text(
                            '${_cantidades[id]}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              setState(() {
                                _cantidades[id] = _cantidades[id]! + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _observacionController,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text(
                            'ENVIAR ORDEN',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
