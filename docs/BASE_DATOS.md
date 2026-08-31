# Base de datos

## Motor

Servidor: MySQL.

Base de datos utilizada durante el desarrollo:

```text
sst_colegio
```

Persistencia móvil: SQLite.

## Tablas funcionales principales

El modelo incluye, entre otras:

```text
actividades
areas
categoriaspeligro
clasificacionescontrol
consecuencias
controles
detalleiperccontroles
detalleipercepp
detallesiperc
equiposproteccion
evaluacionesriesgo
instituciones
mapasriesgo
matricesiperc
nivelesriesgo
peligros
peligrosconsecuencias
peligroscontroles
peligrosEquiposProteccion
probabilidades
procesos
puestostrabajo
sedes
seguimientosiperc
severidades
tiposequipoproteccion
tipospeligro
usuarios
```

## Migraciones

Las migraciones Entity Framework Core deben ejecutarse desde la solución backend usando la configuración correspondiente al entorno.

Antes de aplicar una migración en producción:

1. Crear respaldo de la base.
2. Revisar el SQL generado.
3. Aplicar primero en un ambiente de prueba.
4. Verificar claves foráneas.
5. Aplicar en producción durante una ventana controlada.

## Datos maestros

Para que IPERC funcione correctamente deben existir datos maestros coherentes de probabilidad, severidad, niveles de riesgo, categorías/tipos de peligro, peligros, consecuencias, controles y EPP.

## Respaldos

Un respaldo de código no sustituye al respaldo de MySQL. La base debe disponer de copias periódicas y de una prueba documentada de restauración.