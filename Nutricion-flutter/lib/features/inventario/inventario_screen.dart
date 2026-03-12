import 'package:flutter/material.dart';

import '../../app/models.dart';
import '../../app/widgets/page_header.dart';
import '../../app/api_client.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({
    super.key,
    required this.selectedSede,
    required this.sedes,
    required this.onSedeChange,
  });

  final Sede selectedSede;
  final List<Sede> sedes;
  final ValueChanged<Sede> onSedeChange;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;
  String _searchTerm = '';

  final ApiClient _apiClient = ApiClient();

  bool _cargando = true;
  String? _error;
  List<_Producto> _productos = const [];
  List<_Transaccion> _transacciones = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    _cargarDatosIniciales();
  }

  @override
  void didUpdateWidget(covariant InventarioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSede.id != widget.selectedSede.id) {
      _cargarDatosIniciales();
    }
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final sedeId = widget.selectedSede.id;

    try {
      final productosJson = await _apiClient.getJsonList(
        '/inventario/productos',
        query: {'sedeId': sedeId},
      );

      final historialJson = await _apiClient.getJsonList(
        '/inventario/historial',
        query: {'sedeId': sedeId},
      );

      final sedesById = {
        for (final s in widget.sedes) s.id: s.nombre,
      };

      final productos = productosJson
          .map((e) => _Producto(
                id: e['id'] as String,
                nombre: e['nombre'] as String,
                categoria: e['categoria'] as String,
                cantidad: (e['cantidadActual'] as num).toInt(),
                unidad: e['unidad'] as String,
                stockMinimo: (e['stockMinimo'] as num).toInt(),
                estado: _mapEstadoBackend(e['estado'] as String?),
              ))
          .toList();

      final transacciones = historialJson
          .map((e) {
            final fechaRaw = e['fecha'] as String?;
            final fecha = _formatFecha(fechaRaw);

            final origenId = e['origen'] as String?;
            final destinoId = e['destino'] as String?;

            final origenNombre = origenId != null
                ? (sedesById[origenId] ?? origenId)
                : null;
            final destinoNombre = destinoId != null
                ? (sedesById[destinoId] ?? destinoId)
                : null;

            return _Transaccion(
              id: e['id'] as String,
              fecha: fecha,
              tipo: e['tipo'] as String,
              producto: e['producto'] as String,
              cantidad: (e['cantidad'] as num).toInt(),
              origen: origenNombre,
              destino: destinoNombre,
              motivo: e['motivo'] as String? ?? '',
            );
          })
          .toList();

      setState(() {
        _productos = productos;
        _transacciones = transacciones;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error al cargar inventario: $e';
        // Si algo falla, dejamos los mocks como fallback visual
        _productos = _mockProductos;
        _transacciones = _mockTransacciones;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosStockBajo = _productos
        .where((p) => p.cantidad < p.stockMinimo)
        .toList(growable: false);

    final filtered = _productos.where((p) {
      final term = _searchTerm.toLowerCase();
      return p.nombre.toLowerCase().contains(term) ||
          p.categoria.toLowerCase().contains(term);
    }).toList(growable: false);

    return Column(
      children: [
        PageHeader(
          title: 'Inventario',
          description: 'Gestión de inventario y transacciones',
          selectedSede: widget.selectedSede,
          actions: FilledButton.icon(
            onPressed: _openNuevaTransaccion,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Transacción'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                value: widget.selectedSede.id,
                decoration: const InputDecoration(
                  labelText: 'Sede del inventario',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final sede in widget.sedes)
                    DropdownMenuItem<String>(
                      value: sede.id,
                      child: Text(sede.nombre),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  if (widget.sedes.isEmpty) return;
                  final sede = widget.sedes.firstWhere(
                    (s) => s.id == value,
                    orElse: () => widget.sedes.first,
                  );
                  widget.onSedeChange(sede);
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_cargando) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 24),
                ] else if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                ],
                if (productosStockBajo.isNotEmpty)
                  _StockAlert(productosStockBajo: productosStockBajo),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Productos en Stock',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${filtered.length} productos en ${widget.selectedSede.nombre}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Buscar producto...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchTerm = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _InventarioTabs(
                    currentIndex: _currentTabIndex,
                    onSelect: (index) {
                      _tabController.animateTo(index);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SizedBox(
                    height: 420,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _InventarioTable(productos: filtered),
                        _TransaccionesList(transacciones: _transacciones),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openNuevaTransaccion() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final sedeId = widget.selectedSede.id;
        final sedesDestino = widget.sedes
            .where((s) => s.id != widget.selectedSede.id)
            .toList(growable: false);
        return _NuevaTransaccionDialog(
          productos: _productos,
          sedeId: sedeId,
          sedesDestino: sedesDestino,
          onSaved: _cargarDatosIniciales,
        );
      },
    );
  }
}

String _mapEstadoBackend(String? raw) {
  switch (raw) {
    case 'STOCK_BAJO':
      return 'Stock Bajo';
    case 'NORMAL':
    default:
      return 'Normal';
  }
}

String _formatFecha(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  } catch (_) {
    return raw;
  }
}

class _Producto {
  const _Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.unidad,
    required this.stockMinimo,
    required this.estado,
  });

  final String id;
  final String nombre;
  final String categoria;
  final int cantidad;
  final String unidad;
  final int stockMinimo;
  final String estado;
}

