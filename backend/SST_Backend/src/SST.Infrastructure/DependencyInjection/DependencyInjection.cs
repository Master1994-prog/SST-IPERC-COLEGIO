using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SST.Application.SST.Interfaces;
using SST.Infrastructure.Persistence;
using SST.Infrastructure.Services;

namespace SST.Infrastructure.DependencyInjection;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString =
            configuration.GetConnectionString("DefaultConnection");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "No se configuro ConnectionStrings:DefaultConnection. " +
                "En produccion use ConnectionStrings__DefaultConnection.");
        }

        services.AddDbContext<SSTDbContext>(options =>
        {
            options.UseMySQL(connectionString);
        });

        services.AddScoped<ICategoriaPeligroService, CategoriaPeligroService>();
        services.AddScoped<ITipoPeligroService, TipoPeligroService>();
        services.AddScoped<IPeligroService, PeligroService>();
        services.AddScoped<IConsecuenciaService, ConsecuenciaService>();
        services.AddScoped<IControlService, ControlService>();
        services.AddScoped<IEquipoProteccionService, EquipoProteccionService>();
        services.AddScoped<IPeligroConsecuenciaService, PeligroConsecuenciaService>();
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