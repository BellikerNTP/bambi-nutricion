import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app/nutricion_app.dart';
import 'app/api_client.dart';

Process? _backendProcess;
bool _backendStartedByApp = false;

Future<bool> _pingBackend() async {
  try {
    final uri = Uri.parse('${ApiClient.baseUrl}/health');
    final resp = await http.get(uri).timeout(const Duration(seconds: 2));
    return resp.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<void> _ensureBackendRunning() async {
  // Solo intentamos lanzar el backend automáticamente en Windows.
  if (!Platform.isWindows) return;

  // Si ya responde, no hacemos nada.
  if (await _pingBackend()) return;

  // Nombre del ejecutable del backend. En el instalador deberá colocarse
  // en la misma carpeta que la app Flutter o en una ruta conocida del PATH.
  const backendExe = 'nutricion_backend.exe';

  try {
    // Lanzamos el backend como proceso hijo para poder cerrarlo
    // cuando la app termine.
    _backendProcess = await Process.start(backendExe, []);
    _backendStartedByApp = true;
  } catch (_) {
    // Si no se puede lanzar (por ejemplo en desarrollo), simplemente seguimos
    // y la app fallará al llamar al backend como lo hace hoy.
    return;
  }

  // Esperar unos segundos a que arranque y reintentar el ping.
  for (var i = 0; i < 5; i++) {
    await Future.delayed(const Duration(seconds: 1));
    if (await _pingBackend()) {
      return;
    }
  }
}

Future<void> _shutdownBackend() async {
  try {
    final uri = Uri.parse('${ApiClient.baseUrl}/shutdown');
    await http.post(uri).timeout(const Duration(seconds: 2));
  } catch (_) {
    // Ignorar errores al apagar
  } finally {
    _backendProcess?.kill();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intentar que el backend esté levantado antes de arrancar la app.
  await _ensureBackendRunning();

  runApp(const _BackendLifecycleWrapper(child: NutricionApp()));
}

class _BackendLifecycleWrapper extends StatefulWidget {
  const _BackendLifecycleWrapper({required this.child});

  final Widget child;

  @override
  State<_BackendLifecycleWrapper> createState() => _BackendLifecycleWrapperState();
}

class _BackendLifecycleWrapperState extends State<_BackendLifecycleWrapper> {
  @override
  void dispose() {
    // Si la app se está cerrando, intentamos terminar el backend
    // solo si lo lanzamos nosotros.
    _shutdownBackend();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