class _Transaccion {
  const _Transaccion({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.producto,
    required this.cantidad,
    this.origen,
    this.destino,
    required this.motivo,
  });

  final String id;
  final String fecha;
  final String tipo; // 'entrada', 'salida', 'transferencia'
  final String producto;
  final int cantidad;
  final String? origen;
  final String? destino;
  final String motivo;
}

bool _esCategoriaViveres(String categoria) {
  final c = categoria.toLowerCase();
  return c.contains('viver');
}

bool _esCategoriaFrutasHortalizas(String categoria) {
  final c = categoria.toLowerCase();
  return c.contains('fruta') || c.contains('hortaliza') || c.contains('verdura');
}

const List<_Producto> _mockProductos = [
  _Producto(
    id: '1',
    nombre: 'Arroz',
    categoria: 'Granos',
    cantidad: 45,
    unidad: 'kg',
    stockMinimo: 30,
    estado: 'Normal',
  ),
  _Producto(
    id: '2',
    nombre: 'Frijoles',
    categoria: 'Granos',
    cantidad: 22,
    unidad: 'kg',
    stockMinimo: 20,
    estado: 'Normal',
  ),
  _Producto(
    id: '3',
    nombre: 'Aceite',
    categoria: 'Condimentos',
    cantidad: 15,
    unidad: 'L',
    stockMinimo: 10,
    estado: 'Normal',
  ),
  _Producto(
    id: '4',
    nombre: 'Azúcar',
    categoria: 'Endulzantes',
    cantidad: 18,
    unidad: 'kg',
    stockMinimo: 15,
    estado: 'Normal',
  ),
  _Producto(
    id: '5',
    nombre: 'Pasta',
    categoria: 'Granos',
    cantidad: 12,
    unidad: 'kg',
    stockMinimo: 20,
    estado: 'Stock Bajo',
  ),
  _Producto(
    id: '6',
    nombre: 'Leche en Polvo',
    categoria: 'Lácteos',
    cantidad: 8,
    unidad: 'kg',
    stockMinimo: 12,
    estado: 'Stock Bajo',
  ),
  _Producto(
    id: '7',
    nombre: 'Harina',
    categoria: 'Harinas',
    cantidad: 25,
    unidad: 'kg',
    stockMinimo: 15,
    estado: 'Normal',
  ),
  _Producto(
    id: '8',
    nombre: 'Tomate Enlatado',
    categoria: 'Conservas',
    cantidad: 30,
    unidad: 'latas',
    stockMinimo: 20,
    estado: 'Normal',
  ),
];
const List<_Transaccion> _mockTransacciones = [
  _Transaccion(
    id: '1',
    fecha: '2025-01-28',
    tipo: 'entrada',
    producto: 'Arroz',
    cantidad: 20,
    motivo: 'Compra mensual',
  ),
  _Transaccion(
    id: '2',
    fecha: '2025-01-28',
    tipo: 'salida',
    producto: 'Frijoles',
    cantidad: 5,
    motivo: 'Preparación almuerzo',
  ),
  _Transaccion(
    id: '3',
    fecha: '2025-01-27',
    tipo: 'transferencia',
    producto: 'Aceite',
    cantidad: 3,
    origen: 'Bambi Enlace',
    destino: 'Bambi II',
    motivo: 'Préstamo',
  ),
  _Transaccion(
    id: '4',
    fecha: '2025-01-27',
    tipo: 'entrada',
    producto: 'Azúcar',
    cantidad: 10,
    motivo: 'Donación',
  ),
  _Transaccion(
    id: '5',
    fecha: '2025-01-26',
    tipo: 'salida',
    producto: 'Pasta',
    cantidad: 8,
    motivo: 'Preparación cena',
  ),
];

