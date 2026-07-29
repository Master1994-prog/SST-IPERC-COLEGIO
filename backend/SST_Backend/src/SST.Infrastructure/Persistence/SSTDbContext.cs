using Microsoft.EntityFrameworkCore;
using SST.Domain.SST.Entities;
using SST.Domain.IPERC.Entities;
using SST.Domain.Security.Entities;
using SST.Domain.Organization.Entities;

namespace SST.Infrastructure.Persistence;

/// <summary>
/// Contexto principal de base de datos del sistema SST.
/// Aquí se registran las entidades del dominio y sus configuraciones.
/// </summary>
public class SSTDbContext : DbContext
{
    public SSTDbContext(DbContextOptions<SSTDbContext> options)
        : base(options)
    {
    }

    #region SST

    public DbSet<CategoriaPeligro> CategoriasPeligro { get; set; }
    public DbSet<TipoPeligro> TiposPeligro { get; set; }
    public DbSet<Peligro> Peligros { get; set; }
    public DbSet<Consecuencia> Consecuencias { get; set; }
    public DbSet<PeligroConsecuencia> PeligrosConsecuencias { get; set; }

    public DbSet<ClasificacionControl> ClasificacionesControl =>
        Set<ClasificacionControl>();
    
    public DbSet<Control> Controles { get; set; }
    public DbSet<PeligroControl> PeligrosControles { get; set; }

    public DbSet<TipoEquipoProteccion> TiposEquipoProteccion { get; set; }
    public DbSet<EquipoProteccion> EquiposProteccion { get; set; }
    public DbSet<PeligroEquipoProteccion> PeligrosEquiposProteccion { get; set; }

    #endregion

    #region IPERC

    public DbSet<MatrizIPERC> MatricesIPERC { get; set; }
    public DbSet<DetalleIPERC> DetallesIPERC { get; set; }

    public DbSet<Probabilidad> Probabilidades { get; set; }
    public DbSet<Severidad> Severidades { get; set; }
    public DbSet<NivelRiesgo> NivelesRiesgo { get; set; }
    public DbSet<EvaluacionRiesgo> EvaluacionesRiesgo { get; set; }

    public DbSet<DetalleIPERCControl> DetalleIPERCControles { get; set; }
    public DbSet<DetalleIPERCEPP> DetalleIPERCEPP { get; set; }
    public DbSet<SeguimientoIPERC> SeguimientosIPERC { get; set; }
    public DbSet<MapaRiesgo> MapasRiesgo { get; set; }

    #endregion

    #region Security

    public DbSet<Usuario> Usuarios { get; set; }

    public DbSet<Rol> Roles { get; set; }
    public DbSet<UsuarioRol> UsuariosRoles { get; set; }

    #endregion

    #region Organization

    public DbSet<SST.Domain.Organization.Entities.Institucion> Instituciones
    {
        get;
        set;
    }

    public DbSet<Area> Areas { get; set; }

    public DbSet<Proceso> Procesos { get; set; }

    public DbSet<Sede> Sedes { get; set; }

    public DbSet<Actividad> Actividades { get; set; }

    public DbSet<PuestoTrabajo> PuestosTrabajo { get; set; }

    #endregion

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Aplica automáticamente todas las configuraciones
        // que estén dentro del proyecto SST.Infrastructure.
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(SSTDbContext).Assembly);
    }
}
