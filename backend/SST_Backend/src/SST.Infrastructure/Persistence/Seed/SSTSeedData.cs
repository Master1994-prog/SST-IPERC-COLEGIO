using SST.Domain.IPERC.Entities;
using SST.Domain.Security.Entities;
using SST.Domain.SST.Entities;

namespace SST.Infrastructure.Persistence.Seed;

/// <summary>
/// Datos iniciales del sistema SST/IPERC.
/// Estos registros permiten que el sistema arranque con catálogos básicos.
/// </summary>
public static class SSTSeedData
{
    public static async Task SeedAsync(SSTDbContext context)
    {
        await SeedCategoriasPeligroAsync(context);
        await SeedClasificacionesControlAsync(context);
        await SeedProbabilidadesAsync(context);
        await SeedSeveridadesAsync(context);
        await SeedNivelesRiesgoAsync(context);
        await SeedTiposEquipoProteccionAsync(context);
        await SeedUsuarioAdministradorAsync(context);

        await context.SaveChangesAsync();
    }

    private static async Task SeedCategoriasPeligroAsync(SSTDbContext context)
    {
        if (context.CategoriasPeligro.Any())
            return;

        var categorias = new List<CategoriaPeligro>
        {
            new()
            {
                Codigo = "FIS",
                Nombre = "Físico",
                Descripcion = "Peligros relacionados con ruido, iluminación, temperatura, radiación o condiciones físicas del ambiente.",
                Color = "#2196F3",
                Icono = "physical",
                Orden = 1,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "QUI",
                Nombre = "Químico",
                Descripcion = "Peligros generados por sustancias químicas, gases, vapores, polvos o líquidos peligrosos.",
                Color = "#FF9800",
                Icono = "chemical",
                Orden = 2,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "BIO",
                Nombre = "Biológico",
                Descripcion = "Peligros relacionados con bacterias, virus, hongos, parásitos o agentes biológicos.",
                Color = "#4CAF50",
                Icono = "biological",
                Orden = 3,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "ERG",
                Nombre = "Ergonómico",
                Descripcion = "Peligros relacionados con posturas, movimientos repetitivos, levantamiento de cargas o diseño del puesto.",
                Color = "#9C27B0",
                Icono = "ergonomic",
                Orden = 4,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "PSI",
                Nombre = "Psicosocial",
                Descripcion = "Peligros relacionados con carga laboral, estrés, acoso, presión o clima laboral.",
                Color = "#607D8B",
                Icono = "psychosocial",
                Orden = 5,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "MEC",
                Nombre = "Mecánico",
                Descripcion = "Peligros relacionados con máquinas, herramientas, golpes, cortes, atrapamientos o proyección de partículas.",
                Color = "#795548",
                Icono = "mechanical",
                Orden = 6,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "LOC",
                Nombre = "Locativo",
                Descripcion = "Peligros relacionados con pisos, escaleras, pasillos, techos, orden, limpieza o infraestructura.",
                Color = "#009688",
                Icono = "location",
                Orden = 7,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "ELE",
                Nombre = "Eléctrico",
                Descripcion = "Peligros relacionados con instalaciones eléctricas, equipos energizados, cables o contactos eléctricos.",
                Color = "#FFC107",
                Icono = "electric",
                Orden = 8,
                UsuarioRegistroId = 1
            }
        };

        await context.CategoriasPeligro.AddRangeAsync(categorias);
    }

    private static async Task SeedClasificacionesControlAsync(SSTDbContext context)
    {
        if (context.ClasificacionesControl.Any())
            return;

        var clasificaciones = new List<ClasificacionControl>
        {
            new()
            {
                Codigo = "ELI",
                Nombre = "Eliminación",
                Descripcion = "Eliminar el peligro desde su origen.",
                Prioridad = 1,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "SUS",
                Nombre = "Sustitución",
                Descripcion = "Reemplazar el peligro por una alternativa menos riesgosa.",
                Prioridad = 2,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "ING",
                Nombre = "Control de Ingeniería",
                Descripcion = "Implementar barreras físicas, rediseños o controles técnicos.",
                Prioridad = 3,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "ADM",
                Nombre = "Control Administrativo",
                Descripcion = "Aplicar procedimientos, señalización, capacitación, supervisión o permisos de trabajo.",
                Prioridad = 4,
                UsuarioRegistroId = 1
            },
            new()
            {
                Codigo = "EPP",
                Nombre = "Equipo de Protección Personal",
                Descripcion = "Usar equipos de protección personal como última barrera de control.",
                Prioridad = 5,
                UsuarioRegistroId = 1
            }
        };

        await context.ClasificacionesControl.AddRangeAsync(clasificaciones);
    }