class _StockAlert extends StatelessWidget {
  const _StockAlert({required this.productosStockBajo});

  final List<_Producto> productosStockBajo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerta: ${productosStockBajo.length} producto(s) con stock bajo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  productosStockBajo.map((p) => p.nombre).join(', '),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventarioTabs extends StatelessWidget {
  const _InventarioTabs({
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InventarioTabChip(
          label: 'Inventario Actual',
          isActive: currentIndex == 0,
          onTap: () => onSelect(0),
        ),
        const SizedBox(width: 16),
        _InventarioTabChip(
          label: 'Historial de Transacciones',
          isActive: currentIndex == 1,
          onTap: () => onSelect(1),
        ),
      ],
    );
  }
}

class _InventarioTabChip extends StatelessWidget {
  const _InventarioTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell
/*
ignore: prefer_const_constructors
*/
        (
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFFDF4) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF15803D) : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _InventarioTable extends StatelessWidget {
  const _InventarioTable({required this.productos});

  final List<_Producto> productos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Producto')),
            DataColumn(label: Text('Categoría')),
            DataColumn(label: Text('Cantidad')),
            DataColumn(label: Text('Stock mínimo')),
            DataColumn(label: Text('Estado')),
          ],
          rows: [
            for (final p in productos)
              DataRow(
                cells: [
                  DataCell(Text(p.nombre)),
                  DataCell(Text(p.categoria)),
                  DataCell(Text('${p.cantidad} ${p.unidad}')),
                  DataCell(Text('${p.stockMinimo} ${p.unidad}')),
                  DataCell(_EstadoChip(estado: p.estado)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color textColor;

    switch (estado) {
      case 'Stock Bajo':
        background = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        break;
      default:
        background = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF15803D);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _TransaccionesList extends StatelessWidget {
  const _TransaccionesList({required this.transacciones});

  final List<_Transaccion> transacciones;

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return const Color(0xFF16A34A);
      case 'salida':
        return const Color(0xFFDC2626);
      case 'transferencia':
        return const Color(0xFF2563EB);
      case 'ajuste':
        return const Color(0xFFF97316);
      default:
        return Colors.grey;
    }
  }

  String _labelForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      case 'transferencia':
        return 'Transferencia';
      case 'ajuste':
        return 'Ajuste';
      default:
        return tipo;
    }
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return Icons.arrow_downward;
      case 'salida':
        return Icons.arrow_upward;
      case 'transferencia':
        return Icons.swap_horiz;
      case 'ajuste':
        return Icons.rule_folder;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transacciones.length,
      itemBuilder: (context, index) {
        final t = transacciones[index];
        final color = _colorForTipo(t.tipo);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(_iconForTipo(t.tipo), color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.producto,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.motivo,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    if (t.origen != null || t.destino != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${t.origen ?? '-'} → ${t.destino ?? '-'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${t.cantidad}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.fecha,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _labelForTipo(t.tipo),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NuevaTransaccionDialog extends StatefulWidget {
  const _NuevaTransaccionDialog({
    required this.productos,
    required this.sedeId,
    required this.sedesDestino,
    required this.onSaved,
  });

  final List<_Producto> productos;
  final String sedeId;
  final List<Sede> sedesDestino;
  final Future<void> Function() onSaved;

  @override
  State<_NuevaTransaccionDialog> createState() => _NuevaTransaccionDialogState();
}

class _NuevaTransaccionDialogState extends State<_NuevaTransaccionDialog> {
  String _tipo = 'entrada';
  final TextEditingController _motivoEntradaController =
      TextEditingController();
  final TextEditingController _motivoTransferenciaController =
      TextEditingController();
  final TextEditingController _motivoAjusteController =
      TextEditingController();

    final TextEditingController _busquedaProductoController =
      TextEditingController();
    String _terminoBusquedaProducto = '';

  // Para entradas: cantidad por producto
  final Map<String, String> _cantidadesEntrada = {};

  // Para transferencias: producto y sede destino
  late String _productoSeleccionadoId;
  String? _sedeDestinoId;

  // Para ajustes: cantidad final (conteo real) por producto
  final Map<String, String> _cantidadesAjuste = {};

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _productoSeleccionadoId =
        widget.productos.isNotEmpty ? widget.productos.first.id : '';
    if (widget.sedesDestino.isNotEmpty) {
      _sedeDestinoId = widget.sedesDestino.first.id;
    }
  }

  @override
  void dispose() {
    _motivoEntradaController.dispose();
    _motivoTransferenciaController.dispose();
    _motivoAjusteController.dispose();
    _busquedaProductoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontSizeFactor: 1.2),
      ),
      child: AlertDialog(
        title: const Text('Registrar Transacción'),
        content: SizedBox(
          width: 1100,
          height: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de transacción'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _TipoChip(
                  label: 'Entrada',
                  value: 'entrada',
                  groupValue: _tipo,
                  onChanged: _onTipoChanged,
                ),
                _TipoChip(
                  label: 'Transferencia a otra sede',
                  value: 'transferencia',
                  groupValue: _tipo,
                  onChanged: _onTipoChanged,
                ),
                _TipoChip(
                  label: 'Ajuste de inventario',
                  value: 'ajuste',
                  groupValue: _tipo,
                  onChanged: _onTipoChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tipo == 'entrada' || _tipo == 'ajuste') ...[
              TextField(
                controller: _busquedaProductoController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar rubro por nombre...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _terminoBusquedaProducto = value;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_tipo == 'entrada') {
                    return _EntradaForm(
                      productos: widget.productos,
                      cantidadesEntrada: _cantidadesEntrada,
                      motivoController: _motivoEntradaController,
                      terminoBusqueda: _terminoBusquedaProducto,
                    );
                  }
                  if (_tipo == 'transferencia') {
                    return _TransferenciaForm(
                      productos: widget.productos,
                      productoSeleccionadoId: _productoSeleccionadoId,
                      onProductoChanged: (value) {
                        setState(() {
                          _productoSeleccionadoId = value;
                        });
                      },
                      sedesDestino: widget.sedesDestino,
                      sedeDestinoId: _sedeDestinoId,
                      onSedeDestinoChanged: (value) {
                        setState(() {
                          _sedeDestinoId = value;
                        });
                      },
                      motivoController: _motivoTransferenciaController,
                    );
                  }
                  return _AjusteForm(
                    productos: widget.productos,
                    cantidadesAjuste: _cantidadesAjuste,
                    motivoController: _motivoAjusteController,
                    terminoBusqueda: _terminoBusquedaProducto,
                  );
                },
              ),
            ),
          ],
        ),
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _onSubmit,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _onTipoChanged(String value) {
    setState(() {
      _tipo = value;
    });
  }

  void _onSubmit() {
    if (_tipo == 'entrada') {
      // Preparar una lista de movimientos de entrada (uno por producto con cantidad > 0)
      final movimientos = <Future<void>>[];

      for (final p in widget.productos) {
        final raw = _cantidadesEntrada[p.id]?.trim();
        if (raw == null || raw.isEmpty) continue;
        final cantidad = int.tryParse(raw);
        if (cantidad == null || cantidad <= 0) continue;

        final motivo = _motivoEntradaController.text.trim();

        movimientos.add(_apiClient.postJson(
          '/inventario/movimiento',
          {
            'tipo': 'entrada',
            'productoId': p.id,
            'sedeId': widget.sedeId,
            'cantidad': cantidad,
            'motivo': motivo.isEmpty ? null : motivo,
            'sedeOrigenId': null,
            'sedeDestinoId': null,
          },
        ));
      }

      if (movimientos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa al menos una cantidad válida para registrar una entrada.'),
          ),
        );
        return;
      }

      () async {
        try {
          await Future.wait(movimientos);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entradas registradas correctamente.')),
          );

          await widget.onSaved();

          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar entradas: $e')),
          );
        }
      }();
    } else if (_tipo == 'transferencia') {
      if (_productoSeleccionadoId.isEmpty || _sedeDestinoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un producto y una sede destino.'),
          ),
        );
        return;
      }

      final motivo = _motivoTransferenciaController.text.trim();
      final sedeDestinoId = _sedeDestinoId!;

      () async {
        try {
          await _apiClient.postJson(
            '/inventario/movimiento',
            {
              'tipo': 'transferencia',
              'productoId': _productoSeleccionadoId,
              'sedeId': widget.sedeId,
              'cantidad': 0, // se calculará en el backend
              'motivo': motivo.isEmpty ? null : motivo,
              'sedeOrigenId': widget.sedeId,
              'sedeDestinoId': sedeDestinoId,
            },
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transferencia registrada correctamente.')),
          );

          await widget.onSaved();

          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar transferencia: $e')),
          );
        }
      }();
    } else if (_tipo == 'ajuste') {
      // Ajuste: para cada producto al que se le indique un conteo,
      // se ajusta el inventario a esa cantidad final.
      final movimientos = <Future<void>>[];

      for (final p in widget.productos) {
        final raw = _cantidadesAjuste[p.id]?.trim();
        if (raw == null || raw.isEmpty) continue;
        final cantidadFinal = int.tryParse(raw);
        if (cantidadFinal == null || cantidadFinal < 0) continue;

        // Validación básica en front: no permitir valores mayores al inventario actual
        if (cantidadFinal > p.cantidad) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El conteo para ${p.nombre} no puede ser mayor que la cantidad actual (${p.cantidad}).',
              ),
            ),
          );
          return;
        }

        final motivo = _motivoAjusteController.text.trim();

        movimientos.add(_apiClient.postJson(
          '/inventario/movimiento',
          {
            'tipo': 'ajuste',
            'productoId': p.id,
            'sedeId': widget.sedeId,
            // El backend interpreta "cantidad" como cantidad final deseada para el ajuste.
            'cantidad': cantidadFinal,
            'motivo': motivo.isEmpty ? null : motivo,
            'sedeOrigenId': null,
            'sedeDestinoId': null,
          },
        ));
      }

      if (movimientos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa al menos un conteo válido para registrar un ajuste.'),
          ),
        );
        return;
      }

      () async {
        try {
          await Future.wait(movimientos);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajustes registrados correctamente.')),
          );

          await widget.onSaved();

          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar ajustes: $e')),
          );
        }
      }();
    }
  }
}

