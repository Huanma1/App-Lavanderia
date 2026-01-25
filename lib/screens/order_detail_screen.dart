import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  Orden? _orden;
  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrden();
  }

  Future<void> _loadOrden() async {
    try {
      final data = await _apiService.getOrden(widget.orderId);
      if (mounted) {
        setState(() {
          if (data != null) {
            _orden = Orden.fromJson(data);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return BackgroundWrapper(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No se pudo cargar la orden:\n$_errorMessage',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Orden #${_orden!.id}'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              const Text(
                'Detalle de Prendas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildGarmentList(),
              if (_orden!.observacion != null &&
                  _orden!.observacion!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Observación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _orden!.observacion!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    String fechaFmt = _orden!.fecha;
    try {
      final dt = DateTime.parse(_orden!.fecha);
      fechaFmt = DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      // Ignorar error de parseo
    }

    String fechaSubidaFmt = _orden!.fechaSubida ?? '-';
    if (_orden!.fechaSubida != null) {
      try {
        final dt = DateTime.parse(_orden!.fechaSubida!);
        fechaSubidaFmt = DateFormat('dd/MM/yyyy').format(dt);
      } catch (e) {
        // Ignorar
      }
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eliminar fila de estado
            // _row('Estado:', _orden!.estado ?? 'N/A', isBold: true),
            // const Divider(),
            _row('Fecha Solicitud:', fechaFmt),
            _row('Fecha Subida:', fechaSubidaFmt),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.blue[800] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarmentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orden!.detalles.length,
      itemBuilder: (context, index) {
        final detalle = _orden!.detalles[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.checkroom),
            title: Text(detalle.prenda?.nombre ?? 'Prenda desconocida'),
            trailing: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                '${detalle.cantidad}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
