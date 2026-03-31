import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final data = await _apiService.getUserProfile();
    
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción es permanente. '
          'Se cerrará tu sesión y se eliminarán todos tus datos personales. '
          'Por motivos legales y administrativos, conservaremos únicamente el historial '
          'de transacciones y pagos según la normativa vigente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) setState(() => _isLoading = true);
    final success = await _apiService.deleteAccount();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu cuenta ha sido eliminada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la cuenta. Inténtalo de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(
      color: Colors.white.withValues(alpha: 0.9),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    if (_userData != null) ...[
                      _buildInfoTile(
                        Icons.person_outline,
                        'Nombre Completo',
                        '${_userData!['nombres'] ?? _userData!['name'] ?? ''} ${_userData!['apellido_paterno'] ?? ''} ${_userData!['apellido_materno'] ?? ''}'
                            .trim(),
                      ),
                      _buildInfoTile(
                        Icons.email_outlined,
                        'Correo Electrónico',
                        _userData!['email'] ?? 'No disponible',
                      ),
                      _buildInfoTile(
                        Icons.phone_android,
                        'Teléfono',
                        _userData!['movil'] ?? _userData!['telefono'] ?? 'No disponible',
                      ),
                      _buildInfoTile(
                        Icons.assignment_outlined,
                        'Contrato',
                        _userData!['contrato_nombre'] ?? // El campo nuevo del backend
                        _userData!['nombre_contrato'] ??
                        (_userData!['contrato'] is Map
                            ? (_userData!['contrato']['nombre'] ??
                                _userData!['contrato']['nombre_contrato'] ??
                                'Sin nombre')
                            : (_userData!['contrato'] != null && 
                               !RegExp(r'^[0-9]+$').hasMatch(_userData!['contrato'].toString())
                               ? _userData!['contrato'].toString()
                               : (_userData!['contrato_id']?.toString() ?? _userData!['contrato']?.toString() ?? 'No disponible'))),
                      ),
                      // Opcional: Mostrar empresa si está disponible
                      if (_userData!['empresa_nombre'] != null || _userData!['empresa'] != null)
                        _buildInfoTile(
                          Icons.business_outlined,
                          'Empresa',
                          _userData!['empresa_nombre'] ?? 
                          (_userData!['empresa'] is Map ? _userData!['empresa']['nombre'] : _userData!['empresa']?.toString()) ?? 
                          'No disponible',
                        ),
                    ] else
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No se pudieron cargar los datos del perfil.'),
                        ),
                      ),

                    const SizedBox(height: 30),
                    const Divider(color: Colors.white54),
                    const SizedBox(height: 10),

                    // Botón Eliminar Cuenta
                    Card(
                      color: Colors.red[50]?.withValues(alpha: 0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person_remove, color: Colors.red),
                        title: const Text(
                          'Eliminar cuenta',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text('Darse de baja permanentemente'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.red),
                        onTap: _handleDeleteAccount,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
