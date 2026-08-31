# Arquitectura de SST EduRisk

## Componentes

SST EduRisk utiliza una arquitectura cliente-servidor con capacidad offline.

```text
Flutter Android
   |
   | REST/HTTP(S)
   v
ASP.NET Core Web API
   |
   v
MySQL

Flutter Android
   |
   v
SQLite local
   |
   v
Cola de sincronización
```

## Backend

El backend está organizado por capas:

- `SST.Api`: controladores HTTP, configuración, autenticación y exposición de endpoints.
- `SST.Application`: casos de uso, DTO y contratos de servicio.
- `SST.Domain`: entidades y reglas del dominio.
- `SST.Infrastructure`: persistencia, Entity Framework Core y servicios de infraestructura.

Target framework: `net10.0`.

## Aplicación móvil

La estructura principal Flutter utiliza:

- `lib/core`: configuración, tema, utilidades y servicios transversales.
- `lib/data`: modelos, datasources, repositorios y servicios.
- `lib/domain`: contratos y lógica de dominio cuando corresponda.
- `lib/presentation`: providers, pantallas y componentes de interfaz.

No se utiliza una carpeta `lib/features`.

## Persistencia

Servidor:

```text
MySQL
Base principal: sst_colegio
```

Móvil:

```text
SQLite
Base local: sst_local.db
```

## Estrategia offline

Las operaciones compatibles con modo offline se guardan localmente y se registran como pendientes. Cuando vuelve la conectividad, el servicio de sincronización intenta enviarlas al backend y relaciona el identificador local con el identificador del servidor.

La aplicación debe evitar duplicar registros cuando una entidad local ya dispone de `idServidor`.

## Matriz de riesgo

El sistema soporta evaluación 5x5 mediante probabilidad/frecuencia y severidad. El valor de riesgo se calcula a partir de ambas dimensiones y se representa visualmente por nivel de riesgo.

## Reportes

Los reportes pueden construirse con datos híbridos obtenidos del backend y SQLite. La vista previa PDF conserva una única generación del documento durante cambios de orientación para evitar regeneraciones simultáneas y consumo excesivo de memoria.