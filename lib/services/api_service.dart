import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // --- CONFIGURACIÓN DE ENTORNO ---
  // Cambia a 'true' para usar tu servidor real en el celular
  static const bool useProduction = true;

  static const String localUrl = 'https://10.0.2.2/segemin-local/public/api';
  static const String prodUrl =
      'https://www.segemin.cl/api'; // <--- URL REAL DE PRODUCCIÓN (Con www)

  static String get baseUrl => useProduction ? prodUrl : localUrl;
  // --------------------------------

  // Cliente HTTP
  http.Client _getClient() {
    final ioc = HttpClient();
    // Permitir certificados autofirmados o inválidos en PROD para descartar problemas SSL
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    return IOClient(ioc);
  }

  // Verificar si hay sesión activa
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  /// Limpia el RUT para obtener solo el cuerpo numérico (sin puntos, sin guiones, sin DV)
  String _cleanRutBody(String rut) {
    if (rut.isEmpty) return '';

    // 1. Quitamos puntos y espacios primero
    String cleaned = rut.replaceAll('.', '').replaceAll(' ', '');

    // 2. Si hay un guion, tomamos lo que está antes
    String body = cleaned.contains('-') ? cleaned.split('-')[0] : cleaned;

    // 3. Quitamos cualquier carácter no numérico del cuerpo (por si acaso)
    body = body.replaceAll(RegExp(r'[^0-9]'), '');

    // 4. Si NO había guion pero el usuario pegó el RUT con DV al final
    // (Ej: 210244980 o 21024498K)
    if (!rut.contains('-') && cleaned.length >= 8) {
      String onlyNumbers = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
      if (onlyNumbers.length == 9) {
        return onlyNumbers.substring(0, 8);
      } else if (onlyNumbers.length == 8 && rut.toLowerCase().endsWith('k')) {
        return onlyNumbers;
      }
    }

    return body;
  }

  Future<String?> login(String rut, String password) async {
    final cleanedRut = _cleanRutBody(rut);
    final url = Uri.parse('$baseUrl/login');
    final client = _getClient();

    debugPrint('--- INTENTO DE LOGIN ---');
    debugPrint('URL: $url');

    try {
      final body = jsonEncode({
        'rut_completo': cleanedRut,
        'password': password,
      });

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      debugPrint('Respuesta Status: ${response.statusCode}');
      // IMPORTANTE: Leemos el body una sola vez
      final responseBody = response.body;

      if (responseBody.isEmpty) {
        return 'Error: El servidor respondió vacío (${response.statusCode})';
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseBody);
          final token = data['token'];

          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);
            return null; // Éxito
          } else {
            return 'Error: Servidor no envió token';
          }
        } catch (e) {
          return 'Error de formato (200): $e';
        }
      } else if (response.statusCode == 401) {
        try {
          final data = jsonDecode(responseBody);
          return data['message'] ?? 'Credenciales incorrectas';
        } catch (_) {
          // Si falla el JSON en 401, devolvemos el texto plano por si acaso es HTML
          return 'Error 401: ${responseBody.length > 50 ? responseBody.substring(0, 50) : responseBody}';
        }
      } else {
        return 'Error del servidor (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Error: $e');
      return 'Error técnico: $e';
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getPrendas() async {
    final url = Uri.parse('$baseUrl/prendas');
    final client = _getClient();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo prendas: $e');
      return [];
    } finally {
      client.close();
    }
  }

  Future<bool> createOrden(Map<String, dynamic> orderData) async {
    final url = Uri.parse('$baseUrl/ordenes');
    final client = _getClient();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Error orden: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creando orden: $e');
      return false;
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getOrdenes() async {
    final url = Uri.parse('$baseUrl/ordenes');
    final client = _getClient();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      debugPrint('GET Ordenes URL: $url');
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('GET Ordenes Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error getOrdenes: $e');
      return [];
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> getOrden(int id) async {
    final url = Uri.parse('$baseUrl/ordenes/$id');
    final client = _getClient();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Status ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Error getOrden: $e');
      throw Exception('Error: $e');
    } finally {
      client.close();
    }
  }

  // --- NUEVOS MÉTODOS PARA REGISTRO ---

  /// Obtiene los turnos asociados a un contrato
  Future<List<dynamic>> getTurnosByContrato(String contratoId) async {
    // Ajustar URL según tu backend: /contratos/{id}/turnos
    final url = Uri.parse('$baseUrl/contratos/$contratoId/turnos');
    final client = _getClient();

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'Error getTurnos: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error getTurnosByContrato: $e');
      return [];
    } finally {
      client.close();
    }
  }

  /// Registra un nuevo usuario
  Future<String?> registerUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/register');
    final client = _getClient();

    try {
      // Limpiar RUT antes de enviar
      if (userData.containsKey('rut_completo')) {
        userData['rut_completo'] = _cleanRutBody(userData['rut_completo']);
      }

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userData),
      );

      final responseBody = response.body;
      debugPrint('Register Status: ${response.statusCode}');
      debugPrint('Register Body: $responseBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Si el backend devuelve token al registrar, lo guardamos para auto-login
        try {
          final data = jsonDecode(responseBody);
          if (data['token'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', data['token']);
          }
          return null; // Éxito (null = sin error)
        } catch (_) {
          // Si no hay token o falló el parseo, igual consideramos éxito si fue 200/201
          return null;
        }
      } else {
        // Intentar leer mensaje de error del backend
        try {
          final data = jsonDecode(responseBody);
          // Laravel suele devolver errores de validación en 'errors' o mensaje en 'message'
          if (data['errors'] != null) {
            // Unir errores de validación en un solo string
            final errors = data['errors'] as Map<String, dynamic>;
            return errors.values.map((e) => e.toString()).join('\n');
          }
          return data['message'] ?? 'Error desconocido al registrar';
        } catch (_) {
          return 'Error ${response.statusCode}: $responseBody';
        }
      }
    } catch (e) {
      debugPrint('Error registro: $e');
      return 'Error de conexión: $e';
    } finally {
      client.close();
    }
  }

  Future<String> sendPasswordResetLink(String rut, String email) async {
    final url = Uri.parse('$baseUrl/forgot-password');

    // Limpiamos el RUT para obtener el ID numérico
    final rutLimpio = rut.replaceAll(RegExp(r'[^0-9kK]'), '');
    final idNumerico = rutLimpio.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final response = await _getClient().post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': idNumerico, 'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return 'OK'; // Éxito
      } else {
        return data['message'] ?? 'Error al enviar solicitud.';
      }
    } catch (e) {
      return 'Error de conexión: $e';
    } finally {
      // client.close(); // _getClient should be closed if it was assigned to a variable
    }
  }

  /// Obtiene la información del perfil del usuario autenticado
  Future<Map<String, dynamic>?> getUserProfile() async {
    final url = Uri.parse('$baseUrl/user');
    final client = _getClient();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'Error getUserProfile: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error en getUserProfile: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Solicita la eliminación de la cuenta del usuario (Soft Delete)
  Future<bool> deleteAccount() async {
    final url = Uri.parse('$baseUrl/user');
    final client = _getClient();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Limpiar token localmente tras éxito
        await prefs.remove('auth_token');
        return true;
      } else {
        debugPrint('Error deleteAccount: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error en deleteAccount: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
