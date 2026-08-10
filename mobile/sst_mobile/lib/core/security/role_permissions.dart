class RolePermissions {
  RolePermissions._();

  static const String superAdmin = 'SUPER_ADMIN';
  static const String admin = 'ADMIN';
  static const String supervisorTitular = 'SUP_TITULAR';
  static const String supervisorSuplente = 'SUP_SUPLENTE';
  static const String coordinador = 'COORDINADOR';

  /// Normaliza nombres/códigos de rol para comparar sin depender
  /// de mayúsculas, minúsculas, tildes, espacios o guiones.
  static String normalizar(String rol) {
    String value = rol.trim().toUpperCase();

    value = value
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (value) {
      case 'SUPER_ADMINISTRADOR':
      case 'SUPERADMIN':
      case 'SUPER_ADMIN':
        return superAdmin;
      case 'ADMINISTRADOR':
      case 'ADMIN':
        return admin;
      case 'SUPERVISOR_TITULAR':
      case 'SUP_TITULAR':
        return supervisorTitular;
      case 'SUPERVISOR_SUPLENTE':
      case 'SUP_SUPLENTE':
        return supervisorSuplente;
      case 'COORDINADOR':
        return coordinador;
      default:
        return value;
    }
  }

  static bool esSuperAdmin(String rol) {
    return normalizar(rol) == superAdmin;
  }

  static bool esAdministrador(String rol) {
    final String value = normalizar(rol);
    return value == superAdmin || value == admin;
  }

  static bool puedeAdministrarUsuarios(String rol) {
    return esAdministrador(rol);
  }

  static bool puedeAdministrarRoles(String rol) {
    return esSuperAdmin(rol);
  }

  static bool puedeAdministrarCatalogos(String rol) {
    final String value = normalizar(rol);
    return value == superAdmin || value == admin || value == coordinador;
  }

  static bool puedeGestionarMatrices(String rol) {
    final String value = normalizar(rol);
    return value == superAdmin ||
        value == admin ||
        value == supervisorTitular ||
        value == supervisorSuplente ||
        value == coordinador;
  }

  static bool puedeGestionarSeguimientos(String rol) {
    final String value = normalizar(rol);
    return value == superAdmin ||
        value == admin ||
        value == supervisorTitular ||
        value == supervisorSuplente ||
        value == coordinador;
  }

  static bool puedeVerReportes(String rol) {
    final String value = normalizar(rol);
    return value == superAdmin ||
        value == admin ||
        value == supervisorTitular ||
        value == supervisorSuplente ||
        value == coordinador;
  }

  static bool puedeEliminarRegistros(String rol) {
    final String value = normalizar(rol);
    return value == superAdmin || value == admin;
  }
}
