import 'package:flutter/material.dart';

import '../../app/api_client.dart';
import '../../app/models.dart';
import '../../app/widgets/page_header.dart';

class PlatosServidosScreen extends StatefulWidget {
  const PlatosServidosScreen({super.key, required this.selectedSede});

  final Sede selectedSede;

  @override
  State<PlatosServidosScreen> createState() => _PlatosServidosScreenState();
}

class _PlatosServidosScreenState extends State<PlatosServidosScreen> {
  int _currentStep = 0;

  bool _showForm = false;

  DateTime _fecha = DateTime.now();
  String _cargo = '';
  String _nombrePlato = '';
  String _cantidadPersonas = '';
  String _observaciones = '';

  final ApiClient _apiClient = ApiClient();
  bool _cargandoHistorial = true;
  List<_PlatoHistorial> _historial = const [];
  bool _cargandoIngredientes = true;
  List<_ProductoInventario> _productosDisponibles = const [];
  final List<_IngredienteSeleccionado> _ingredientesSeleccionados = [];

  // Nueva configuración: cargos x sedes
  bool _cargandoConfig = true;
  String? _errorConfig;
  List<Sede> _sedesConfig = const [];
  List<_CargoConfig> _cargosConfig = const [];
  final ScrollController _tablaHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarConfiguracionCargosYSedes();
  }

  @override
  void didUpdateWidget(covariant PlatosServidosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSede.id != widget.selectedSede.id) {
      // La configuración de cargos x sedes es global, pero por si acaso
      // recargamos cuando cambie la sede seleccionada.
      _cargarConfiguracionCargosYSedes();
    }
  }

  @override
  void dispose() {
    _tablaHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Platos Servidos',
          description: 'Configuración de cargos contados por sede',
          selectedSede: widget.selectedSede,
          actions: Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _abrirRegistrarComida,
                icon: const Icon(Icons.restaurant),
                label: const Text('Registrar comida'),
              ),
              OutlinedButton.icon(
                onPressed: _abrirEditarCargos,
                icon: const Icon(Icons.edit),
                label: const Text('Editar cargos'),
              ),
              OutlinedButton.icon(
                onPressed: _abrirNuevoCargo,
                icon: const Icon(Icons.add),
                label: const Text('Agregar cargo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildTablaCargosPorSede(),
          ),
        ),
      ],
    );
  }

  void _abrirRegistrarComida() {
    if (_sedesConfig.isEmpty || _cargosConfig.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return _RegistrarComidaDialog(
          sedes: _sedesConfig,
          cargos: _cargosConfig,
          apiClient: _apiClient,
          sedeInicial: widget.selectedSede,
        );
      },
    );
  }

  void _abrirEditarCargos() {
    if (_cargosConfig.isEmpty || _sedesConfig.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return _EditarCargosDialog(
          cargos: _cargosConfig,
          sedes: _sedesConfig,
          apiClient: _apiClient,
          onSaved: _cargarConfiguracionCargosYSedes,
        );
      },
    );
  }

  void _abrirNuevoCargo() {
    if (_sedesConfig.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return _NuevoCargoDialog(
          sedes: _sedesConfig,
          apiClient: _apiClient,
          onSaved: _cargarConfiguracionCargosYSedes,
        );
      },
    );
  }

  Future<void> _cargarConfiguracionCargosYSedes() async {
    setState(() {
      _cargandoConfig = true;
      _errorConfig = null;
    });

    try {
      final sedesJson = await _apiClient.getJsonList(
        '/sedes',
        query: {'activa': 'true'},
      );
      final cargosJson = await _apiClient.getJsonList('/cargos');

      final sedes = sedesJson
          .map((e) => Sede.fromJson(e as Map<String, dynamic>))
          .toList();

      final cargos = cargosJson
          .map((e) => _CargoConfig(
                id: e['id'] as String,
                nombre: e['nombre'] as String,
                tipo: (e['tipo'] as num?)?.toInt() ?? 0,
                sedes: List<String>.from(e['sedes'] as List? ?? const []),
              ))
          .toList();

      setState(() {
        _sedesConfig = sedes;
        _cargosConfig = cargos;
        _cargandoConfig = false;
      });
    } catch (e) {
      setState(() {
        _cargandoConfig = false;
        _errorConfig = 'Error al cargar configuración de cargos: $e';
        _sedesConfig = const [];
        _cargosConfig = const [];
      });
    }
  }

  Widget _buildTablaCargosPorSede() {
    if (_cargandoConfig) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorConfig != null) {
      return Center(
        child: Text(
          _errorConfig!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_cargosConfig.isEmpty || _sedesConfig.isEmpty) {
      return const Center(
        child: Text('No hay cargos o sedes configurados.'),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cargos contados por sede',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bodyHeight =
                      (constraints.maxHeight - 48).clamp(0.0, constraints.maxHeight);

                  return Scrollbar(
                    controller: _tablaHorizontalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _tablaHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TablaHeaderRow(sedes: _sedesConfig),
                            const Divider(height: 1),
                            SizedBox(
                              height: bodyHeight.toDouble(),
                              child: ListView.builder(
                                itemCount: _cargosConfig.length,
                                itemBuilder: (context, index) {
                                  final cargo = _cargosConfig[index];
                                  return _TablaCargoRow(
                                    cargo: cargo,
                                    sedes: _sedesConfig,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStepContinue() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      final parsed = int.tryParse(_cantidadPersonas);
      if (parsed == null || parsed <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La cantidad de personas debe ser un número mayor a 0.'),
            ),
          );
        return;
      }

      final sedeId = widget.selectedSede.id;
      final cargoBackend = _mapCargoBackend(_cargo);

      final ingredientesPayload = _ingredientesSeleccionados
          .where((ing) => ing.productoId != null && ing.cantidad.isNotEmpty)
          .map((ing) {
        final cantidad = double.tryParse(ing.cantidad.replaceAll(',', '.')) ?? 0;
        return {
          'productoId': ing.productoId,
          'cantidad': cantidad,
        };
      }).toList();

      () async {
        try {
          await _apiClient.postJson(
            '/platos/registro',
            {
              'fecha': _fecha.toIso8601String(),
              'sedeId': sedeId,
              'cargoId': cargoBackend,
              'nombrePlato': _nombrePlato,
              'cantidadPersonas': parsed,
              'ingredientes': ingredientesPayload,
              'observaciones': _observaciones.trim().isEmpty
                  ? null
                  : _observaciones.trim(),
            },
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plato servido registrado.')),
          );

          await _cargarHistorial();
          if (mounted) {
            _resetForm();
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar plato: $e')),
          );
        }
      }();
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nombrePlato.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingresa el nombre del plato.')),
          );
          return false;
        }
        if (_cargo.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona un cargo.')),
          );
          return false;
        }
        if (_cantidadPersonas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Ingresa la cantidad de personas.'),
            ),
          );
          return false;
        }
        final parsed = int.tryParse(_cantidadPersonas);
        if (parsed == null || parsed <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('La cantidad de personas debe ser un número mayor a 0.'),
            ),
          );
          return false;
        }
        return true;
      case 1:
        final validos = _ingredientesSeleccionados.where(
          (ing) => ing.productoId != null && ing.cantidad.isNotEmpty,
        );
        if (validos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Agrega al menos un ingrediente con cantidad utilizada.',
              ),
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _cargo = '';
      _nombrePlato = '';
      _cantidadPersonas = '';
      _observaciones = '';
      _fecha = DateTime.now();
      _showForm = false;
      _ingredientesSeleccionados.clear();
    });
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargandoHistorial = true;
    });

    final sedeId = widget.selectedSede.id;

    try {
      final data = await _apiClient.getJsonList(
        '/platos/historial',
        query: {'sedeId': sedeId},
      );

      final registros = data
          .map((e) => _PlatoHistorial(
                id: e['id'] as String,
                fecha: DateTime.parse(e['fecha'] as String),
                cargoId: e['cargoId'] as String,
                nombrePlato: e['nombrePlato'] as String,
                cantidadPersonas: (e['cantidadPersonas'] as num).toInt(),
              ))
          .toList();

      setState(() {
        _historial = registros;
        _cargandoHistorial = false;
      });
    } catch (e) {
      setState(() {
        _cargandoHistorial = false;
        _historial = const [];
      });
    }
  }

  Future<void> _cargarIngredientesDisponibles() async {
    setState(() {
      _cargandoIngredientes = true;
    });

    final sedeId = widget.selectedSede.id;

    try {
      final data = await _apiClient.getJsonList(
        '/inventario/productos',
        query: {'sedeId': sedeId},
      );

      final productos = data
          .map((e) => _ProductoInventario(
                id: e['id'] as String,
                nombre: e['nombre'] as String,
                unidad: e['unidad'] as String,
                cantidadActual: (e['cantidadActual'] as num).toInt(),
              ))
          .toList();

      setState(() {
        _productosDisponibles = productos;
        _cargandoIngredientes = false;
      });
    } catch (e) {
      setState(() {
        _productosDisponibles = const [];
        _cargandoIngredientes = false;
      });
    }
  }

  void _agregarIngrediente() {
    if (_productosDisponibles.isEmpty) return;

    final usados = _ingredientesSeleccionados
        .where((ing) => ing.productoId != null)
        .map((ing) => ing.productoId)
        .toSet();

    if (usados.length >= _productosDisponibles.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Ya agregaste todos los ingredientes disponibles.'),
        ),
      );
      return;
    }

    setState(() {
      _ingredientesSeleccionados.add(_IngredienteSeleccionado());
    });
  }

  void _eliminarIngrediente(int index) {
    setState(() {
      if (index >= 0 && index < _ingredientesSeleccionados.length) {
        _ingredientesSeleccionados.removeAt(index);
      }
    });
  }

  void _onIngredienteProductoChanged(int index, String? productoId) {
    if (index < 0 || index >= _ingredientesSeleccionados.length) return;
    setState(() {
      _ingredientesSeleccionados[index].productoId = productoId;
    });
  }

  void _onIngredienteCantidadChanged(int index, String cantidad) {
    if (index < 0 || index >= _ingredientesSeleccionados.length) return;
    setState(() {
      _ingredientesSeleccionados[index].cantidad = cantidad;
    });
  }
}

