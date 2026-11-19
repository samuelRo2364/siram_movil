import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'models/incidente.dart';
import 'services/siram_graphql_service.dart';

void main() {
  runApp(const SiramApp());
}

class SiramApp extends StatelessWidget {
  const SiramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIRAM Emergencias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC2626),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const PermisoUbicacionGate(),
    );
  }
}

// ============================================================================
// GUARDIÁN DE PERMISOS DE UBICACIÓN (BLOQUEA LA APP SI SE RECHAZA EL PERMISO)
// ============================================================================
class PermisoUbicacionGate extends StatefulWidget {
  const PermisoUbicacionGate({super.key});

  @override
  State<PermisoUbicacionGate> createState() => _PermisoUbicacionGateState();
}

class _PermisoUbicacionGateState extends State<PermisoUbicacionGate>
    with WidgetsBindingObserver {
  bool _verificando = true;
  bool _permisoConcedido = false;
  bool _dialogoVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificarUbicacion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarUbicacion();
    }
  }

  Future<void> _verificarUbicacion() async {
    setState(() => _verificando = true);

    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      if (!mounted) return;
      setState(() {
        _verificando = false;
        _permisoConcedido = false;
      });
      _mostrarDialogoBloqueo(
        titulo: 'GPS desactivado',
        mensaje:
        'SIRAM necesita que actives la ubicación (GPS) de tu dispositivo para enviar tus coordenadas exactas en caso de emergencia.',
        esServicioApagado: true,
        permanente: false,
      );
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permiso == LocationPermission.whileInUse ||
        permiso == LocationPermission.always) {
      if (_dialogoVisible) {
        Navigator.of(context, rootNavigator: true).pop();
        _dialogoVisible = false;
      }
      setState(() {
        _verificando = false;
        _permisoConcedido = true;
      });
    } else {
      final bool esPermanente = permiso == LocationPermission.deniedForever;
      setState(() {
        _verificando = false;
        _permisoConcedido = false;
      });
      _mostrarDialogoBloqueo(
        titulo: 'Permiso de ubicación obligatorio',
        mensaje: esPermanente
            ? 'Has denegado permanentemente el acceso a la ubicación. Debes habilitarlo manualmente en los ajustes de la aplicación para poder usar SIRAM.'
            : 'No puedes utilizar SIRAM sin conceder acceso a tu ubicación, ya que las entidades de socorro requieren tus coordenadas para atender el reporte.',
        esServicioApagado: false,
        permanente: esPermanente,
      );
    }
  }

  void _mostrarDialogoBloqueo({
    required String titulo,
    required String mensaje,
    required bool esServicioApagado,
    required bool permanente,
  }) {
    if (_dialogoVisible) return;
    _dialogoVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(
              Icons.location_off_rounded,
              color: Color(0xFFDC2626),
              size: 48,
            ),
            title: Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              mensaje,
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (esServicioApagado)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    _dialogoVisible = false;
                    await Geolocator.openLocationSettings();
                  },
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Activar GPS'),
                )
              else if (permanente)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    _dialogoVisible = false;
                    await Geolocator.openAppSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Abrir Ajustes'),
                )
              else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _dialogoVisible = false;
                    _verificarUbicacion();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Conceder Permiso'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permisoConcedido) {
      return const HomeScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.emergency_share_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'SIRAM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _verificando
              ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFDC2626)),
              SizedBox(height: 16),
              Text('Verificando permisos de ubicación...'),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Color(0xFF0F172A),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acceso bloqueado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SIRAM requiere acceso a tu ubicación GPS para poder reportar emergencias.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                onPressed: _verificarUbicacion,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Verificar nuevamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.emergency_share_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIRAM',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Sistema de Respuesta a Emergencias',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? const ReportarEmergenciaTab()
          : const HistorialIncidentesTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos_rounded, color: Color(0xFFDC2626)),
            label: 'Reportar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF0F172A)),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 1: REPORTAR EMERGENCIA
// ============================================================================
class ReportarEmergenciaTab extends StatefulWidget {
  const ReportarEmergenciaTab({super.key});

  @override
  State<ReportarEmergenciaTab> createState() => _ReportarEmergenciaTabState();
}

