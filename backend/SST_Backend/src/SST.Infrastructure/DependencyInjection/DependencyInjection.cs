using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SST.Application.SST.Interfaces;
using SST.Infrastructure.Persistence;
using SST.Infrastructure.Services;

namespace SST.Infrastructure.DependencyInjection;

/// <summary>
/// Clase encargada de registrar los servicios de infraestructura.
/// Aquí se configura la conexión a la base de datos y los servicios del sistema.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Registra los servicios de infraestructura dentro del contenedor de dependencias.
    /// Este método se llama desde el proyecto principal SST.Api.
    /// </summary>
    /// <param name="services">Colección de servicios de la aplicación.</param>
    /// <param name="configuration">Configuración del archivo appsettings.json.</param>
    /// <returns>Servicios configurados.</returns>
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Obtiene la cadena de conexión llamada "DefaultConnection" desde appsettings.json.
        // Si no existe, lanza un error para evitar que la aplicación inicie sin base de datos.
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("No se encontró la cadena de conexión 'DefaultConnection'.");

        // Registra el contexto de base de datos SSTDbContext usando MySQL.
        // Este contexto será usado por los servicios para acceder a las tablas.
        services.AddDbContext<SSTDbContext>(options =>
        {
            options.UseMySQL(connectionString);
        });

        // Registro del servicio de Categoría de Peligro.
        services.AddScoped<ICategoriaPeligroService, CategoriaPeligroService>();

        // Registro del servicio de Tipo de Peligro.
        services.AddScoped<ITipoPeligroService, TipoPeligroService>();

        // Registro del servicio de Peligro.
        services.AddScoped<IPeligroService, PeligroService>();

        // Registro del servicio de Consecuencia.
        services.AddScoped<IConsecuenciaService, ConsecuenciaService>();

        // Registro del servicio de Control.
        services.AddScoped<IControlService, ControlService>();

        // Registro del servicio de Equipo de Protección Personal.
        services.AddScoped<IEquipoProteccionService, EquipoProteccionService>();

        // Registro del servicio de relación Peligro - Consecuencia.
        services.AddScoped<IPeligroConsecuenciaService, PeligroConsecuenciaService>();

        // Registro del servicio de relación Peligro - Control.
        services.AddScoped<IPeligroControlService, PeligroControlService>();

        services.AddScoped<IMatrizIPERCService, MatrizIPERCService>();

        services.AddScoped<IDetalleIPERCService, DetalleIPERCService>();

        services.AddScoped<IMapaRiesgoService, MapaRiesgoService>();

        services.AddScoped<ISeguimientoIPERCService, SeguimientoIPERCService>();

        services.AddScoped<IReporteIPERCService, ReporteIPERCService>();

        services.AddScoped<IEvaluacionRiesgoService, EvaluacionRiesgoService>();

        services.AddScoped<ITipoEquipoProteccionService, TipoEquipoProteccionService>();

        services.AddScoped<IClasificacionControlService, ClasificacionControlService>();

        return services;
    }
}