class _PlatoHistorial {
  const _PlatoHistorial({
    required this.id,
    required this.fecha,
    required this.cargoId,
    required this.nombrePlato,
    required this.cantidadPersonas,
  });

  final String id;
  final DateTime fecha;
  final String cargoId;
  final String nombrePlato;
  final int cantidadPersonas;
}

class _CargoConfig {
  const _CargoConfig({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.sedes,
  });

  final String id;
  final String nombre;
  final int tipo;
  final List<String> sedes;
}

class _TipoPlato {
  const _TipoPlato({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  final String id;
  final String nombre;
  final bool activo;
}

class _CargoEditable {
  _CargoEditable({
    required this.id,
    required String nombre,
    required List<String> sedes,
  })  : nombreController = TextEditingController(text: nombre),
        sedesSeleccionadas = {...sedes};

  final String id;
  final TextEditingController nombreController;
  final Set<String> sedesSeleccionadas;
  bool eliminado = false;
}

class _TablaHeaderRow extends StatelessWidget {
  const _TablaHeaderRow({required this.sedes});

  final List<Sede> sedes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const _TablaCell(
            text: 'Cargo',
            isHeader: true,
            flex: 3,
          ),
          for (final sede in sedes)
            _TablaCell(
              text: sede.nombre,
              isHeader: true,
            ),
        ],
      ),
    );
  }
}

