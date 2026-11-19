import 'package:flutter/material.dart';

enum TipoIncidente {
  HURTO,
  ACCIDENTE_TRANSITO,
  INCENDIO,
  SISMO,
  INUNDACION,
  OTRO,
}

extension TipoIncidenteExtension on TipoIncidente {
  String get label {
    switch (this) {
      case TipoIncidente.HURTO:
        return 'Hurto';
      case TipoIncidente.ACCIDENTE_TRANSITO:
        return 'Accidente de Tránsito';
      case TipoIncidente.INCENDIO:
        return 'Incendio';
      case TipoIncidente.SISMO:
        return 'Sismo';
      case TipoIncidente.INUNDACION:
        return 'Inundación';
      case TipoIncidente.OTRO:
        return 'Otro';
    }
  }

  String get entidadAsignada {
    switch (this) {
      case TipoIncidente.HURTO:
      case TipoIncidente.ACCIDENTE_TRANSITO:
      case TipoIncidente.OTRO:
        return 'Policía';
      case TipoIncidente.INCENDIO:
        return 'Bomberos';
      case TipoIncidente.SISMO:
      case TipoIncidente.INUNDACION:
        return 'Central de Riesgos';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoIncidente.HURTO:
        return Icons.local_police_rounded;
      case TipoIncidente.ACCIDENTE_TRANSITO:
        return Icons.car_crash_rounded;
      case TipoIncidente.INCENDIO:
        return Icons.local_fire_department_rounded;
      case TipoIncidente.SISMO:
        return Icons.landslide_rounded;
      case TipoIncidente.INUNDACION:
        return Icons.flood_rounded;
      case TipoIncidente.OTRO:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TipoIncidente.HURTO:
        return const Color(0xFF1E3A8A);
      case TipoIncidente.ACCIDENTE_TRANSITO:
        return const Color(0xFFD97706);
      case TipoIncidente.INCENDIO:
        return const Color(0xFFDC2626);
      case TipoIncidente.SISMO:
        return const Color(0xFF7C2D12);
      case TipoIncidente.INUNDACION:
        return const Color(0xFF0284C7);
      case TipoIncidente.OTRO:
        return const Color(0xFF4B5563);
    }
  }
}

class Incidente {
  final String id;
  final TipoIncidente tipo;
  final double latitud;
  final double longitud;
  final String fechaHora;

  Incidente({
    required this.id,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    final tipoStr = json['tipo'] as String;
    final tipoEnum = TipoIncidente.values.firstWhere(
          (e) => e.name == tipoStr,
      orElse: () => TipoIncidente.OTRO,
    );

    final ubicacion = json['ubicacion'] as Map<String, dynamic>;

    return Incidente(
      id: json['id'].toString(),
      tipo: tipoEnum,
      latitud: (ubicacion['latitud'] as num).toDouble(),
      longitud: (ubicacion['longitud'] as num).toDouble(),
      fechaHora: json['fechaHora'].toString(),
    );
  }
}