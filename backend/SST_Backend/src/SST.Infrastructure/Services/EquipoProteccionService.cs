using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar los Equipos de Protección Personal.
/// Aquí se realiza la lógica de negocio y el acceso a base de datos.
/// </summary>
public class EquipoProteccionService : IEquipoProteccionService
{
    private readonly SSTDbContext _context;

    /// <summary>
    /// Constructor del servicio.
    /// Recibe el contexto de base de datos por inyección de dependencias.
    /// </summary>
    public EquipoProteccionService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todos los equipos de protección activos.
    /// </summary>
    public async Task<IEnumerable<EquipoProteccionDto>> GetAllAsync()
    {
        return await _context.Set<EquipoProteccion>()
            .AsNoTracking()
            .Include(x => x.TipoEquipoProteccion)
            .Where(x => x.Activo)
            .Select(x => new EquipoProteccionDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                TipoEquipoProteccionId = x.TipoEquipoProteccionId,
                TipoEquipoProteccionNombre = x.TipoEquipoProteccion.Nombre,
                Marca = x.Marca,
                Modelo = x.Modelo,
                NormaTecnica = x.NormaTecnica,
                VidaUtilMeses = x.VidaUtilMeses,
                RequiereCapacitacion = x.RequiereCapacitacion,
                RequiereMantenimiento = x.RequiereMantenimiento,
                Activo = x.Activo,
                EsGlobal = x.EsGlobal,
                ColegioId = x.ColegioId
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un equipo de protección por su Id.
    /// </summary>
    public async Task<EquipoProteccionDto?> GetByIdAsync(long id)
    {
        return await _context.Set<EquipoProteccion>()
            .AsNoTracking()
            .Include(x => x.TipoEquipoProteccion)
            .Where(x => x.Id == id)
            .Select(x => new EquipoProteccionDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                TipoEquipoProteccionId = x.TipoEquipoProteccionId,
                TipoEquipoProteccionNombre = x.TipoEquipoProteccion.Nombre,
                Marca = x.Marca,
                Modelo = x.Modelo,
                NormaTecnica = x.NormaTecnica,
                VidaUtilMeses = x.VidaUtilMeses,
                RequiereCapacitacion = x.RequiereCapacitacion,
                RequiereMantenimiento = x.RequiereMantenimiento,
                Activo = x.Activo,
                EsGlobal = x.EsGlobal,
                ColegioId = x.ColegioId
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Registra un nuevo equipo de protección.
    /// </summary>
    public async Task<EquipoProteccionDto> CreateAsync(CreateEquipoProteccionDto dto)
    {
        // Verifica que el tipo de equipo exista y esté activo.
        var tipoEquipo = await _context.Set<TipoEquipoProteccion>()
            .FirstOrDefaultAsync(x => x.Id == dto.TipoEquipoProteccionId && x.Activo);

        if (tipoEquipo is null)
            throw new InvalidOperationException("El tipo de equipo de protección seleccionado no existe o está inactivo.");

        // Evita registrar dos equipos activos con el mismo código.
        var existeCodigo = await _context.Set<EquipoProteccion>()
            .AnyAsync(x => x.Codigo.ToLower() == dto.Codigo.ToLower() && x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe un equipo de protección activo con ese código.");

        // Evita registrar dos equipos activos con el mismo nombre.
        var existeNombre = await _context.Set<EquipoProteccion>()
            .AnyAsync(x => x.Nombre.ToLower() == dto.Nombre.ToLower() && x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe un equipo de protección activo con ese nombre.");

        // Crea la entidad EquipoProteccion.
        var equipo = new EquipoProteccion
        {
            Codigo = dto.Codigo.Trim().ToUpper(),
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion?.Trim(),
            TipoEquipoProteccionId = dto.TipoEquipoProteccionId,
            Marca = dto.Marca?.Trim(),
            Modelo = dto.Modelo?.Trim(),
            NormaTecnica = dto.NormaTecnica?.Trim(),
            VidaUtilMeses = dto.VidaUtilMeses,
            RequiereCapacitacion = dto.RequiereCapacitacion,
            RequiereMantenimiento = dto.RequiereMantenimiento,
            Activo = true,
            EsGlobal = dto.EsGlobal,
            ColegioId = dto.ColegioId
        };

        _context.Set<EquipoProteccion>().Add(equipo);
        await _context.SaveChangesAsync();

        return new EquipoProteccionDto
        {
            Id = equipo.Id,
            Codigo = equipo.Codigo,
            Nombre = equipo.Nombre,
            Descripcion = equipo.Descripcion,
            TipoEquipoProteccionId = equipo.TipoEquipoProteccionId,
            TipoEquipoProteccionNombre = tipoEquipo.Nombre,
            Marca = equipo.Marca,
            Modelo = equipo.Modelo,
            NormaTecnica = equipo.NormaTecnica,
            VidaUtilMeses = equipo.VidaUtilMeses,
            RequiereCapacitacion = equipo.RequiereCapacitacion,
            RequiereMantenimiento = equipo.RequiereMantenimiento,
            Activo = equipo.Activo,
            EsGlobal = equipo.EsGlobal,
            ColegioId = equipo.ColegioId
        };
    }

    /// <summary>
    /// Actualiza un equipo de protección existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateEquipoProteccionDto dto)
    {
        var equipo = await _context.Set<EquipoProteccion>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (equipo is null)
            return false;

        // Verifica que el tipo de equipo exista y esté activo.
        var existeTipo = await _context.Set<TipoEquipoProteccion>()
            .AnyAsync(x => x.Id == dto.TipoEquipoProteccionId && x.Activo);

        if (!existeTipo)
            throw new InvalidOperationException("El tipo de equipo de protección seleccionado no existe o está inactivo.");

        // Evita duplicar código en otro registro activo.
        var existeCodigo = await _context.Set<EquipoProteccion>()
            .AnyAsync(x =>
                x.Id != id &&
                x.Codigo.ToLower() == dto.Codigo.ToLower() &&
                x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe otro equipo de protección activo con ese código.");

        // Evita duplicar nombre en otro registro activo.
        var existeNombre = await _context.Set<EquipoProteccion>()
            .AnyAsync(x =>
                x.Id != id &&
                x.Nombre.ToLower() == dto.Nombre.ToLower() &&
                x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe otro equipo de protección activo con ese nombre.");

        // Actualiza los datos.
        equipo.Codigo = dto.Codigo.Trim().ToUpper();
        equipo.Nombre = dto.Nombre.Trim();
        equipo.Descripcion = dto.Descripcion?.Trim();
        equipo.TipoEquipoProteccionId = dto.TipoEquipoProteccionId;
        equipo.Marca = dto.Marca?.Trim();
        equipo.Modelo = dto.Modelo?.Trim();
        equipo.NormaTecnica = dto.NormaTecnica?.Trim();
        equipo.VidaUtilMeses = dto.VidaUtilMeses;
        equipo.RequiereCapacitacion = dto.RequiereCapacitacion;
        equipo.RequiereMantenimiento = dto.RequiereMantenimiento;
        equipo.Activo = dto.Activo;
        equipo.EsGlobal = dto.EsGlobal;
        equipo.ColegioId = dto.ColegioId;
        equipo.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva un equipo de protección.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var equipo = await _context.Set<EquipoProteccion>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (equipo is null)
            return false;

        equipo.Activo = false;
        equipo.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