class _TablaCargoRow extends StatelessWidget {
  const _TablaCargoRow({required this.cargo, required this.sedes});

  final _CargoConfig cargo;
  final List<Sede> sedes;

  @override
  Widget build(BuildContext context) {
    return Container
/* ignore: prefer_const_constructors */
        (
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          _TablaCell(
            text: cargo.nombre,
            flex: 3,
          ),
          for (final sede in sedes)
            _TablaCell(
              text: cargo.sedes.contains(sede.id) ? 'Sí' : 'No',
              color: cargo.sedes.contains(sede.id)
                  ? const Color(0xFF16A34A)
                  : Colors.grey.shade600,
            ),
        ],
      ),
    );
  }
}

class _TablaCell extends StatelessWidget {
  const _TablaCell({
    required this.text,
    this.isHeader = false,
    this.flex = 2,
    this.color,
  });

  final String text;
  final bool isHeader;
  final int flex;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseStyle = isHeader
        ? const TextStyle(fontWeight: FontWeight.w600)
        : const TextStyle();

    return Expanded(
      flex: flex,
      child: Align(
        alignment: isHeader ? Alignment.centerLeft : Alignment.center,
        child: Text(
          text,
          style: baseStyle.copyWith(color: color ?? baseStyle.color),
        ),
      ),
    );
  }
}

class _EditarCargosDialog extends StatefulWidget {
  const _EditarCargosDialog({
    required this.cargos,
    required this.sedes,
    required this.apiClient,
    required this.onSaved,
  });

