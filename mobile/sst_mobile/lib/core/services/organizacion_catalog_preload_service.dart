import '../../data/datasources/local/catalogos_organizacion_local_datasource.dart';
import '../../data/datasources/remote/catalogos_remote_datasource.dart';
import '../../data/models/catalogo_item_model.dart';
import '../network/network_info.dart';

class OrganizacionCatalogPreloadService {
  OrganizacionCatalogPreloadService({
    NetworkInfo? networkInfo,
    CatalogosRemoteDatasource? remoteDatasource,
    CatalogosOrganizacionLocalDatasource? localDatasource,
  }) : _networkInfo = networkInfo ?? NetworkInfo.instance,
       _remoteDatasource = remoteDatasource ?? CatalogosRemoteDatasource(),
       _localDatasource =
           localDatasource ?? CatalogosOrganizacionLocalDatasource();

  final NetworkInfo _networkInfo;
  final CatalogosRemoteDatasource _remoteDatasource;
  final CatalogosOrganizacionLocalDatasource _localDatasource;

  bool _ejecutando = false;

  Future<bool> preload() async {
    if (_ejecutando) {
      return _tieneInstitucionesLocales();
    }

    _ejecutando = true;

    try {
      await _localDatasource.prepararTablas();

      final bool conectado = await _networkInfo.isConnected;

      if (!conectado) {
        return _tieneInstitucionesLocales();
      }

      final List<CatalogoItemModel> instituciones;

      try {
        instituciones = await _remoteDatasource.obtenerInstituciones();
      } catch (_) {
        return _tieneInstitucionesLocales();
      }

      if (instituciones.isNotEmpty) {
        await _localDatasource.guardarInstituciones(instituciones);
      }

      for (final CatalogoItemModel institucion in instituciones) {
        await _precargarInstitucion(institucion.id);
      }

      return _tieneInstitucionesLocales();
    } finally {
      _ejecutando = false;
    }
  }

  Future<void> _precargarInstitucion(int institucionId) async {
    if (institucionId <= 0) {
      return;
    }

    try {
      final List<CatalogoItemModel> sedes = await _remoteDatasource
          .obtenerSedes(institucionId: institucionId);

      await _localDatasource.guardarSedes(sedes, institucionId: institucionId);
    } catch (_) {}

    List<CatalogoItemModel> areas = <CatalogoItemModel>[];

    try {
      areas = await _remoteDatasource.obtenerAreas(
        institucionId: institucionId,
      );

      await _localDatasource.guardarAreas(areas, institucionId: institucionId);
    } catch (_) {
      try {
        areas = await _localDatasource.obtenerAreas(
          institucionId: institucionId,
        );
      } catch (_) {
        areas = <CatalogoItemModel>[];
      }
    }

    for (final CatalogoItemModel area in areas) {
      await _precargarArea(area.id);
    }
  }

  Future<void> _precargarArea(int areaId) async {
    if (areaId <= 0) {
      return;
    }

    try {
      final List<CatalogoItemModel> puestos = await _remoteDatasource
          .obtenerPuestosTrabajo(areaId: areaId);

      await _localDatasource.guardarPuestosTrabajo(puestos, areaId: areaId);
    } catch (_) {}

    List<CatalogoItemModel> procesos = <CatalogoItemModel>[];

    try {
      procesos = await _remoteDatasource.obtenerProcesos(areaId: areaId);

      await _localDatasource.guardarProcesos(procesos, areaId: areaId);
    } catch (_) {
      try {
        procesos = await _localDatasource.obtenerProcesos(areaId: areaId);
      } catch (_) {
        procesos = <CatalogoItemModel>[];
      }
    }

    for (final CatalogoItemModel proceso in procesos) {
      await _precargarProceso(proceso.id);
    }
  }

  Future<void> _precargarProceso(int procesoId) async {
    if (procesoId <= 0) {
      return;
    }

    try {
      final List<CatalogoItemModel> actividades = await _remoteDatasource
          .obtenerActividades(procesoId: procesoId);

      await _localDatasource.guardarActividades(
        actividades,
        procesoId: procesoId,
      );
    } catch (_) {}
  }

  Future<bool> _tieneInstitucionesLocales() async {
    try {
      final List<CatalogoItemModel> instituciones = await _localDatasource
          .obtenerInstituciones();

      return instituciones.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
