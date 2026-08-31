# Roles y permisos

Roles funcionales de SST EduRisk:

| Rol | Administración de usuarios/roles | Catálogos | Matrices IPERC | Seguimientos | Reportes |
|---|---:|---:|---:|---:|---:|
| SUPER_ADMIN | Sí | Sí | Sí | Sí | Sí |
| ADMIN | No | Sí | Sí | Sí | Sí |
| COORDINADOR | No | Sí | Sí | Sí | Sí |
| SUP_TITULAR | No | No | Sí | Sí | Sí |
| SUP_SUPLENTE | No | No | Sí | Sí | Sí |

## Principios

- `SUPER_ADMIN` administra usuarios, roles y operaciones críticas.
- La eliminación de registros sensibles debe restringirse según permisos.
- Los permisos deben validarse en backend; ocultar botones en Flutter no reemplaza la autorización del servidor.
- La sesión offline debe conservar el rol autorizado previamente.