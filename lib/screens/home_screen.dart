import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _ordenes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrdenes();
  }

  Future<void> _loadOrdenes() async {
    setState(() => _isLoading = true);
    final ordenes = await _apiService.getOrdenes();
    if (mounted) {
      setState(() {
        _ordenes = ordenes;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Mis Órdenes'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadOrdenes,
              tooltip: 'Recargar',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Cerrar Sesión',
            ),
          ],
        ),
        body: Column(
          children: [
            // Sección de Bienvenida / Botón Crear
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateOrderScreen(),
                      ),
                    );
                    // Recargar lista al volver
                    _loadOrdenes();
                  },
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Crear Orden de Lavado'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            const Divider(color: Colors.white54),

            // Lista de Órdenes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _ordenes.isEmpty
                  ? const Center(
                      child: Text(
                        'No tienes órdenes recientes.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _ordenes.length,
                      itemBuilder: (context, index) {
                        final orden = _ordenes[index];
                        final id = orden['id'];
                        // final estado = orden['estado'] ?? 'Pendiente'; // Ya no lo mostramos

                        // Formatear Fechas
                        final fechaRaw = orden['fecha'];
                        String fechaFmt = '';
                        if (fechaRaw != null) {
                          try {
                            final dt = DateTime.parse(fechaRaw);
                            fechaFmt = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(dt);
                          } catch (e) {
                            fechaFmt = fechaRaw;
                          }
                        }

                        final fechaSubidaRaw = orden['fecha_subida'];
                        String fechaSubidaFmt = '';
                        if (fechaSubidaRaw != null) {
                          try {
                            // Asumiendo que viene YYYY-MM-DD
                            final dt = DateTime.parse(fechaSubidaRaw);
                            fechaSubidaFmt = DateFormat(
                              'dd/MM/yyyy',
                            ).format(dt);
                          } catch (e) {
                            fechaSubidaFmt = fechaSubidaRaw;
                          }
                        }

                        return Card(
                          color: Colors.white.withValues(alpha: 0.9),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              'Orden #$id',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('Solicitud: $fechaFmt'),
                                    ],
                                  ),
                                  if (fechaSubidaFmt.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.arrow_upward,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('Subida: $fechaSubidaFmt'),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderDetailScreen(orderId: id),
                                  ),
                                );
                              },
                              child: const Icon(Icons.visibility),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OrderDetailScreen(orderId: id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
