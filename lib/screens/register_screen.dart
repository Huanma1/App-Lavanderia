import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for TextInputFormatter
import '../widgets/background_wrapper.dart';
import '../services/api_service.dart';
import 'dart:async'; // Importar para usar Timer
import '../screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores
  final _rutController = TextEditingController();
  final _dvController = TextEditingController();
  final _contratoController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();

  // Estado
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _turnos = [];
  dynamic _selectedTurnoId;
  bool _isLoadingTurnos = false;
  Timer? _debounce; // Timer para el debounce

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en contrato para buscar turnos (opcional si usas botón)
    _contratoController.addListener(
      () => _onContratoChanged(_contratoController.text),
    );

    // Escuchar cambios en RUT para calcular DV
    _rutController.addListener(_updateDV);

    _telefonoController.text = "+569"; // Prefijo por defecto
  }

  @override
  void dispose() {
    _rutController.removeListener(_updateDV);
    _rutController.dispose();
    _dvController.dispose();
    _contratoController.dispose();
    _nombresController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _debounce?.cancel(); // Cancelar timer al salir
    super.dispose();
  }

  // Método para manejar cambios en el contrato con Debounce
  void _onContratoChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Si el campo está vacío, limpiar turnos y retornar
    if (value.trim().isEmpty) {
      setState(() {
        _turnos = [];
        _selectedTurnoId = null;
      });
      return;
    }

    // Esperar 800ms antes de llamar a la API
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _fetchTurnos();
    });
  }

  // Algoritmo Módulo 11 para calcular DV
  void _updateDV() {
    String rut = _rutController.text.replaceAll('.', '').replaceAll(' ', '');
    if (rut.isEmpty) {
      _dvController.text = '';
      return;
    }

    // Invertir cadena
    String rutInvertido = rut.split('').reversed.join();
    int suma = 0;
    int multiplicador = 2;

    for (int i = 0; i < rutInvertido.length; i++) {
      suma += int.parse(rutInvertido[i]) * multiplicador;
      multiplicador++;
      if (multiplicador > 7) multiplicador = 2;
    }

    int resto = suma % 11;
    String dv;
    if (resto == 1) {
      dv = 'K';
    } else if (resto == 0) {
      dv = '0';
    } else {
      dv = (11 - resto).toString();
    }

    // Solo actualizar si es diferente para evitar loops (aunque con readOnly no pasa nada)
    if (_dvController.text != dv) {
      _dvController.text = dv;
    }
  }

  Future<void> _fetchTurnos() async {
    final codigo = _contratoController.text.trim();
    if (codigo.isEmpty) {
      // No mostrar snackbar si el campo está vacío, ya que el debounce lo maneja
      return;
    }

    setState(() {
      _isLoadingTurnos = true;
      _turnos = [];
      _selectedTurnoId = null;
      _errorMessage = null; // Limpiar errores previos
    });

    final api = ApiService();
    // Agregamos try-catch extra por si acaso
    try {
      final turnos = await api.getTurnosByContrato(codigo);

      if (mounted) {
        setState(() {
          _isLoadingTurnos = false;
          _turnos = turnos;
          if (_turnos.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No se encontraron turnos para el contrato "$codigo".\nVerifique que el contrato exista en el sistema.',
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTurnos = false;
          _errorMessage = "Error al buscar turnos: $e";
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTurnoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un turno')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rutCompleto =
        "${_rutController.text.trim()}-${_dvController.text.trim()}";

    final data = {
      'rut': _rutController.text.trim(), // Send numeric RUT separately
      'dv': _dvController.text.trim(), // Send DV separately
      'rut_completo': rutCompleto,
      'contrato_id': _contratoController.text.trim(),
      'turno_id': _selectedTurnoId,
      'nombres': _nombresController.text.trim(),
      'apellido_paterno': _apellidoPaternoController.text.trim(),
      'apellido_materno': _apellidoMaternoController.text.trim(),
      'email': _emailController.text.trim(),
      'movil': _telefonoController.text.trim(), // Changed key to 'movil'
    };

    final api = ApiService();
    final error = await api.registerUser(data);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        // Éxito -> Ir a Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = error;
        });
      }
    }
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
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Registro de Usuario',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230), // ~90% opacity
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.red[100],
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),

                    // --- DISCLAIMER ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50], // Yellowish/Blueish background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Contraseña por Defecto: Su contraseña será generada automáticamente utilizando los primeros 5 dígitos numéricos de su RUN.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- RUN y DV ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            label: 'RUN*',
                            hint: 'Ej: 16055586',
                            controller: _rutController,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            label: 'DV*',
                            hint: '',
                            controller: _dvController,
                            readOnly: true, // AUTO-CALCULADO
                            validator: (v) => v!.isEmpty ? 'Req' : null,
                            fillColor:
                                Colors.grey[200], // Visualmente deshabilitado
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- CONTRATO y TURNO ---
                    // En desktop sería Row, en móvil quizás columna.
                    // Vamos a hacer una Columna para asegurar espacio en móvil.
                    _buildTextField(
                      label: 'Código Contrato*',
                      hint: 'INGRESE CÓDIGO',
                      controller: _contratoController,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      inputFormatters: [
                        // Force Uppercase
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                          );
                        }),
                      ],
                      onChanged: _onContratoChanged, // Lógica automática
                      suffixIcon: _isLoadingTurnos
                          ? Transform.scale(
                              scale: 0.5,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : null, // Mostrar spinner si carga
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "Turno*",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          value: _selectedTurnoId,
                          isExpanded: true,
                          hint: const Text('Seleccione Contrato y Busque'),
                          items: _turnos.map<DropdownMenuItem<dynamic>>((
                            turno,
                          ) {
                            return DropdownMenuItem<dynamic>(
                              value: turno['id'],
                              child: Text(
                                turno['nombre'] ?? 'Turno ${turno['id']}',
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTurnoId = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- NOMBRES ---
                    _buildTextField(
                      label: 'Nombres*',
                      hint: 'Ej: Felipe',
                      controller: _nombresController,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Apellido Paterno*',
                      hint: 'Ej: Miranda',
                      controller: _apellidoPaternoController,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Apellido Materno',
                      hint: 'Ej: Osorio',
                      controller: _apellidoMaternoController,
                    ),
                    const SizedBox(height: 16),

                    // --- CONTACTO ---
                    _buildTextField(
                      label: 'Email*',
                      hint: '',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Número de Contacto',
                      hint: '+56993976202',
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),

                    // --- BOTÓN REGISTRO ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Registrarse',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
    bool readOnly = false,
    Color? fillColor,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged, // Nuevo parámetro onChanged
    Widget? suffixIcon, // Nuevo parámetro suffixIcon
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          onChanged: onChanged, // Asignar onChanged
          decoration: InputDecoration(
            hintText: hint,
            counterText: "", // Hide counter for max length fields
            filled: true,
            fillColor: fillColor ?? Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
        ),
      ],
    );
  }
}