    private static async Task SeedProbabilidadesAsync(SSTDbContext context)
    {
        if (context.Probabilidades.Any())
            return;

        var probabilidades = new List<Probabilidad>
        {
            new() { Valor = 1, Nombre = "Rara", Descripcion = "Puede ocurrir solo en circunstancias excepcionales.", UsuarioRegistroId = 1 },
            new() { Valor = 2, Nombre = "Poco probable", Descripcion = "Podría ocurrir en algún momento.", UsuarioRegistroId = 1 },
            new() { Valor = 3, Nombre = "Posible", Descripcion = "Puede ocurrir ocasionalmente.", UsuarioRegistroId = 1 },
            new() { Valor = 4, Nombre = "Probable", Descripcion = "Puede ocurrir frecuentemente.", UsuarioRegistroId = 1 },
            new() { Valor = 5, Nombre = "Muy probable", Descripcion = "Se espera que ocurra con frecuencia.", UsuarioRegistroId = 1 }
        };

        await context.Probabilidades.AddRangeAsync(probabilidades);
    }

    private static async Task SeedSeveridadesAsync(SSTDbContext context)
    {
        if (context.Severidades.Any())
            return;

        var severidades = new List<Severidad>
        {
            new() { Valor = 1, Nombre = "Insignificante", Descripcion = "Lesión leve sin pérdida de jornada.", UsuarioRegistroId = 1 },
            new() { Valor = 2, Nombre = "Menor", Descripcion = "Lesión menor con atención básica.", UsuarioRegistroId = 1 },
            new() { Valor = 3, Nombre = "Moderada", Descripcion = "Lesión con descanso médico o afectación moderada.", UsuarioRegistroId = 1 },
            new() { Valor = 4, Nombre = "Mayor", Descripcion = "Lesión grave o incapacidad temporal significativa.", UsuarioRegistroId = 1 },
            new() { Valor = 5, Nombre = "Catastrófica", Descripcion = "Fatalidad o incapacidad permanente.", UsuarioRegistroId = 1 }
        };

        await context.Severidades.AddRangeAsync(severidades);
    }

    private static async Task SeedNivelesRiesgoAsync(SSTDbContext context)
    {
        if (context.NivelesRiesgo.Any())
            return;

        var niveles = new List<NivelRiesgo>
        {
            new()
            {
                Nombre = "Bajo",
                Desde = 1,
                Hasta = 4,
                Color = "#4CAF50",
                Aceptable = true,
                UsuarioRegistroId = 1
            },
            new()
            {
                Nombre = "Medio",
                Desde = 5,
                Hasta = 9,
                Color = "#FFC107",
                Aceptable = true,
                UsuarioRegistroId = 1
            },
            new()
            {
                Nombre = "Alto",
                Desde = 10,
                Hasta = 16,
                Color = "#FF9800",
                Aceptable = false,
                UsuarioRegistroId = 1
            },
            new()
            {
                Nombre = "Crítico",
                Desde = 17,
                Hasta = 25,
                Color = "#F44336",
                Aceptable = false,
                UsuarioRegistroId = 1
            }
        };

        await context.NivelesRiesgo.AddRangeAsync(niveles);
    }

    private static async Task SeedTiposEquipoProteccionAsync(SSTDbContext context)
    {
        if (context.TiposEquipoProteccion.Any())
            return;

        var tipos = new List<TipoEquipoProteccion>
        {
            new() { Codigo = "CAB", Nombre = "Protección de Cabeza", Descripcion = "Cascos y elementos para proteger la cabeza.", Orden = 1, UsuarioRegistroId = 1 },
            new() { Codigo = "VIS", Nombre = "Protección Visual", Descripcion = "Lentes, gafas y protectores visuales.", Orden = 2, UsuarioRegistroId = 1 },
            new() { Codigo = "AUD", Nombre = "Protección Auditiva", Descripcion = "Tapones y orejeras de seguridad.", Orden = 3, UsuarioRegistroId = 1 },
            new() { Codigo = "RES", Nombre = "Protección Respiratoria", Descripcion = "Mascarillas, respiradores y filtros.", Orden = 4, UsuarioRegistroId = 1 },
            new() { Codigo = "MAN", Nombre = "Protección de Manos", Descripcion = "Guantes de seguridad.", Orden = 5, UsuarioRegistroId = 1 },
            new() { Codigo = "PIE", Nombre = "Protección de Pies", Descripcion = "Calzado de seguridad.", Orden = 6, UsuarioRegistroId = 1 },
            new() { Codigo = "COR", Nombre = "Protección Corporal", Descripcion = "Mandiles, chalecos, ropa de trabajo y protección corporal.", Orden = 7, UsuarioRegistroId = 1 },
            new() { Codigo = "FAC", Nombre = "Protección Facial", Descripcion = "Caretas y protectores faciales.", Orden = 8, UsuarioRegistroId = 1 }
        };

        await context.TiposEquipoProteccion.AddRangeAsync(tipos);
    }

    private static async Task SeedUsuarioAdministradorAsync(SSTDbContext context)
    {
        if (context.Usuarios.Any())
            return;

        var admin = new Usuario
        {
            Nombres = "Administrador",
            Apellidos = "Sistema",
            TipoDocumento = "DNI",
            NumeroDocumento = "00000000",
            Correo = "admin@sstcolegio.local",
            Telefono = "000000000",
            NombreUsuario = "admin",
            PasswordHash = "CAMBIAR_PASSWORD_HASH",
            DebeCambiarPassword = true,
            InstitucionId = 1,
            Activo = true,
            UsuarioRegistroId = 1
        };

        await context.Usuarios.AddAsync(admin);
    }
}
