import 'package:flutter/material.dart';

import '../../app/api_client.dart';
import '../../app/models.dart';
import '../../app/widgets/page_header.dart';

class PlatosServidosScreen extends StatefulWidget {
  const PlatosServidosScreen({super.key, required this.selectedCasa});

  final Casa selectedCasa;

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

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
    _cargarIngredientesDisponibles();
  }

  @override
  void didUpdateWidget(covariant PlatosServidosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCasa.id != widget.selectedCasa.id) {
      _resetForm();
      _cargarHistorial();
      _cargarIngredientesDisponibles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Platos Servidos',
          description: 'Registro diario de platos servidos',
          selectedCasa: widget.selectedCasa,
          actions: FilledButton.icon(
            onPressed: () {
              setState(() {
                if (_showForm) {
                  _resetForm();
                } else {
                  _showForm = true;
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            icon: Icon(_showForm ? Icons.close : Icons.add),
            label: Text(_showForm ? 'Cerrar formulario' : 'Nuevo Registro'),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showForm)
                  _RegistroStepper(
                    currentStep: _currentStep,
                    onStepContinue: _handleStepContinue,
                    onStepCancel: _handleStepCancel,
                    onFechaChanged: (value) => setState(() => _fecha = value),
                    onCargoChanged: (value) => setState(() => _cargo = value),
                    onNombrePlatoChanged: (value) => setState(() => _nombrePlato = value),
                    onCantidadPersonasChanged: (value) =>
                        setState(() => _cantidadPersonas = value),
                    onObservacionesChanged: (value) =>
                        setState(() => _observaciones = value),
                    fecha: _fecha,
                    cargo: _cargo,
                    nombrePlato: _nombrePlato,
                    cantidadPersonas: _cantidadPersonas,
                    observaciones: _observaciones,
                    productosDisponibles: _productosDisponibles,
                    ingredientesSeleccionados: _ingredientesSeleccionados,
                    cargandoIngredientes: _cargandoIngredientes,
                    onAgregarIngrediente: _agregarIngrediente,
                    onEliminarIngrediente: _eliminarIngrediente,
                    onIngredienteProductoChanged: _onIngredienteProductoChanged,
                    onIngredienteCantidadChanged: _onIngredienteCantidadChanged,
                  )
                else
                  _PlatosRecientesCard(
                    registros: _historial,
                    cargando: _cargandoHistorial,
                  ),
              ],
            ),
          ),
        ),
      ],
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
            content:
                Text('La cantidad de personas debe ser un número mayor a 0.'),
          ),
        );
        return;
      }

      final sedeId = mapCasaToSedeId(widget.selectedCasa.nombre);
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

    final sedeId = mapCasaToSedeId(widget.selectedCasa.nombre);

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

    final sedeId = mapCasaToSedeId(widget.selectedCasa.nombre);

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
                          'No hay ingredientes disponibles en el inventario de esta casa.',
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
                        ? 'No hay registros recientes para esta casa.'
                        : 'Últimos platos servidos en la casa seleccionada',
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

