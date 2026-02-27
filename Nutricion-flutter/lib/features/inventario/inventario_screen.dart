import 'package:flutter/material.dart';

import '../../app/models.dart';
import '../../app/widgets/page_header.dart';
import '../../app/api_client.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key, required this.selectedCasa});

  final Casa selectedCasa;

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
    if (oldWidget.selectedCasa.id != widget.selectedCasa.id) {
      _cargarDatosIniciales();
    }
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final sedeId = mapCasaToSedeId(widget.selectedCasa.nombre);

    try {
      final productosJson = await _apiClient.getJsonList(
        '/inventario/productos',
        query: {'sedeId': sedeId},
      );

      final historialJson = await _apiClient.getJsonList(
        '/inventario/historial',
        query: {'sedeId': sedeId},
      );

      final productos = productosJson
          .map((e) => _Producto(
                id: e['id'] as String,
                nombre: e['nombre'] as String,
                categoria: e['categoria'] as String,
                cantidad: (e['cantidadActual'] as num).toInt(),
                unidad: e['unidad'] as String,
                stockMinimo: (e['stockMinimo'] as num).toInt(),
                estado: e['estado'] as String,
              ))
          .toList();

      final transacciones = historialJson
          .map((e) => _Transaccion(
                id: e['id'] as String,
                fecha: (e['fecha'] as String?) ?? '',
                tipo: e['tipo'] as String,
                producto: e['producto'] as String,
                cantidad: (e['cantidad'] as num).toInt(),
                origen: e['origen'] as String?,
                destino: e['destino'] as String?,
                motivo: e['motivo'] as String? ?? '',
              ))
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
          selectedCasa: widget.selectedCasa,
          actions: FilledButton.icon(
            onPressed: _openNuevaTransaccion,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Transacción'),
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
                            '${filtered.length} productos en ${widget.selectedCasa.nombre}',
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
        final sedeId = mapCasaToSedeId(widget.selectedCasa.nombre);
        return _NuevaTransaccionDialog(
          productos: _productos,
          sedeId: sedeId,
          onSaved: _cargarDatosIniciales,
        );
      },
    );
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
    origen: 'Casa Principal',
    destino: 'Casa Ángeles',
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
    required this.onSaved,
  });

  final List<_Producto> productos;
  final String sedeId;
  final Future<void> Function() onSaved;

  @override
  State<_NuevaTransaccionDialog> createState() => _NuevaTransaccionDialogState();
}

class _NuevaTransaccionDialogState extends State<_NuevaTransaccionDialog> {
  String _tipo = 'entrada';
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  late String _productoSeleccionadoId;
  String _origenId = casas.first.id;
  String _destinoId = casas.length > 1 ? casas[1].id : casas.first.id;

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _productoSeleccionadoId =
        widget.productos.isNotEmpty ? widget.productos.first.id : '';
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Transacción'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  label: 'Salida',
                  value: 'salida',
                  groupValue: _tipo,
                  onChanged: _onTipoChanged,
                ),
                _TipoChip(
                  label: 'Transferencia',
                  value: 'transferencia',
                  groupValue: _tipo,
                  onChanged: _onTipoChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _productoSeleccionadoId.isEmpty
                  ? null
                  : _productoSeleccionadoId,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in widget.productos)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(p.nombre),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _productoSeleccionadoId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_tipo == 'transferencia') ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _origenId,
                      decoration: const InputDecoration(
                        labelText: 'Casa origen',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in casas)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _origenId = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _destinoId,
                      decoration: const InputDecoration(
                        labelText: 'Casa destino',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in casas)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _destinoId = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'La transacción se registrará en el sistema de inventario.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
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
    );
  }

  void _onTipoChanged(String value) {
    setState(() {
      _tipo = value;
    });
  }

  void _onSubmit() {
    final cantidad = int.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser un número mayor a 0.'),
        ),
      );
      return;
    }

    if (_productoSeleccionadoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto.')),
      );
      return;
    }

    final motivo = _motivoController.text.trim();

    () async {
      try {
        await _apiClient.postJson(
          '/inventario/movimiento',
          {
            'tipo': _tipo,
            'productoId': _productoSeleccionadoId,
            'sedeId': widget.sedeId,
            'cantidad': cantidad,
            'motivo': motivo.isEmpty ? null : motivo,
            'sedeOrigenId': _tipo == 'transferencia' ? _origenId : null,
            'sedeDestinoId': _tipo == 'transferencia' ? _destinoId : null,
          },
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción registrada correctamente.')),
        );

        await widget.onSaved();

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar transacción: $e')),
        );
      }
    }();
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