  final List<_CargoConfig> cargos;
  final List<Sede> sedes;
  final ApiClient apiClient;
  final Future<void> Function() onSaved;

  @override
  State<_EditarCargosDialog> createState() => _EditarCargosDialogState();
}

class _EditarCargosDialogState extends State<_EditarCargosDialog> {
  late final List<_CargoEditable> _editables;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _editables = [
      for (final c in widget.cargos)
        _CargoEditable(id: c.id, nombre: c.nombre, sedes: c.sedes),
    ];
  }

  @override
  void dispose() {
    for (final e in _editables) {
      e.nombreController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar cargos'),
      content: SizedBox(
        width: 820,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edita el nombre y en qué sedes se cuenta cada cargo.',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _editables.length,
                itemBuilder: (context, index) {
                  final editable = _editables[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: editable.eliminado
                        ? Colors.red.shade50
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: editable.nombreController,
                                  enabled: !editable.eliminado,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre del cargo',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    editable.eliminado = !editable.eliminado;
                                  });
                                },
                                icon: Icon(
                                  editable.eliminado
                                      ? Icons.undo
                                      : Icons.delete_outline,
                                  color: Colors.red.shade700,
                                ),
                                label: Text(
                                  editable.eliminado
                                      ? 'Deshacer'
                                      : 'Eliminar',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!editable.eliminado)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final sede in widget.sedes)
                                  FilterChip(
                                    label: Text(sede.nombre),
                                    selected: editable.sedesSeleccionadas
                                        .contains(sede.id),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          editable.sedesSeleccionadas
                                              .add(sede.id);
                                        } else {
                                          editable.sedesSeleccionadas
                                              .remove(sede.id);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            )
                          else
                            Text(
                              'Este cargo se marcará como eliminado (tipo = 0).',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child:
              _guardando ? const CircularProgressIndicator() : const Text('Aceptar'),
        ),
      ],
    );
  }

  void _guardar() {
    () async {
      setState(() {
        _guardando = true;
      });

      try {
        for (final editable in _editables) {
          final nombre = editable.nombreController.text.trim();
          if (nombre.isEmpty) continue;

          final tipo = editable.eliminado ? 0 : 1;
          final sedes =
              editable.eliminado ? <String>[] : editable.sedesSeleccionadas.toList();

          await widget.apiClient.putJson(
            '/cargos/${editable.id}',
            {
              'nombre': nombre,
              'tipo': tipo,
              'sedes': sedes,
              'observaciones': null,
            },
          );
        }

        await widget.onSaved();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cargos actualizados correctamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar cargos: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _guardando = false;
          });
        }
      }
    }();
  }
}

class _NuevoCargoDialog extends StatefulWidget {
  const _NuevoCargoDialog({
    required this.sedes,
    required this.apiClient,
    required this.onSaved,
  });

  final List<Sede> sedes;
  final ApiClient apiClient;
  final Future<void> Function() onSaved;

  @override
  State<_NuevoCargoDialog> createState() => _NuevoCargoDialogState();
}

class _NuevoCargoDialogState extends State<_NuevoCargoDialog> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final Set<String> _sedesSeleccionadas = {};
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar cargo'),
      content: SizedBox(
        width: 600,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cargo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('¿En qué sedes se cuenta este cargo?'),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final sede in widget.sedes)
                      FilterChip(
                        label: Text(sede.nombre),
                        selected: _sedesSeleccionadas.contains(sede.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _sedesSeleccionadas.add(sede.id);
                            } else {
                              _sedesSeleccionadas.remove(sede.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child:
              _guardando ? const CircularProgressIndicator() : const Text('Aceptar'),
        ),
      ],
    );
  }

  void _guardar() {
    () async {
      final nombre = _nombreController.text.trim();
      if (nombre.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un nombre para el cargo.')),
        );
        return;
      }

      setState(() {
        _guardando = true;
      });

      try {
        final observaciones =
            _observacionesController.text.trim().isEmpty
                ? null
                : _observacionesController.text.trim();

        await widget.apiClient.postJson(
          '/cargos',
          {
            'nombre': nombre,
            'tipo': 1,
            'sedes': _sedesSeleccionadas.toList(),
            'observaciones': observaciones,
          },
        );

        await widget.onSaved();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cargo creado correctamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear cargo: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _guardando = false;
          });
        }
      }
    }();
  }
}

