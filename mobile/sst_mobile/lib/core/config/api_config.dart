class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://192.168.18.23:5006/api';

  static const Duration connectTimeout = Duration(seconds: 30);

  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String loginEndpoint = '/Auth/login';
  static const String matricesIpercEndpoint = '/MatricesIPERC';

  static const String institucionesEndpoint = '/Instituciones';

  static const String sedesEndpoint = '/Sedes';
  static const String areasEndpoint = '/Areas';

  static const String puestosTrabajoEndpoint = '/PuestosTrabajo';

  static const String procesosEndpoint = '/Procesos';
  static const String actividadesEndpoint = '/Actividades';
}
