class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://192.168.18.23:5006/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String loginEndpoint = '/Auth/login';
  static const String solicitarAccesoEndpoint = '/Auth/solicitar-acceso';

  static const String recuperarPasswordEndpoint = '/Auth/recuperar-password';
  static const String matricesIpercEndpoint = '/MatricesIPERC';
  static const String areasEndpoint = '/Areas';
  static const String institucionesEndpoint = '/Instituciones';
  static const String sedesEndpoint = '/Sedes';
  static const String usuariosEndpoint = '/Usuarios';
  static const String solicitudesAccesoEndpoint = '/Solicitudes/acceso';
  static const String cambiarPasswordPropioEndpoint =
      '/Auth/cambiar-password-propio';
  static const String solicitudesRecuperacionEndpoint =
      '/Solicitudes/recuperacion';
  static const String rolesEndpoint = '/Roles';
  static const String puestosTrabajoEndpoint = '/PuestosTrabajo';
  static const String procesosEndpoint = '/Procesos';
  static const String actividadesEndpoint = '/Actividades';
  static const String peligrosEndpoint = '/Peligros';
  static const String consecuenciasEndpoint = '/Consecuencias';
  static const String controlesEndpoint = '/Controles';
  static const String evaluacionesRiesgoEndpoint = '/evaluaciones-riesgo';
  static const String equiposProteccionEndpoint = '/equipos-proteccion';
  static const String tiposEquipoProteccionEndpoint =
      '/tipos-equipo-proteccion';
  static const String clasificacionesControlEndpoint =
      '/clasificaciones-control';
  static const String tiposPeligroEndpoint = '/tipos-peligro';
  static const String categoriasPeligroEndpoint = '/categorias-peligro';
  static const String detallesIpercEndpoint = '/detalles-iperc';
  static const String probabilidadesEndpoint = '/Probabilidades';
  static const String severidadesEndpoint = '/Severidades';

  static const String mapasRiesgoEndpoint = '/mapas-riesgo';
  static const String mapaRiesgoUploadPlanoEndpoint =
      '/mapas-riesgo/upload-plano';
}
