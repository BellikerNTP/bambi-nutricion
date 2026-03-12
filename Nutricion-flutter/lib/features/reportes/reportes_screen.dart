import 'package:flutter/material.dart';

import '../../app/models.dart';
import '../../app/widgets/page_header.dart';
import '../../app/api_client.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key, required this.selectedSede});

  final Sede selectedSede;

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    {
  late DateTime _desde;
  late DateTime _hasta;

  final ApiClient _apiClient = ApiClient();
  bool _cargando = true;
  String? _error;
  List<Sede> _sedes = const [];
  List<_CategoriaResumenPlatos> _categorias = const [];
  List<_TipoPlatoResumen> _tiposPlato = const [];
  int _totalGeneralTipos = 0;
  Map<String, int> _totalTiposPorSede = const {};

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    _desde = DateTime(prevMonth.year, prevMonth.month, 1);
    final ultimoDia = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
    _hasta = DateTime(prevMonth.year, prevMonth.month, ultimoDia);

    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Reportes',
          description: 'Resumen de platos servidos por rango de fechas',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFiltrosFechas(),
                const SizedBox(height: 16),
                _buildResumenPlatos(),
                const SizedBox(height: 16),
                _buildResumenPorTipoPlato(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final sedesJson = await _apiClient.getJsonList(
        '/sedes',
        query: {'activa': 'true'},
      );
      final sedes = sedesJson
          .map((e) => Sede.fromJson(e as Map<String, dynamic>))
          .toList();

      final resumen = await _apiClient.getJsonObject(
        '/reportes/platos-servidos',
        query: {
          'desde': _desde.toIso8601String(),
          'hasta': _hasta.toIso8601String(),
        },
      );

      final categoriasJson = resumen['categorias'] as List<dynamic>? ?? const [];
      final categorias = categoriasJson.map((e) {
        final map = e as Map<String, dynamic>;
        final codigo = map['codigo'] as String;
        final nombre = map['nombre'] as String;
        final total = (map['total'] as num?)?.toInt() ?? 0;
        final porSedeList = map['porSede'] as List<dynamic>? ?? const [];
        final porSede = <String, int>{};
        for (final item in porSedeList) {
          final m = item as Map<String, dynamic>;
          final sedeId = m['sedeId'] as String;
          final cant = (m['cantidad'] as num?)?.toInt() ?? 0;
          porSede[sedeId] = cant;
        }
        return _CategoriaResumenPlatos(
          codigo: codigo,
          nombre: nombre,
          total: total,
          porSede: porSede,
        );
      }).toList();

      final resumenTipos = await _apiClient.getJsonObject(
        '/reportes/platos-por-tipo',
        query: {
          'desde': _desde.toIso8601String(),
          'hasta': _hasta.toIso8601String(),
        },
      );

      final tiposJson = resumenTipos['tipos'] as List<dynamic>? ?? const [];
      final tiposPlato = tiposJson.map((e) {
        final map = e as Map<String, dynamic>;
        final codigo = map['codigo'] as String;
        final nombre = map['nombre'] as String;
        final total = (map['total'] as num?)?.toInt() ?? 0;
        final porSedeList = map['porSede'] as List<dynamic>? ?? const [];
        final porSede = <String, int>{};
        for (final item in porSedeList) {
          final m = item as Map<String, dynamic>;
          final sedeId = m['sedeId'] as String;
          final cant = (m['cantidad'] as num?)?.toInt() ?? 0;
          porSede[sedeId] = cant;
        }
        return _TipoPlatoResumen(
          codigo: codigo,
          nombre: nombre,
          total: total,
          porSede: porSede,
        );
      }).toList();

      final totalGeneralTipos = (resumenTipos['totalGeneral'] as num?)?.toInt() ?? 0;
      final totalPorSedeList = resumenTipos['totalPorSede'] as List<dynamic>? ?? const [];
      final totalTiposPorSede = <String, int>{};
      for (final item in totalPorSedeList) {
        final m = item as Map<String, dynamic>;
        final sedeId = m['sedeId'] as String;
        final cant = (m['cantidad'] as num?)?.toInt() ?? 0;
        totalTiposPorSede[sedeId] = cant;
      }

      setState(() {
        _sedes = sedes;
        _categorias = categorias;
        _tiposPlato = tiposPlato;
        _totalGeneralTipos = totalGeneralTipos;
        _totalTiposPorSede = totalTiposPorSede;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error al cargar reporte: $e';
        _sedes = const [];
        _categorias = const [];
        _tiposPlato = const [];
        _totalGeneralTipos = 0;
        _totalTiposPorSede = const {};
      });
    }
  }

  Widget _buildFiltrosFechas() {
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
          Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Text(
                'Rango de fechas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Recargar',
                icon: const Icon(Icons.refresh),
                onPressed: _cargarDatos,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _desde,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _desde = picked;
                      });
                      await _cargarDatos();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Desde',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_desde.year}-${_desde.month.toString().padLeft(2, '0')}-${_desde.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _hasta,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _hasta = picked;
                      });
                      await _cargarDatos();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_hasta.year}-${_hasta.month.toString().padLeft(2, '0')}-${_hasta.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenPlatos() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Text(
        _error!,
        style: const TextStyle(color: Colors.red),
      );
    }
    if (_categorias.isEmpty || _sedes.isEmpty) {
      return const Text('No hay datos de platos servidos para este rango.');
    }

    final categoriasOrden = <String>['NINOS', 'TIAS', 'ADULTOS_IMPORTANTES', 'ADULTOS_SECUNDARIOS'];
    final categoriasMap = {for (final c in _categorias) c.codigo: c};

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
          const Text(
            'Platos servidos por categoría y sede',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Categoría')),
                const DataColumn(label: Text('Total')),
                for (final sede in _sedes)
                  DataColumn(label: Text(sede.nombre)),
              ],
              rows: [
                for (final codigo in categoriasOrden)
                  if (categoriasMap[codigo] != null)
                    _buildDataRow(categoriasMap[codigo]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(_CategoriaResumenPlatos categoria) {
    return DataRow(
      cells: [
        DataCell(Text(categoria.nombre)),
        DataCell(Text('${categoria.total}')),
        for (final sede in _sedes)
          DataCell(Text('${categoria.porSede[sede.id] ?? 0}')),
      ],
    );
  }
  Widget _buildResumenPorTipoPlato() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return const SizedBox.shrink();
    }
    if (_tiposPlato.isEmpty || _sedes.isEmpty) {
      return const Text('No hay datos por tipo de plato para este rango.');
    }

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
          const Text(
            'Platos servidos por tipo de plato y sede',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Tipo de plato')),
                const DataColumn(label: Text('Total')),
                for (final sede in _sedes)
                  DataColumn(label: Text(sede.nombre)),
              ],
              rows: [
                for (final tipo in _tiposPlato)
                  DataRow(
                    cells: [
                      DataCell(Text(tipo.nombre)),
                      DataCell(Text('${tipo.total}')),
                      for (final sede in _sedes)
                        DataCell(Text('${tipo.porSede[sede.id] ?? 0}')),
                    ],
                  ),
                DataRow(
                  cells: [
                    const DataCell(Text(
                      'TOTAL GENERAL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )),
                    DataCell(Text(
                      '$_totalGeneralTipos',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                    for (final sede in _sedes)
                      DataCell(Text(
                        '${_totalTiposPorSede[sede.id] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _CategoriaResumenPlatos {
  const _CategoriaResumenPlatos({
    required this.codigo,
    required this.nombre,
    required this.total,
    required this.porSede,
  });

  final String codigo;
  final String nombre;
  final int total;
  final Map<String, int> porSede;
}

class _TipoPlatoResumen {
  const _TipoPlatoResumen({
    required this.codigo,
    required this.nombre,
    required this.total,
    required this.porSede,
  });

  final String codigo;
  final String nombre;
  final int total;
  final Map<String, int> porSede;
}

