import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import 'matriz_iperc_detail_screen.dart';
import 'nueva_matriz_iperc_screen.dart';

class MatricesIpercScreen extends StatefulWidget {
  const MatricesIpercScreen({super.key});

  @override
  State<MatricesIpercScreen> createState() => _MatricesIpercScreenState();
}

class _MatricesIpercScreenState extends State<MatricesIpercScreen> {
  final MatrizIpercRepository _repository = MatrizIpercRepository();

  bool _cargando = true;
  String? _mensajeError;

  List<MatrizIpercModel> _matrices = <MatrizIpercModel>[];

  @override
  void initState() {
    super.initState();
    _cargarMatrices();
  }

  Future<void> _cargarMatrices() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _mensajeError = null;
      });
    }

    try {
      final List<MatrizIpercModel> matrices = await _repository
          .obtenerMatrices();

      if (!mounted) {
        return;
      }

      setState(() {
        _matrices = matrices;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      String mensaje = 'No se pudieron cargar las matrices IPERC.';

      if (error.response?.statusCode == 401) {
        mensaje = 'La sesión venció. Inicie sesión nuevamente.';
      } else if (error.response?.statusCode == 403) {
        mensaje = 'No tiene permisos para consultar matrices.';
      } else if (error.response?.statusCode == 404) {
        mensaje = 'No se encontró el endpoint de matrices IPERC.';
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        mensaje = 'No se pudo conectar con el servidor.';
      }

      setState(() {
        _mensajeError = mensaje;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeError = 'Error inesperado: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrices IPERC')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bool? creada = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => NuevaMatrizIpercScreen(
                matricesRegistradas: _matrices,
              ),
            ),
          );

          if (creada == true) {
            await _cargarMatrices();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva matriz'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarMatrices,
        child: _construirContenido(),
      ),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensajeError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 80),
          Icon(
            Icons.cloud_off,
            size: 72,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 18),
          Text(
            _mensajeError!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: _cargarMatrices,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    if (_matrices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 80),
          Icon(
            Icons.assignment_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'No hay matrices IPERC registradas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Presione “Nueva matriz” para registrar la primera.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _matrices.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final MatrizIpercModel matriz = _matrices[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MatrizIpercDetailScreen(matriz: matriz),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    child: Icon(
                      matriz.activo
                          ? Icons.assignment
                          : Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          matriz.codigo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          matriz.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (matriz.objetivo != null &&
                            matriz.objetivo!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            matriz.objetivo!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: matriz.activo
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            matriz.activo ? 'Activa' : 'Inactiva',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
