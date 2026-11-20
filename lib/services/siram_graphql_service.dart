import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incidente.dart';

class SiramGraphqlService {
  // 10.0.2.2 apunta al localhost de tu PC desde el emulador de Android Studio.
  // Si usas un celular físico por Wi-Fi, cámbialo por la IP local de tu PC (ej. http://192.168.1.15:8080/graphql).
  static const String _endpoint = 'http://192.168.0.8:8080/graphql';

  Future<Incidente> reportarIncidente({
    required TipoIncidente tipo,
    required double latitud,
    required double longitud,
  }) async {
    const String mutation = '''
      mutation ReportarIncidente(\$input: ReportarIncidenteInput!) {
        reportarIncidente(input: \$input) {
          id
          tipo
          ubicacion {
            latitud
            longitud
          }
          fechaHora
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': mutation,
        'variables': {
          'input': {
            'tipo': tipo.name,
            'ubicacion': {
              'latitud': latitud,
              'longitud': longitud,
            },
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error de conexión con el servidor (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['errors'] != null) {
      throw Exception(body['errors'][0]['message']);
    }

    return Incidente.fromJson(body['data']['reportarIncidente']);
  }

  Future<List<Incidente>> obtenerIncidentes({
    TipoIncidente? filtroTipo,
    String? filtroFecha,
  }) async {
    const String query = '''
      query ListarIncidentes(\$tipo: TipoIncidente, \$fecha: String) {
        incidentes(tipo: \$tipo, fecha: \$fecha) {
          id
          tipo
          ubicacion {
            latitud
            longitud
          }
          fechaHora
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': {
          'tipo': filtroTipo?.name,
          'fecha': filtroFecha,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al consultar incidentes (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['errors'] != null) {
      throw Exception(body['errors'][0]['message']);
    }

    final List<dynamic> lista = body['data']['incidentes'] ?? [];
    return lista.map((item) => Incidente.fromJson(item)).toList().reversed.toList();
  }
}