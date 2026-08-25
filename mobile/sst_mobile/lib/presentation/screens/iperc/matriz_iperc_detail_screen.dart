import 'package:flutter/material.dart';

import '../../../core/security/role_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/matriz_iperc_model.dart';
import '../../../data/repositories/matriz_iperc_repository.dart';
import '../controles/controles_screen.dart';
import '../matriz_riesgo/matriz_riesgo_screen.dart';
import 'detalles_iperc_screen.dart';
import 'editar_matriz_iperc_screen.dart';

/// ===============================================================
/// DETALLE MATRIZ IPERC - SST EDURISK
/// ===============================================================
///
/// Muestra la información completa de una matriz IPERC y permite
/// acceder a:
/// - peligros y riesgos;
/// - matriz 5x5;
/// - controles;
/// - seguimientos;
/// - edición de la matriz según permisos.
///
/// Colores oficiales:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
/// ===============================================================
class MatrizIpercDetailScreen extends StatefulWidget {
  const MatrizIpercDetailScreen({
    required this.matriz,
    required this.rol,
    super.key,
  });

  final MatrizIpercModel matriz;
  final String rol;

  @override
  State<MatrizIpercDetailScreen> createState() {
    return _MatrizIpercDetailScreenState();
  }
}

class _MatrizIpercDetailScreenState extends State<MatrizIpercDetailScreen> {
  bool get _puedeGestionarMatrices {
    return RolePermissions.puedeGestionarMatrices(widget.rol);
  }

  final MatrizIpercRepository _repository = MatrizIpercRepository();

  late MatrizIpercModel matriz;

  bool _cargandoDetalle = false;

  @override
  void initState() {
    super.initState();

    matriz = widget.matriz;

    _cargarDetalleActualizado();
  }

  // =============================================================
  // RECARGAR MATRIZ
  // =============================================================

  Future<void> _cargarDetalleActualizado() async {
    if (matriz.id <= 0) {
      return;
    }

    setState(() {
      _cargandoDetalle = true;
    });

    try {
      final MatrizIpercModel matrizActualizada = await _repository
          .obtenerMatrizPorId(matriz.id);

      if (!mounted) {
        return;
      }

      setState(() {
        matriz = matrizActualizada;
      });
    } catch (_) {
      // Si la recarga falla, se conserva la información previa.
    } finally {
      if (mounted) {
        setState(() {
          _cargandoDetalle = false;
        });
      }
    }
  }

  // =============================================================
  // ABRIR DETALLES
  // =============================================================

