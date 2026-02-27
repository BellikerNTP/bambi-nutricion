import 'package:flutter/material.dart';
import '../features/inventario/inventario_screen.dart';
import '../features/platos_servidos/platos_servidos_screen.dart';
import 'models.dart';
import 'widgets/sidebar.dart';

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
  Casa _selectedCasa = casas.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentView: _currentView,
            onViewChange: (view) {
              setState(() {
                _currentView = view;
              });
            },
            selectedCasa: _selectedCasa,
            onCasaChange: (casa) {
              setState(() {
                _selectedCasa = casa;
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

  Widget _buildView() {
    switch (_currentView) {
      case ViewType.platos:
        return PlatosServidosScreen(selectedCasa: _selectedCasa);
      case ViewType.inventario:
        return InventarioScreen(selectedCasa: _selectedCasa);
    }
  }
}
