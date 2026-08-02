import 'package:flutter/foundation.dart';

import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';

/// Administra la lista de responsables.
class UsuarioProvider extends ChangeNotifier {
  UsuarioProvider({UsuarioRepository? repository})
    : _repository = repository ?? UsuarioRepository();

  final UsuarioRepository _repository;

  final List<UsuarioModel> _usuarios = <UsuarioModel>[];

  final List<UsuarioModel> _usuariosFiltrados = <UsuarioModel>[];

  bool _cargando = false;
  String? _error;
  String _textoBusqueda = '';

  List<UsuarioModel> get usuarios {
    return List<UsuarioModel>.unmodifiable(_usuarios);
  }

  List<UsuarioModel> get usuariosFiltrados {
    return List<UsuarioModel>.unmodifiable(_usuariosFiltrados);
  }

  bool get cargando => _cargando;

  String? get error => _error;

  String get textoBusqueda => _textoBusqueda;

  bool get tieneUsuarios {
    return _usuariosFiltrados.isNotEmpty;
  }

  /// Carga los usuarios desde el backend.
  Future<void> cargarUsuarios({
    int? institucionId,
    int? sedeId,
    int? areaId,
  }) async {
    if (_cargando) {
      return;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final List<UsuarioModel> resultado = await _repository.obtenerTodos(
        institucionId: institucionId,
        sedeId: sedeId,
        areaId: areaId,
      );

      resultado.sort((UsuarioModel primero, UsuarioModel segundo) {
        return primero.nombreVisible.toLowerCase().compareTo(
          segundo.nombreVisible.toLowerCase(),
        );
      });

      _usuarios
        ..clear()
        ..addAll(resultado);

      _aplicarFiltro();
    } catch (error) {
      _error = _limpiarMensaje(error);

      _usuarios.clear();
      _usuariosFiltrados.clear();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Obtiene un usuario por ID.
  ///
  /// Primero lo busca en la lista cargada.
  Future<UsuarioModel?> obtenerPorId(int id) async {
    if (id <= 0) {
      return null;
    }

    for (final UsuarioModel usuario in _usuarios) {
      if (usuario.id == id) {
        return usuario;
      }
    }

    try {
      return await _repository.obtenerPorId(id);
    } catch (error) {
      _error = _limpiarMensaje(error);
      notifyListeners();

      return null;
    }
  }

  /// Filtra por nombre, usuario o correo.
  void buscar(String texto) {
    _textoBusqueda = texto.trim();
    _aplicarFiltro();
    notifyListeners();
  }

  void limpiarBusqueda() {
    if (_textoBusqueda.isEmpty) {
      return;
    }

    _textoBusqueda = '';
    _aplicarFiltro();
    notifyListeners();
  }

  void limpiarError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  void _aplicarFiltro() {
    final List<UsuarioModel> resultado = _repository.buscarEnLista(
      _usuarios,
      _textoBusqueda,
    );

    _usuariosFiltrados
      ..clear()
      ..addAll(resultado);
  }

  String _limpiarMensaje(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