String _cargoLabel(String id) {
  switch (id) {
    case 'NINOS':
      return 'Niños';
    case 'PERSONAL':
      return 'Personal';
    case 'VISITAS':
      return 'Visitas';
    case 'VOLUNTARIOS':
      return 'Voluntarios';
    case 'TODOS':
      return 'Todos';
    default:
      return id;
  }
}

String _mapCargoBackend(String value) {
  switch (value) {
    case 'ninos':
      return 'NINOS';
    case 'personal':
      return 'PERSONAL';
    case 'visitas':
      return 'VISITAS';
    case 'voluntarios':
      return 'VOLUNTARIOS';
    case 'todos':
      return 'TODOS';
    default:
      return value.toUpperCase();
  }
}

class _RegistroStepper extends StatelessWidget {
  const _RegistroStepper({
    required this.currentStep,
    required this.onStepContinue,
    required this.onStepCancel,
    required this.onFechaChanged,
    required this.onCargoChanged,
    required this.onNombrePlatoChanged,
    required this.onCantidadPersonasChanged,
    required this.onObservacionesChanged,
    required this.fecha,
    required this.cargo,
    required this.nombrePlato,
    required this.cantidadPersonas,
    required this.observaciones,
    required this.productosDisponibles,
    required this.ingredientesSeleccionados,
    required this.cargandoIngredientes,
    required this.onAgregarIngrediente,
    required this.onEliminarIngrediente,
    required this.onIngredienteProductoChanged,
    required this.onIngredienteCantidadChanged,
  });

