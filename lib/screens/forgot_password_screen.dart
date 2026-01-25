import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/background_wrapper.dart'; // Correct import for BackgroundWrapper

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _dvController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _rutController.addListener(_updateDV);
  }

  @override
  void dispose() {
    _rutController.removeListener(_updateDV);
    _rutController.dispose();
    _dvController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateDV() {
    final rut = _rutController.text.trim();
    if (rut.isEmpty) {
      _dvController.text = '';
      return;
    }
    _dvController.text = _calculateDV(rut);
  }

  String _calculateDV(String rut) {
    if (rut.isEmpty) return "";
    int suma = 0;
    int multiplicador = 2;
    // Iterar de atrás hacia adelante
    for (int i = rut.length - 1; i >= 0; i--) {
      int? digito = int.tryParse(rut[i]);
      if (digito == null) return ""; // Si hay caracteres no numéricos
      suma += digito * multiplicador;
      multiplicador++;
      if (multiplicador > 7) multiplicador = 2;
    }
    int resto = suma % 11;
    int dv = 11 - resto;
    if (dv == 11) return "0";
    if (dv == 10) return "K";
    return dv.toString();
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    final api = ApiService();
    // Enviamos solo la parte numérica (RUN) como ID.
    final result = await api.sendPasswordResetLink(
      _rutController.text.trim(),
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (result == 'OK') {
        _isError = false;
        _message =
            'Solicitud enviada. Revisa tu correo electrónico para restablecer tu contraseña.';
        // Limpiar campos si fue exitoso
        _rutController.clear();
        _dvController.clear();
        _emailController.clear();
      } else {
        _isError = true;
        _message = result;
      }
    });
  }

  // Helper para crear Inputs idénticos al Login/Registro
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    IconData? icon,
    bool readOnly = false,
    Color? fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 5),
        ],
        Container(
          decoration: BoxDecoration(
            color: fillColor ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            readOnly: readOnly,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.blue[800])
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: label,
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "Recuperar Contraseña",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Ingresa tu RUT y correo electrónico para recibir un enlace de recuperación.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      if (_message != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isError ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isError
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                            ),
                          ),
                          child: Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isError
                                  ? Colors.red[800]
                                  : Colors.green[800],
                            ),
                          ),
                        ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              label: 'RUN',
                              controller: _rutController,
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              label: 'DV',
                              controller: _dvController,
                              readOnly: true, // AUTO-CALCULADO
                              fillColor: Colors.grey[200],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Req' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Correo Electrónico',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        icon: Icons.email_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "ENVIAR ENLACE",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