class _ReportarEmergenciaTabState extends State<ReportarEmergenciaTab> {
  final SiramGraphqlService _api = SiramGraphqlService();
  TipoIncidente _tipoSeleccionado = TipoIncidente.ACCIDENTE_TRANSITO;
  double? _latitud;
  double? _longitud;
  bool _cargandoUbicacion = false;
  bool _enviandoReporte = false;
  String? _mensajeUbicacion;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _cargandoUbicacion = true;
      _mensajeUbicacion = 'Obteniendo coordenadas GPS...';
    });

    try {
      bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        throw Exception('El GPS del dispositivo está desactivado.');
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado.');
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación bloqueado en ajustes.');
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
        _mensajeUbicacion = null;
      });
    } catch (e) {
      setState(() {
        _mensajeUbicacion = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _cargandoUbicacion = false);
    }
  }

  Future<void> _enviarAlerta() async {
    if (_latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes obtener tu ubicación GPS antes de enviar la alerta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _enviandoReporte = true);

    try {
      final incidenteCreado = await _api.reportarIncidente(
        tipo: _tipoSeleccionado,
        latitud: _latitud!,
        longitud: _longitud!,
      );

      if (!mounted) return;
      _mostrarDialogoConfirmacion(incidenteCreado);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reportar: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _enviandoReporte = false);
    }
  }

  void _mostrarDialogoConfirmacion(Incidente incidente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
        title: const Text('¡Alerta Enviada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu reporte de ${incidente.tipo.label} ha sido registrado y despachado a ${incidente.tipo.entidadAsignada}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'ID: ${incidente.id.substring(0, 8)}...\nGPS: ${incidente.latitud.toStringAsFixed(4)}, ${incidente.longitud.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de ubicación GPS
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ubicación Actual',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        if (_cargandoUbicacion)
                          const Text('Localizando satélite...', style: TextStyle(fontSize: 13))
                        else if (_latitud != null && _longitud != null)
                          Text(
                            'Lat: ${_latitud!.toStringAsFixed(5)} | Lng: ${_longitud!.toStringAsFixed(5)}',
                            style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                          )
                        else
                          Text(
                            _mensajeUbicacion ?? 'Ubicación no disponible',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _cargandoUbicacion ? null : _obtenerUbicacionActual,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Actualizar GPS',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Selecciona el tipo de emergencia',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          // Cuadrícula de tipos de incidente
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: TipoIncidente.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final tipo = TipoIncidente.values[index];
              final seleccionado = tipo == _tipoSeleccionado;

              return InkWell(
                onTap: () => setState(() => _tipoSeleccionado = tipo),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: seleccionado ? tipo.color.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: seleccionado ? tipo.color : Colors.grey.shade200,
                      width: seleccionado ? 2.2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tipo.icon, size: 34, color: tipo.color),
                      const SizedBox(height: 8),
                      Text(
                        tipo.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Botón principal de envío
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: _enviandoReporte ? null : _enviarAlerta,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _enviandoReporte
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _enviandoReporte
                    ? 'ENVIANDO ALERTA...'
                    : 'REPORTAR ${_tipoSeleccionado.label.toUpperCase()}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 2: HISTORIAL DE INCIDENTES
// ============================================================================
class HistorialIncidentesTab extends StatefulWidget {
  const HistorialIncidentesTab({super.key});

  @override
  State<HistorialIncidentesTab> createState() => _HistorialIncidentesTabState();
}

class _HistorialIncidentesTabState extends State<HistorialIncidentesTab> {
  final SiramGraphqlService _api = SiramGraphqlService();
  TipoIncidente? _filtroSeleccionado;
  late Future<List<Incidente>> _futureIncidentes;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _futureIncidentes = _api.obtenerIncidentes(filtroTipo: _filtroSeleccionado);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra horizontal de filtros por TipoIncidente
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _filtroSeleccionado == null,
                  onSelected: (_) {
                    _filtroSeleccionado = null;
                    _recargar();
                  },
                ),
                const SizedBox(width: 8),
                ...TipoIncidente.values.map((tipo) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tipo.label),
                      selected: _filtroSeleccionado == tipo,
                      onSelected: (_) {
                        _filtroSeleccionado = tipo;
                        _recargar();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Lista de incidentes
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: FutureBuilder<List<Incidente>>(
              future: _futureIncidentes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'No se pudo conectar con SIRAM:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _recargar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final incidentes = snapshot.data ?? [];
                if (incidentes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay incidentes registrados con este filtro.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: incidentes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = incidentes[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: item.tipo.color.withOpacity(0.15),
                          child: Icon(item.tipo.icon, color: item.tipo.color),
                        ),
                        title: Text(
                          item.tipo.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Entidad: ${item.tipo.entidadAsignada}'),
                            Text(
                              'GPS: ${item.latitud.toStringAsFixed(4)}, ${item.longitud.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Fecha: ${item.fechaHora.replaceFirst('T', ' ').split('.').first}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}