  final int currentStep;
  final VoidCallback onStepContinue;
  final VoidCallback onStepCancel;
  final ValueChanged<DateTime> onFechaChanged;
  final ValueChanged<String> onCargoChanged;
  final ValueChanged<String> onNombrePlatoChanged;
  final ValueChanged<String> onCantidadPersonasChanged;
  final ValueChanged<String> onObservacionesChanged;
  final DateTime fecha;
  final String cargo;
  final String nombrePlato;
  final String cantidadPersonas;
  final String observaciones;
  final List<_ProductoInventario> productosDisponibles;
  final List<_IngredienteSeleccionado> ingredientesSeleccionados;
  final bool cargandoIngredientes;
  final VoidCallback onAgregarIngrediente;
  final ValueChanged<int> onEliminarIngrediente;
  final void Function(int, String?) onIngredienteProductoChanged;
  final void Function(int, String) onIngredienteCantidadChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFFF6FBF4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Form(
          child: Stepper(
            currentStep: currentStep,
            onStepContinue: onStepContinue,
            onStepCancel: onStepCancel,
            type: StepperType.vertical,
            controlsBuilder: (context, details) {
              final isLast = currentStep == 2;
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: details.onStepContinue,
                      icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                      label: Text(isLast ? 'Finalizar' : 'Siguiente'),
                    ),
                    const SizedBox(width: 12),
                    if (currentStep > 0)
                      TextButton.icon(
                        onPressed: details.onStepCancel,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Anterior'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Datos del plato'),
                isActive: currentStep >= 0,
                state:
                    currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: fecha,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                onFechaChanged(picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha',
                                border: OutlineInputBorder(),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                              ),
                              child: Text(
                                '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: nombrePlato,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del plato',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: onNombrePlatoChanged,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: cargo.isEmpty ? null : cargo,
                      decoration: const InputDecoration(
                        labelText: 'Cargo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ninos',
                          child: Text('Niños'),
                        ),
                        DropdownMenuItem(
                          value: 'personal',
                          child: Text('Personal'),
                        ),
                        DropdownMenuItem(
                          value: 'visitas',
                          child: Text('Visitas'),
                        ),
                        DropdownMenuItem(
                          value: 'voluntarios',
                          child: Text('Voluntarios'),
                        ),
                        DropdownMenuItem(
                          value: 'todos',
                          child: Text('Todos'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onCargoChanged(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona un cargo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: cantidadPersonas,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de personas',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: onCantidadPersonasChanged,
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Ingredientes'),
                isActive: currentStep >= 1,
                state:
                    currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cargandoIngredientes)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (productosDisponibles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No hay ingredientes disponibles en el inventario de esta sede.',
                        ),
                      )
                    else ...[
                      for (int i = 0; i < ingredientesSeleccionados.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: ingredientesSeleccionados[i].productoId,
                                  decoration: const InputDecoration(
                                    labelText: 'Ingrediente',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    for (int j = 0;
                                        j < productosDisponibles.length;
                                        j++)
                                      if (ingredientesSeleccionados
                                              .asMap()
                                              .entries
                                              .where((e) =>
                                                  e.key != i &&
                                                  e.value.productoId ==
                                                      productosDisponibles[j]
                                                          .id)
                                              .isEmpty)
                                      DropdownMenuItem(
                                        value: productosDisponibles[j].id,
                                        child: Text(
                                          '${productosDisponibles[j].nombre} (${productosDisponibles[j].cantidadActual} ${productosDisponibles[j].unidad} disponibles)',
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) =>
                                      onIngredienteProductoChanged(i, value),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue:
                                      ingredientesSeleccionados[i].cantidad,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad usada',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) =>
                                      onIngredienteCantidadChanged(i, value),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Quitar ingrediente',
                                icon: const Icon(Icons.close),
                                onPressed: () => onEliminarIngrediente(i),
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onAgregarIngrediente,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar ingrediente'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Step(
                title: const Text('Confirmar'),
                isActive: currentStep >= 2,
                state: currentStep == 2
                    ? StepState.editing
                    : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResumenRow(
                      label: 'Fecha',
                      value:
                          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(height: 8),
                    _ResumenRow(
                      label: 'Cargo',
                      value: cargo.isEmpty ? '-' : cargo,
                    ),
                    const SizedBox(height: 8),
                    _ResumenRow(
                      label: 'Nombre del plato',
                      value: nombrePlato.isEmpty ? '-' : nombrePlato,
                    ),
                    const SizedBox(height: 8),
                    _ResumenRow(
                      label: 'Cantidad de personas',
                      value:
                          cantidadPersonas.isEmpty ? '-' : cantidadPersonas,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingredientes utilizados',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (ingredientesSeleccionados.isEmpty)
                      const Text('No se seleccionaron ingredientes.')
                    else
                      Column(
                        children: [
                          for (final ing in ingredientesSeleccionados)
                            Builder(
                              builder: (context) {
                                final prod = productosDisponibles.firstWhere(
                                  (p) => p.id == ing.productoId,
                                  orElse: () => const _ProductoInventario(
                                    id: '',
                                    nombre: 'Ingrediente',
                                    unidad: '',
                                    cantidadActual: 0,
                                  ),
                                );
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          prod.id.isEmpty
                                              ? '-'
                                              : prod.nombre,
                                          style:
                                              const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        ing.cantidad.isEmpty
                                            ? '-'
                                            : '${ing.cantidad} ${prod.unidad}',
                                        style:
                                            const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: observaciones,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: onObservacionesChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  const _ResumenRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ProductoInventario {
  const _ProductoInventario({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.cantidadActual,
  });

  final String id;
  final String nombre;
  final String unidad;
  final int cantidadActual;
}

class _IngredienteSeleccionado {
  _IngredienteSeleccionado();

  String? productoId;
  String cantidad = '';
}

class _RegistrarComidaDialog extends StatefulWidget {
  const _RegistrarComidaDialog({
    required this.sedes,
    required this.cargos,
    required this.apiClient,
    required this.sedeInicial,
  });

  final List<Sede> sedes;
  final List<_CargoConfig> cargos;
  final ApiClient apiClient;
  final Sede sedeInicial;

  @override
  State<_RegistrarComidaDialog> createState() => _RegistrarComidaDialogState();
}

class _RegistrarComidaDialogState extends State<_RegistrarComidaDialog> {
  int _paso = 0;
  DateTime _fechaRegistro = DateTime.now();
  Sede? _sedeSeleccionada;
  _TipoPlato? _tipoSeleccionado;

  bool _cargandoTipos = true;
  String? _errorTipos;
  List<_TipoPlato> _tipos = const [];

  final Map<String, TextEditingController> _cantidadPorCargo = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Usar siempre una instancia que esté dentro de la lista de sedes
    // del dropdown, para evitar el error de valor no encontrado.
    final sedes = widget.sedes;
    if (sedes.isNotEmpty) {
      final match = sedes.firstWhere(
        (s) => s.id == widget.sedeInicial.id,
        orElse: () => sedes.first,
      );
      _sedeSeleccionada = match;
    }
    _cargarTiposPlatos();
  }

  @override
  void dispose() {
    for (final c in _cantidadPorCargo.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarTiposPlatos() async {
    setState(() {
      _cargandoTipos = true;
      _errorTipos = null;
    });

    try {
      final data = await widget.apiClient.getJsonList('/tipos-platos');
      final tipos = data
          .map((e) => _TipoPlato(
                id: e['id'] as String,
                nombre: e['nombre'] as String,
                activo: (e['activo'] as bool?) ?? true,
              ))
          .where((t) => t.activo)
          .toList();

      setState(() {
        _tipos = tipos;
        _cargandoTipos = false;
        if (_tipos.isNotEmpty) {
          _tipoSeleccionado = _tipos.first;
        }
      });
    } catch (e) {
      setState(() {
        _cargandoTipos = false;
        _errorTipos = 'Error al cargar tipos de platos: $e';
        _tipos = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar comida'),
      content: SizedBox(
        width: 820,
        height: 520,
        child: _buildContenido(),
      ),
      actions: _buildAcciones(),
    );
  }

  Widget _buildContenido() {
    if (_paso == 0) {
      return _buildPasoSeleccionBasica();
    } else if (_paso == 1) {
      return _buildPasoCargos();
    } else {
      return _buildPasoResumen();
    }
  }

  List<Widget> _buildAcciones() {
    return [
      TextButton(
        onPressed: _guardando ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      if (_paso > 0)
        TextButton(
          onPressed: _guardando ? null : _regresar,
          child: const Text('Regresar'),
        ),
      FilledButton(
        onPressed: _guardando ? null : (_paso == 2 ? _guardar : _continuar),
        child: _guardando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_paso == 2 ? 'Guardar' : 'Continuar'),
      ),
    ];
  }

  Widget _buildPasoSeleccionBasica() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primero selecciona la fecha, la sede y el tipo de comida.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaRegistro,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaRegistro = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha del registro',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_fechaRegistro.year}-${_fechaRegistro.month.toString().padLeft(2, '0')}-${_fechaRegistro.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Sede>(
          value: _sedeSeleccionada,
          decoration: const InputDecoration(
            labelText: 'Sede del registro',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final sede in widget.sedes)
              DropdownMenuItem<Sede>(
                value: sede,
                child: Text(sede.nombre),
              ),
          ],
          onChanged: (value) {
            setState(() {
              _sedeSeleccionada = value;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_cargandoTipos)
          const Center(child: CircularProgressIndicator())
        else if (_errorTipos != null)
          Text(
            _errorTipos!,
            style: const TextStyle(color: Colors.red),
          )
        else
          DropdownButtonFormField<_TipoPlato>(
            value: _tipoSeleccionado,
            decoration: const InputDecoration(
              labelText: 'Tipo de comida',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final t in _tipos)
                DropdownMenuItem<_TipoPlato>(
                  value: t,
                  child: Text(t.nombre),
                ),
            ],
            onChanged: (value) {
              setState(() {
                _tipoSeleccionado = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildPasoCargos() {
    final sede = _sedeSeleccionada;
    if (sede == null) {
      return const Center(
        child: Text('Selecciona una sede antes de continuar.'),
      );
    }

    final cargosFiltrados = widget.cargos
        .where((c) => c.sedes.contains(sede.id) && c.tipo != 0)
        .toList();

    if (cargosFiltrados.isEmpty) {
      return const Center(
        child: Text('No hay cargos configurados para esta sede.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuántas personas comieron por cada cargo en ${sede.nombre}?',
        ),
        const SizedBox(height: 12),
        const Text(
          'Solo se guardarán los cargos con una cantidad mayor a 0.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: cargosFiltrados.length,
            itemBuilder: (context, index) {
              final cargo = cargosFiltrados[index];
              final controller = _cantidadPorCargo.putIfAbsent(
                cargo.id,
                () => TextEditingController(),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(cargo.nombre),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Personas',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
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

  Widget _buildPasoResumen() {
    final sede = _sedeSeleccionada;
    final tipo = _tipoSeleccionado;

    final registros = _obtenerRegistrosValidos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Revisa el resumen antes de guardar.'),
        const SizedBox(height: 12),
        _ResumenRow(
          label: 'Fecha del registro',
          value:
              '${_fechaRegistro.year}-${_fechaRegistro.month.toString().padLeft(2, '0')}-${_fechaRegistro.day.toString().padLeft(2, '0')}',
        ),
        const SizedBox(height: 8),
        _ResumenRow(
          label: 'Sede',
          value: sede?.nombre ?? '-',
        ),
        const SizedBox(height: 8),
        _ResumenRow(
          label: 'Tipo de comida',
          value: tipo?.nombre ?? '-',
        ),
        const SizedBox(height: 16),
        const Text(
          'Personas por cargo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (registros.isEmpty)
          const Text('No hay cargos con cantidad mayor a 0.')
        else
          Expanded(
            child: ListView.builder(
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final r = registros[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(r['nombreCargo'] as String),
                      ),
                      Text('${r['cantidad']} personas'),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _continuar() {
    if (_paso == 0) {
      if (_sedeSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una sede.')),
        );
        return;
      }
      if (_tipoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un tipo de comida.')),
        );
        return;
      }
      setState(() {
        _paso = 1;
      });
    } else if (_paso == 1) {
      final registros = _obtenerRegistrosValidos();
      if (registros.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Ingresa al menos una cantidad mayor a 0 para algún cargo.'),
          ),
        );
        return;
      }
      setState(() {
        _paso = 2;
      });
    }
  }

  void _regresar() {
    if (_paso > 0) {
      setState(() {
        _paso -= 1;
      });
    }
  }

  List<Map<String, Object>> _obtenerRegistrosValidos() {
    final sede = _sedeSeleccionada;
    if (sede == null) return [];

    final cargosFiltrados = widget.cargos
        .where((c) => c.sedes.contains(sede.id) && c.tipo != 0)
        .toList();

    final List<Map<String, Object>> registros = [];
    for (final cargo in cargosFiltrados) {
      final controller = _cantidadPorCargo[cargo.id];
      if (controller == null) continue;
      final text = controller.text.trim();
      if (text.isEmpty) continue;
      final parsed = int.tryParse(text);
      if (parsed == null || parsed <= 0) continue;

      registros.add({
        'cargoId': cargo.id,
        'nombreCargo': cargo.nombre,
        'cantidad': parsed,
      });
    }

    return registros;
  }

  void _guardar() {
    final sede = _sedeSeleccionada;
    final tipo = _tipoSeleccionado;
    if (sede == null || tipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan datos para guardar el registro.')),
      );
      return;
    }

    final registros = _obtenerRegistrosValidos();
    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ingresa al menos una cantidad mayor a 0 para algún cargo.'),
        ),
      );
      return;
    }

    () async {
      setState(() {
        _guardando = true;
      });

      try {
        final payload = {
          'fechaRegistro': _fechaRegistro.toIso8601String(),
          'sedeId': sede.id,
          'tipoComidaId': tipo.id,
          'registros': [
            for (final r in registros)
              {
                'cargoId': r['cargoId'],
                'cantidadPersonas': r['cantidad'],
              },
          ],
        };

        await widget.apiClient.postJson(
          '/platos/registrar-comida',
          payload,
        );

        if (!mounted) return;

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comida registrada correctamente.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar comida: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _guardando = false;
          });
        }
      }
    }();
  }
}

class _PlatosRecientesCard extends StatelessWidget {
  const _PlatosRecientesCard({
    required this.registros,
    this.cargando = false,
  });

  final List<_PlatoHistorial> registros;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registros Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (cargando)
                  Text(
                    'Cargando registros...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  )
                else
                  Text(
                    registros.isEmpty
                        ? 'No hay registros recientes para esta sede.'
                        : 'Últimos platos servidos en la sede seleccionada',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Encabezado de tabla
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'FECHA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'CARGO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'PLATO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'PERSONAS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Filas
                      if (registros.isEmpty && !cargando)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sin registros para mostrar.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        for (final plato in registros)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${plato.fecha.year}-${plato.fecha.month.toString().padLeft(2, '0')}-${plato.fecha.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _cargoLabel(plato.cargoId),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    plato.nombrePlato,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${plato.cantidadPersonas}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
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
        const SizedBox(height: 24),
        const _RegistroInfoCard(),
      ],
    );
  }
}

class _RegistroInfoCard extends StatelessWidget {
  const _RegistroInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: const Color(0xFFE0F2FE),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Registro de Platos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Registra cada plato servido especificando el tipo de comida, cargo, cantidad de personas y detalles del plato. '
                    'El sistema validará que no se repitan registros del mismo tipo de comida para un cargo en el mismo día.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