class _EntradaForm extends StatelessWidget {
  const _EntradaForm({
    required this.productos,
    required this.cantidadesEntrada,
    required this.motivoController,
    required this.terminoBusqueda,
  });

  final List<_Producto> productos;
  final Map<String, String> cantidadesEntrada;
  final TextEditingController motivoController;
  final String terminoBusqueda;

  @override
  Widget build(BuildContext context) {
    final List<_Producto> viveres = [];
    final List<_Producto> frutasYHortalizas = [];
    final List<_Producto> otros = [];

    final filtro = terminoBusqueda.toLowerCase().trim();

    for (final p in productos) {
      final coincideBusqueda =
          filtro.isEmpty || p.nombre.toLowerCase().contains(filtro);
      if (!coincideBusqueda) continue;

      if (_esCategoriaViveres(p.categoria)) {
        viveres.add(p);
      } else if (_esCategoriaFrutasHortalizas(p.categoria)) {
        frutasYHortalizas.add(p);
      } else {
        otros.add(p);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cantidades compradas por producto'),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ColumnaCategoriaEntrada(
                  titulo: 'Víveres',
                  productos: viveres,
                  cantidadesEntrada: cantidadesEntrada,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColumnaCategoriaEntrada(
                  titulo: 'Frutas y hortalizas',
                  productos: frutasYHortalizas,
                  cantidadesEntrada: cantidadesEntrada,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColumnaCategoriaEntrada(
                  titulo: 'Otros',
                  productos: otros,
                  cantidadesEntrada: cantidadesEntrada,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: motivoController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional, se aplicará a todos)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Se registrará una entrada por cada producto con cantidad > 0.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _TransferenciaForm extends StatelessWidget {
  const _TransferenciaForm({
    required this.productos,
    required this.productoSeleccionadoId,
    required this.onProductoChanged,
    required this.sedesDestino,
    required this.sedeDestinoId,
    required this.onSedeDestinoChanged,
    required this.motivoController,
  });

  final List<_Producto> productos;
  final String productoSeleccionadoId;
  final ValueChanged<String> onProductoChanged;
  final List<Sede> sedesDestino;
  final String? sedeDestinoId;
  final ValueChanged<String?> onSedeDestinoChanged;
  final TextEditingController motivoController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: productoSeleccionadoId.isEmpty ? null : productoSeleccionadoId,
          decoration: const InputDecoration(
            labelText: 'Producto a transferir',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final p in productos)
              DropdownMenuItem(
                value: p.id,
                child: Text(p.nombre),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onProductoChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: sedeDestinoId,
          decoration: const InputDecoration(
            labelText: 'Sede destino',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final s in sedesDestino)
              DropdownMenuItem(
                value: s.id,
                child: Text(s.nombre),
              ),
          ],
          onChanged: (value) {
            onSedeDestinoChanged(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: motivoController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Se calculará automáticamente la cantidad a transferir según el stock mínimo en la sede destino. '
          'Esa cantidad se restará del inventario de la sede actual y se sumará al inventario de la sede destino.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _AjusteForm extends StatelessWidget {
  const _AjusteForm({
    required this.productos,
    required this.cantidadesAjuste,
    required this.motivoController,
    required this.terminoBusqueda,
  });

  final List<_Producto> productos;
  final Map<String, String> cantidadesAjuste;
  final TextEditingController motivoController;
  final String terminoBusqueda;

  @override
  Widget build(BuildContext context) {
    final List<_Producto> viveres = [];
    final List<_Producto> frutasYHortalizas = [];
    final List<_Producto> otros = [];

    final filtro = terminoBusqueda.toLowerCase().trim();

    for (final p in productos) {
      final coincideBusqueda =
          filtro.isEmpty || p.nombre.toLowerCase().contains(filtro);
      if (!coincideBusqueda) continue;

      if (_esCategoriaViveres(p.categoria)) {
        viveres.add(p);
      } else if (_esCategoriaFrutasHortalizas(p.categoria)) {
        frutasYHortalizas.add(p);
      } else {
        otros.add(p);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Conteo real por producto'),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ColumnaCategoriaAjuste(
                  titulo: 'Víveres',
                  productos: viveres,
                  cantidadesAjuste: cantidadesAjuste,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColumnaCategoriaAjuste(
                  titulo: 'Frutas y hortalizas',
                  productos: frutasYHortalizas,
                  cantidadesAjuste: cantidadesAjuste,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColumnaCategoriaAjuste(
                  titulo: 'Otros',
                  productos: otros,
                  cantidadesAjuste: cantidadesAjuste,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: motivoController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional, se aplicará a todos)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Se registrará un ajuste por cada producto con conteo ingresado. '
          'En el historial verás como "cantidad" la diferencia entre el inventario anterior y el conteo real.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _ColumnaCategoriaEntrada extends StatelessWidget {
  const _ColumnaCategoriaEntrada({
    required this.titulo,
    required this.productos,
    required this.cantidadesEntrada,
  });

  final String titulo;
  final List<_Producto> productos;
  final Map<String, String> cantidadesEntrada;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final p = productos[index];
              final key = p.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(p.nombre),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cant.',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          cantidadesEntrada[key] = value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColumnaCategoriaAjuste extends StatelessWidget {
  const _ColumnaCategoriaAjuste({
    required this.titulo,
    required this.productos,
    required this.cantidadesAjuste,
  });

  final String titulo;
  final List<_Producto> productos;
  final Map<String, String> cantidadesAjuste;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final p = productos[index];
              final key = p.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre),
                          const SizedBox(height: 2),
                          Text(
                            'Actual: ${p.cantidad} ${p.unidad}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Conteo',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          cantidadesAjuste[key] = value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TipoChip extends StatelessWidget {
  const _TipoChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(value),
    );
  }
}