  void _abrirDetalles() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return DetallesIpercScreen(matriz: matriz, rol: widget.rol);
        },
      ),
    );
  }

  // =============================================================
  // EDITAR MATRIZ
  // =============================================================

  Future<void> _editarMatriz() async {
    if (!_puedeGestionarMatrices || _cargandoDetalle) {
      return;
    }

    final bool? actualizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return EditarMatrizIpercScreen(matriz: matriz);
        },
      ),
    );

    if (!mounted || actualizada != true) {
      return;
    }

    await _cargarDetalleActualizado();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(matriz.codigo, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargandoDetalle ? null : _cargarDetalleActualizado,
            icon: _cargandoDetalle
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          if (_puedeGestionarMatrices)
            IconButton(
              tooltip: 'Editar matriz',
              onPressed: _cargandoDetalle ? null : _editarMatriz,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargarDetalleActualizado,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: <Widget>[
            if (_cargandoDetalle) ...<Widget>[
              const LinearProgressIndicator(
                color: AppColors.primaryBright,
                backgroundColor: AppColors.border,
              ),
              const SizedBox(height: 16),
            ],

            _EncabezadoMatriz(matriz: matriz),

            const SizedBox(height: 16),

            _SeccionCard(
              titulo: 'Información general',
              descripcion: 'Datos principales y estado actual de la matriz.',
              icono: Icons.info_outline,
              color: AppColors.primaryBright,
              children: <Widget>[
                _DatoFila(
                  etiqueta: 'Código',
                  valor: matriz.codigo,
                  icono: Icons.qr_code_2_outlined,
                ),
                const Divider(height: 1),
                _DatoFila(
                  etiqueta: 'Nombre',
                  valor: matriz.nombre,
                  icono: Icons.assignment_outlined,
                ),
                const Divider(height: 1),
                _DatoFila(
                  etiqueta: 'Objetivo',
                  valor: _textoOpcional(matriz.objetivo),
                  icono: Icons.flag_outlined,
                ),
                const Divider(height: 1),
                _DatoFila(
                  etiqueta: 'Estado',
                  valor: matriz.activo ? 'Activa' : 'Inactiva',
                  icono: matriz.activo
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  valorColor: matriz.activo
                      ? AppColors.green
                      : AppColors.riskOrange,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SeccionCard(
              titulo: 'Organización',
              descripcion:
                  'Ubicación organizacional asociada a la evaluación IPERC.',
              icono: Icons.apartment_outlined,
              color: AppColors.green,
              children: <Widget>[
                _DatoFila(
                  etiqueta: 'Institución',
                  valor: matriz.institucionVisible,
                  icono: Icons.apartment_outlined,
                ),
                const Divider(height: 1),
                _DatoFila(
                  etiqueta: 'Área',
                  valor: matriz.areaVisible,
                  icono: Icons.domain_outlined,
                ),
                const Divider(height: 1),
                _DatoFila(
                  etiqueta: 'Actividad',
                  valor: matriz.actividadVisible,
                  icono: Icons.task_alt_outlined,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SeccionCard(
              titulo: 'Evaluación IPERC',
              descripcion:
                  'Acceda a la evaluación, riesgos, controles y seguimiento.',
              icono: Icons.grid_view_outlined,
              color: AppColors.yellow,
              colorTexto: AppColors.navyDark,
              children: <Widget>[
                _AccionMatriz(
                  icono: Icons.list_alt,
                  titulo: 'Peligros y riesgos',
                  descripcion:
                      'Consultar los peligros, consecuencias y evaluaciones registradas únicamente en esta matriz.',
                  color: AppColors.riskOrange,
                  onTap: _abrirDetalles,
                ),

                const Divider(height: 1),

                _AccionMatriz(
                  icono: Icons.grid_on_outlined,
                  titulo: 'Matriz de riesgo 5×5',
                  descripcion:
                      'Visualizar la relación entre probabilidad, severidad y nivel de riesgo.',
                  color: AppColors.yellow,
                  colorTexto: AppColors.navyDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) {
                          return const MatrizRiesgoScreen();
                        },
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _AccionMatriz(
                  icono: Icons.shield_outlined,
                  titulo: 'Controles',
                  descripcion:
                      'Consultar las medidas de control registradas en el sistema.',
                  color: AppColors.green,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) {
                          return ControlesScreen(
                            rol: widget.rol,
                            soloLectura: true,
                          );
                        },
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _AccionMatriz(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Seguimientos',
                  descripcion:
                      'Seleccionar un detalle IPERC de esta matriz para revisar sus avances, evidencias y observaciones.',
                  color: AppColors.primaryBright,
                  onTap: _abrirDetalles,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _textoOpcional(String? valor) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'No registrado';
    }

    return texto;
  }
}

/// ===============================================================
/// ENCABEZADO MATRIZ
/// ===============================================================

class _EncabezadoMatriz extends StatelessWidget {
  const _EncabezadoMatriz({required this.matriz});

  final MatrizIpercModel matriz;

  @override
  Widget build(BuildContext context) {
    final Color estadoColor = matriz.activo
        ? AppColors.green
        : AppColors.riskOrange;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primaryBright,
            AppColors.primary,
            AppColors.navyDark,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              matriz.activo
                  ? Icons.assignment_turned_in_outlined
                  : Icons.assignment_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  matriz.codigo,
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  matriz.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 11),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        matriz.activo
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: estadoColor,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        matriz.activo ? 'Activa' : 'Inactiva',
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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
    );
  }
}

/// ===============================================================
/// SECCIÓN REUTILIZABLE
/// ===============================================================

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.children,
    this.colorTexto,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final Color? colorTexto;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: foreground, size: 26),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ...children,
        ],
      ),
    );
  }
}

/// ===============================================================
/// FILA DE DATO
/// ===============================================================

class _DatoFila extends StatelessWidget {
  const _DatoFila({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.valorColor,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final Color? valorColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icono, size: 20, color: AppColors.primary),
          ),

          const SizedBox(width: 11),

          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                etiqueta,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                valor,
                style: TextStyle(
                  color: valorColor ?? AppColors.textPrimary,
                  fontWeight: valorColor != null
                      ? FontWeight.w800
                      : FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// ACCIÓN MATRIZ
/// ===============================================================

class _AccionMatriz extends StatelessWidget {
  const _AccionMatriz({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
    this.colorTexto,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color? colorTexto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = colorTexto ?? color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: foreground, size: 25),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: foreground,
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
