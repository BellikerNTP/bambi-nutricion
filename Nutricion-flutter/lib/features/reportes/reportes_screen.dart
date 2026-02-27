import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/models.dart';
import '../../app/widgets/page_header.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key, required this.selectedCasa});

  final Casa selectedCasa;

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  String _mesSeleccionado = '2025-01';
  String _cargoSeleccionado = 'todos';
  String _casaComparacion = '';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _getMockReportData();

    return Column(
      children: [
        PageHeader(
          title: 'Reportes',
          description: 'Visualización y generación de reportes',
          selectedCasa: widget.selectedCasa,
          actions: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte exportado a Excel (simulado).'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            icon: const Icon(Icons.download),
            label: const Text('Exportar a Excel'),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _FiltrosSection(
                  mesSeleccionado: _mesSeleccionado,
                  cargoSeleccionado: _cargoSeleccionado,
                  casaComparacion: _casaComparacion,
                  onMesChanged: (v) => setState(() => _mesSeleccionado = v),
                  onCargoChanged: (v) => setState(() => _cargoSeleccionado = v),
                  onCasaComparacionChanged: (v) => setState(() => _casaComparacion = v),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.green.shade700,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: Colors.green.shade700,
                        tabs: const [
                          Tab(text: 'Resumen general'),
                          Tab(text: 'Detalles por cargo'),
                        ],
                      ),
                      SizedBox(
                        height: 520,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _ResumenGeneralTab(data: data),
                            _PorCargoTab(data: data),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportData {
  _ReportData({
    required this.platosPorMes,
    required this.gastoPorCategoria,
    required this.consumoDiario,
    required this.platosPorCargo,
  });

  final List<Map<String, dynamic>> platosPorMes;
  final List<Map<String, dynamic>> gastoPorCategoria;
  final List<Map<String, dynamic>> consumoDiario;
  final List<Map<String, dynamic>> platosPorCargo;
}

_ReportData _getMockReportData() {
  return _ReportData(
    platosPorMes: const [
      {
        'mes': 'Ene',
        'desayuno': 620,
        'almuerzo': 620,
        'cena': 620,
        'meriendas': 410,
      },
      {
        'mes': 'Feb',
        'desayuno': 580,
        'almuerzo': 580,
        'cena': 580,
        'meriendas': 390,
      },
      {
        'mes': 'Mar',
        'desayuno': 650,
        'almuerzo': 650,
        'cena': 650,
        'meriendas': 425,
      },
      {
        'mes': 'Abr',
        'desayuno': 610,
        'almuerzo': 610,
        'cena': 610,
        'meriendas': 405,
      },
    ],
    gastoPorCategoria: const [
      {
        'categoria': 'Granos y Cereales',
        'valor': 1200.0,
        'porcentaje': 30,
      },
      {
        'categoria': 'Proteínas',
        'valor': 1600.0,
        'porcentaje': 40,
      },
      {
        'categoria': 'Verduras y Frutas',
        'valor': 800.0,
        'porcentaje': 20,
      },
      {
        'categoria': 'Lácteos',
        'valor': 400.0,
        'porcentaje': 10,
      },
    ],
    consumoDiario: const [
      {'dia': 'Lun 20', 'gasto': 145.0},
      {'dia': 'Mar 21', 'gasto': 160.0},
      {'dia': 'Mié 22', 'gasto': 138.0},
      {'dia': 'Jue 23', 'gasto': 155.0},
      {'dia': 'Vie 24', 'gasto': 142.0},
      {'dia': 'Sáb 25', 'gasto': 128.0},
      {'dia': 'Dom 26', 'gasto': 135.0},
    ],
    platosPorCargo: const [
      {'cargo': 'Niños', 'cantidad': 1850, 'porcentaje': 65},
      {'cargo': 'Personal', 'cantidad': 450, 'porcentaje': 16},
      {'cargo': 'Visitas', 'cantidad': 280, 'porcentaje': 10},
      {'cargo': 'Voluntarios', 'cantidad': 270, 'porcentaje': 9},
    ],
  );
}

class _FiltrosSection extends StatelessWidget {
  const _FiltrosSection({
    required this.mesSeleccionado,
    required this.cargoSeleccionado,
    required this.casaComparacion,
    required this.onMesChanged,
    required this.onCargoChanged,
    required this.onCasaComparacionChanged,
  });

  final String mesSeleccionado;
  final String cargoSeleccionado;
  final String casaComparacion;
  final ValueChanged<String> onMesChanged;
  final ValueChanged<String> onCargoChanged;
  final ValueChanged<String> onCasaComparacionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Text(
                'Filtros',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isWide ? 260 : constraints.maxWidth,
                    child: DropdownButtonFormField<String>(
                      value: mesSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '2025-01', child: Text('Enero 2025')),
                        DropdownMenuItem(value: '2025-02', child: Text('Febrero 2025')),
                        DropdownMenuItem(value: '2025-03', child: Text('Marzo 2025')),
                        DropdownMenuItem(value: '2025-04', child: Text('Abril 2025')),
                        DropdownMenuItem(value: '2025-05', child: Text('Mayo 2025')),
                      ],
                      onChanged: (value) {
                        if (value != null) onMesChanged(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 260 : constraints.maxWidth,
                    child: DropdownButtonFormField<String>(
                      value: cargoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Cargo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'ninos', child: Text('Niños')),
                        DropdownMenuItem(value: 'personal', child: Text('Personal')),
                        DropdownMenuItem(value: 'visitas', child: Text('Visitas')),
                        DropdownMenuItem(value: 'voluntarios', child: Text('Voluntarios')),
                      ],
                      onChanged: (value) {
                        if (value != null) onCargoChanged(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 260 : constraints.maxWidth,
                    child: TextFormField(
                      initialValue: casaComparacion,
                      decoration: const InputDecoration(
                        labelText: 'Comparar con otra casa (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: onCasaComparacionChanged,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResumenGeneralTab extends StatelessWidget {
  const _ResumenGeneralTab({required this.data});

  final _ReportData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _CardContainer(
                    title: 'Platos por mes',
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= data.platosPorMes.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    data.platosPorMes[index]['mes'] as String,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < data.platosPorMes.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: (data.platosPorMes[i]['desayuno'] as num).toDouble(),
                                  color: const Color(0xFF10B981),
                                  width: 6,
                                ),
                                BarChartRodData(
                                  toY: (data.platosPorMes[i]['almuerzo'] as num).toDouble(),
                                  color: const Color(0xFF3B82F6),
                                  width: 6,
                                ),
                                BarChartRodData(
                                  toY: (data.platosPorMes[i]['cena'] as num).toDouble(),
                                  color: const Color(0xFFF59E0B),
                                  width: 6,
                                ),
                                BarChartRodData(
                                  toY: (data.platosPorMes[i]['meriendas'] as num).toDouble(),
                                  color: const Color(0xFF8B5CF6),
                                  width: 6,
                                ),
                              ],
                              barsSpace: 2,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardContainer(
                    title: 'Gasto por categoría',
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (var i = 0; i < data.gastoPorCategoria.length; i++)
                            PieChartSectionData(
                              color: [
                                const Color(0xFF10B981),
                                const Color(0xFF3B82F6),
                                const Color(0xFFF59E0B),
                                const Color(0xFF8B5CF6),
                              ][i],
                              value: (data.gastoPorCategoria[i]['valor'] as num).toDouble(),
                              title:
                                  '${data.gastoPorCategoria[i]['porcentaje']}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _CardContainer(
              title: 'Consumo diario',
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.consumoDiario.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              data.consumoDiario[index]['dia'] as String,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      spots: [
                        for (var i = 0; i < data.consumoDiario.length; i++)
                          FlSpot(
                            i.toDouble(),
                            (data.consumoDiario[i]['gasto'] as num).toDouble(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PorCargoTab extends StatelessWidget {
  const _PorCargoTab({required this.data});

  final _ReportData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: _CardContainer(
              title: 'Platos por cargo',
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.platosPorCargo.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              data.platosPorCargo[index]['cargo'] as String,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < data.platosPorCargo.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (data.platosPorCargo[i]['cantidad'] as num).toDouble(),
                            color: const Color(0xFF3B82F6),
                            width: 14,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _CardContainer(
              title: 'Detalle porcentual',
              child: ListView.builder(
                itemCount: data.platosPorCargo.length,
                itemBuilder: (context, index) {
                  final item = data.platosPorCargo[index];
                  return ListTile(
                    title: Text(item['cargo'] as String),
                    subtitle: Text(
                      '${item['cantidad']} platos',
                    ),
                    trailing: Text(
                      '${item['porcentaje']}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

