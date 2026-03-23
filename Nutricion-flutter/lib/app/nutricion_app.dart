import 'package:flutter/material.dart';
import '../features/inventario/inventario_screen.dart';
import '../features/platos_servidos/platos_servidos_screen.dart';
import '../features/reportes/reportes_screen.dart';
import 'models.dart';
import 'widgets/sidebar.dart';
import 'api_client.dart';

class NutricionApp extends StatelessWidget {
  const NutricionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrición',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: const _NutricionHome(),
    );
  }
}

class _NutricionHome extends StatefulWidget {
  const _NutricionHome();

  @override
  State<_NutricionHome> createState() => _NutricionHomeState();
}

class _NutricionHomeState extends State<_NutricionHome> {
  ViewType _currentView = ViewType.inventario;
  final ApiClient _apiClient = ApiClient();
  List<Sede> _sedes = const [];
  Sede? _selectedSede;
  bool _cargandoSedes = true;
  String? _errorSedes;
  bool _globalLoading = false;
  OverlayEntry? _loadingOverlayEntry;

  @override
  void initState() {
    super.initState();
    _cargarSedes();
  }

  Future<void> _cargarSedes() async {
    setState(() {
      _cargandoSedes = true;
      _errorSedes = null;
    });

    try {
      final sedesJson = await _apiClient.getJsonList(
        '/sedes',
        query: {'activa': 'true'},
      );

      final sedes = sedesJson
          .map((e) => Sede.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _sedes = sedes;
        _selectedSede = sedes.isNotEmpty ? sedes.first : null;
        _cargandoSedes = false;
      });
    } catch (e) {
      setState(() {
        _cargandoSedes = false;
        _errorSedes = 'Error al cargar sedes: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoSedes) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorSedes != null || _selectedSede == null) {
      return Scaffold(
        body: Center(
          child: Text(_errorSedes ?? 'No hay sedes disponibles'),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentView: _currentView,
            onViewChange: (view) {
              if (_globalLoading) return; // bloquear cambios mientras carga
              setState(() {
                _currentView = view;
              });
            },
          ),
          Expanded(
            child: _buildView(),
          ),
        ],
      ),
    );
  }

  void _setGlobalLoading(bool value) {
    if (!mounted) return;

    if (value) {
      if (_globalLoading) return;
      _globalLoading = true;

      final overlay = Navigator.of(context, rootNavigator: true).overlay;
      if (overlay == null) return;

      _loadingOverlayEntry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );
      overlay.insert(_loadingOverlayEntry!);
    } else {
      if (!_globalLoading) return;
      _globalLoading = false;
      _loadingOverlayEntry?.remove();
      _loadingOverlayEntry = null;
    }

    setState(() {});
  }

  Widget _buildView() {
    switch (_currentView) {
      case ViewType.platos:
        return PlatosServidosScreen(selectedSede: _selectedSede!);
      case ViewType.inventario:
        return InventarioScreen(
          selectedSede: _selectedSede!,
          sedes: _sedes,
          setGlobalLoading: _setGlobalLoading,
          onSedeChange: (sede) {
            setState(() {
              _selectedSede = sede;
            });
          },
        );
      case ViewType.reportes:
        return ReportesScreen(selectedSede: _selectedSede!);
    }
  }
}
