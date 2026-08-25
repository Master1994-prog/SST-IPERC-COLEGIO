import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/evaluacion_riesgo_model.dart';

/// ===============================================================
/// MATRIZ DE RIESGO IPERC 5×5 - SST EDURISK
/// ===============================================================
///
/// Visualiza la relación:
///
///      Probabilidad × Severidad = Valor del riesgo
///
/// IMPORTANTE:
/// - La estructura 5×5 se mantiene.
/// - Los niveles y rangos se obtienen desde evaluacion_riesgo_model.dart.
/// - El color de cada celda se conserva desde nivel.colorHex.
/// - La identidad visual del contenedor usa los colores SST EduRisk.
///
/// Colores SST EduRisk:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// background    #F6F8FC
/// ===============================================================
class MatrizRiesgoScreen extends StatelessWidget {
  const MatrizRiesgoScreen({super.key});

  static const String routeName = '/matriz-riesgo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Matriz de riesgo 5×5'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: const <Widget>[
            _EncabezadoMatriz(),
            SizedBox(height: 16),
            _DescripcionMatriz(),
            SizedBox(height: 16),
            _MatrizRiesgoTabla(),
            SizedBox(height: 16),
            _LeyendaRiesgo(),
            SizedBox(height: 16),
            _GuiaLectura(),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// ENCABEZADO
/// ===============================================================

class _EncabezadoMatriz extends StatelessWidget {
  const _EncabezadoMatriz();

  @override
  Widget build(BuildContext context) {
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Evaluación del riesgo IPERC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Matriz básica de 5 niveles de probabilidad '
                  'por 5 niveles de severidad.',
                  style: TextStyle(
                    color: Color(0xFFDCEAFF),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 9),
                _FormulaCabecera(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaCabecera extends StatelessWidget {
  const _FormulaCabecera();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.calculate_outlined, size: 17, color: AppColors.yellow),
          SizedBox(width: 6),
          Text(
            'P × S = Riesgo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// DESCRIPCIÓN
/// ===============================================================

class _DescripcionMatriz extends StatelessWidget {
  const _DescripcionMatriz();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBright.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              color: AppColors.primaryBright,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Probabilidad × Severidad',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Ubica la probabilidad en las filas y la severidad '
                  'en las columnas. La intersección muestra el valor '
                  'y el nivel correspondiente del riesgo.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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
/// TABLA 5×5
/// ===============================================================

class _MatrizRiesgoTabla extends StatelessWidget {
  const _MatrizRiesgoTabla();

  @override
  Widget build(BuildContext context) {
    const List<int> severidades = <int>[1, 2, 3, 4, 5];

    // Orden descendente para visualizar arriba
    // los niveles de mayor probabilidad.
    const List<int> probabilidades = <int>[5, 4, 3, 2, 1];

    return Container(
      padding: const EdgeInsets.all(14),
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
          const Row(
            children: <Widget>[
              _TituloEje(icono: Icons.arrow_forward, titulo: 'Severidad'),
            ],
          ),
          const SizedBox(height: 10),

          // Desplazamiento horizontal para equipos pequeños.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const _CeldaCabecera(
                      texto: 'P/S',
                      tooltip: 'Probabilidad / Severidad',
                      principal: true,
                    ),
                    ...severidades.map((int severidad) {
                      return _CeldaCabecera(
                        texto: severidad.toString(),
                        tooltip: 'Severidad $severidad',
                      );
                    }),
                  ],
                ),
                ...probabilidades.map((int probabilidad) {
                  return Row(
                    children: <Widget>[
                      _CeldaCabecera(
                        texto: probabilidad.toString(),
                        tooltip: 'Probabilidad $probabilidad',
                      ),
                      ...severidades.map((int severidad) {
                        final int valor = probabilidad * severidad;

                        final NivelRiesgoIpercOption nivel =
                            obtenerNivelRiesgoIperc(valor);

                        return _CeldaRiesgo(
                          valor: valor,
                          probabilidad: probabilidad,
                          severidad: severidad,
                          nivel: nivel,
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const _TituloEje(icono: Icons.arrow_upward, titulo: 'Probabilidad'),
        ],
      ),
    );
  }
}

class _TituloEje extends StatelessWidget {
  const _TituloEje({required this.icono, required this.titulo});

  final IconData icono;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// CELDA DE CABECERA
/// ===============================================================

class _CeldaCabecera extends StatelessWidget {
  const _CeldaCabecera({
    required this.texto,
    required this.tooltip,
    this.principal = false,
  });

  final String texto;
  final String tooltip;
  final bool principal;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 54,
        height: 54,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: principal ? AppColors.navyDark : AppColors.primary,
          borderRadius: BorderRadius.circular(9),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// CELDA DE RIESGO
/// ===============================================================

class _CeldaRiesgo extends StatelessWidget {
  const _CeldaRiesgo({
    required this.valor,
    required this.probabilidad,
    required this.severidad,
    required this.nivel,
  });

  final int valor;
  final int probabilidad;
  final int severidad;
  final NivelRiesgoIpercOption nivel;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(nivel.colorHex);

    final Color foreground = _colorDeTexto(color);

    return Tooltip(
      message:
          '$probabilidad × $severidad = $valor\n'
          'Riesgo ${nivel.nombre}',
      child: Container(
        width: 54,
        height: 54,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              valor.toString(),
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              nivel.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.88),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// LEYENDA
/// ===============================================================

class _LeyendaRiesgo extends StatelessWidget {
  const _LeyendaRiesgo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              _IconoSeccion(
                icono: Icons.legend_toggle_outlined,
                color: AppColors.primaryBright,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Leyenda de riesgo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Rangos configurados para la evaluación IPERC.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...nivelesRiesgoIperc.map((NivelRiesgoIpercOption nivel) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemLeyenda(nivel: nivel),
            );
          }),
        ],
      ),
    );
  }
}

class _IconoSeccion extends StatelessWidget {
  const _IconoSeccion({required this.icono, required this.color});

  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icono, color: color),
    );
  }
}

/// ===============================================================
/// ITEM DE LEYENDA
/// ===============================================================

class _ItemLeyenda extends StatelessWidget {
  const _ItemLeyenda({required this.nivel});

  final NivelRiesgoIpercOption nivel;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorDesdeHex(nivel.colorHex);

    final Color foreground = _colorDeTexto(color);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
            ),
            child: Text(
              '${nivel.desde}-'
              '${nivel.hasta}',
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nivel.nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Valor ${nivel.desde} a ${nivel.hasta}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: (nivel.aceptable ? AppColors.green : AppColors.riskOrange)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  nivel.aceptable
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: nivel.aceptable
                      ? AppColors.green
                      : AppColors.riskOrange,
                  size: 17,
                ),
                const SizedBox(width: 4),
                Text(
                  nivel.aceptable ? 'Aceptable' : 'Requiere acción',
                  style: TextStyle(
                    color: nivel.aceptable
                        ? AppColors.green
                        : AppColors.riskOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
/// GUÍA DE LECTURA
/// ===============================================================

class _GuiaLectura extends StatelessWidget {
  const _GuiaLectura();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Ejemplo: si la probabilidad es 4 y la severidad es 5, '
              'el valor del riesgo es 20. El color y nivel se obtienen '
              'automáticamente de la configuración IPERC del sistema.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// COLOR DESDE HEX
/// ===============================================================

Color _colorDesdeHex(String hex) {
  String limpio = hex.replaceAll('#', '').trim();

  if (limpio.length == 6) {
    limpio = 'FF$limpio';
  }

  final int? valor = int.tryParse(limpio, radix: 16);

  return valor == null ? AppColors.textSecondary : Color(valor);
}

/// ===============================================================
/// CONTRASTE AUTOMÁTICO
/// ===============================================================

Color _colorDeTexto(Color fondo) {
  return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
      ? Colors.white
      : Colors.black87;
}
