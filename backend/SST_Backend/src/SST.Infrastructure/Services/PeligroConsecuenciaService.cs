using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar la relación entre peligros y consecuencias.
/// Aquí se realiza la lógica de negocio y el acceso a la base de datos.
/// </summary>
public class PeligroConsecuenciaService : IPeligroConsecuenciaService
{
    private readonly SSTDbContext _context;

    /// <summary>
    /// Constructor del servicio.
    /// Recibe el contexto de base de datos mediante inyección de dependencias.
    /// </summary>
    public PeligroConsecuenciaService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todas las relaciones activas entre peligros y consecuencias.
    /// </summary>
    public async Task<IEnumerable<PeligroConsecuenciaDto>> GetAllAsync()
    {
        return await _context.Set<PeligroConsecuencia>()
            .AsNoTracking()
            .Include(x => x.Peligro)
            .Include(x => x.Consecuencia)
            .Where(x => x.Activo)
            .Select(x => new PeligroConsecuenciaDto
            {
                Id = x.Id,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ConsecuenciaId = x.ConsecuenciaId,
                ConsecuenciaNombre = x.Consecuencia.Nombre,
                Observaciones = x.Observaciones,
                Principal = x.Principal,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene una relación peligro-consecuencia por su Id.
    /// </summary>
    public async Task<PeligroConsecuenciaDto?> GetByIdAsync(long id)
    {
        return await _context.Set<PeligroConsecuencia>()
            .AsNoTracking()
            .Include(x => x.Peligro)
            .Include(x => x.Consecuencia)
            .Where(x => x.Id == id)
            .Select(x => new PeligroConsecuenciaDto
            {
                Id = x.Id,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ConsecuenciaId = x.ConsecuenciaId,
                ConsecuenciaNombre = x.Consecuencia.Nombre,
                Observaciones = x.Observaciones,
                Principal = x.Principal,
                Activo = x.Activo
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Obtiene todas las consecuencias activas asociadas a un peligro específico.
    /// </summary>
    public async Task<IEnumerable<PeligroConsecuenciaDto>> GetByPeligroIdAsync(long peligroId)
    {
        return await _context.Set<PeligroConsecuencia>()
            .AsNoTracking()
            .Include(x => x.Peligro)
            .Include(x => x.Consecuencia)
            .Where(x => x.PeligroId == peligroId && x.Activo)
            .Select(x => new PeligroConsecuenciaDto
            {
                Id = x.Id,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ConsecuenciaId = x.ConsecuenciaId,
                ConsecuenciaNombre = x.Consecuencia.Nombre,
                Observaciones = x.Observaciones,
                Principal = x.Principal,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Registra una nueva relación entre peligro y consecuencia.
    /// </summary>
    public async Task<PeligroConsecuenciaDto> CreateAsync(CreatePeligroConsecuenciaDto dto)
    {
        // Verifica que el peligro exista y esté activo.
        var peligro = await _context.Peligros
            .FirstOrDefaultAsync(x => x.Id == dto.PeligroId && x.Activo);

        if (peligro is null)
            throw new InvalidOperationException("El peligro seleccionado no existe o está inactivo.");

        // Verifica que la consecuencia exista y esté activa.
        var consecuencia = await _context.Consecuencias
            .FirstOrDefaultAsync(x => x.Id == dto.ConsecuenciaId && x.Activo);

        if (consecuencia is null)
            throw new InvalidOperationException("La consecuencia seleccionada no existe o está inactiva.");

        // Evita registrar la misma consecuencia dos veces para el mismo peligro.
        var existeRelacion = await _context.Set<PeligroConsecuencia>()
            .AnyAsync(x =>
                x.PeligroId == dto.PeligroId &&
                x.ConsecuenciaId == dto.ConsecuenciaId &&
                x.Activo);

        if (existeRelacion)
            throw new InvalidOperationException("Esta consecuencia ya está asociada al peligro seleccionado.");

        // Si se marca como principal, se desmarcan las demás consecuencias principales del mismo peligro.
        if (dto.Principal)
        {
            var principales = await _context.Set<PeligroConsecuencia>()
                .Where(x => x.PeligroId == dto.PeligroId && x.Principal && x.Activo)
                .ToListAsync();

            foreach (var item in principales)
            {
                item.Principal = false;
                item.FechaActualizacion = DateTime.UtcNow;
            }
        }

        // Crea la relación.
        var peligroConsecuencia = new PeligroConsecuencia
        {
            PeligroId = dto.PeligroId,
            ConsecuenciaId = dto.ConsecuenciaId,
            Observaciones = dto.Observaciones?.Trim(),
            Principal = dto.Principal,
            Activo = true
        };

        _context.Set<PeligroConsecuencia>().Add(peligroConsecuencia);
        await _context.SaveChangesAsync();

        return new PeligroConsecuenciaDto
        {
            Id = peligroConsecuencia.Id,
            PeligroId = peligroConsecuencia.PeligroId,
            PeligroNombre = peligro.Nombre,
            ConsecuenciaId = peligroConsecuencia.ConsecuenciaId,
            ConsecuenciaNombre = consecuencia.Nombre,
            Observaciones = peligroConsecuencia.Observaciones,
            Principal = peligroConsecuencia.Principal,
            Activo = peligroConsecuencia.Activo
        };
    }

    /// <summary>
    /// Actualiza una relación peligro-consecuencia existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdatePeligroConsecuenciaDto dto)
    {
        var peligroConsecuencia = await _context.Set<PeligroConsecuencia>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (peligroConsecuencia is null)
            return false;

        // Verifica que el peligro exista y esté activo.
        var existePeligro = await _context.Peligros
            .AnyAsync(x => x.Id == dto.PeligroId && x.Activo);

        if (!existePeligro)
            throw new InvalidOperationException("El peligro seleccionado no existe o está inactivo.");

        // Verifica que la consecuencia exista y esté activa.
        var existeConsecuencia = await _context.Consecuencias
            .AnyAsync(x => x.Id == dto.ConsecuenciaId && x.Activo);

        if (!existeConsecuencia)
            throw new InvalidOperationException("La consecuencia seleccionada no existe o está inactiva.");

        // Evita duplicar la misma relación en otro registro.
        var existeRelacion = await _context.Set<PeligroConsecuencia>()
            .AnyAsync(x =>
                x.Id != id &&
                x.PeligroId == dto.PeligroId &&
                x.ConsecuenciaId == dto.ConsecuenciaId &&
                x.Activo);

        if (existeRelacion)
            throw new InvalidOperationException("Esta consecuencia ya está asociada al peligro seleccionado.");

        // Si se marca como principal, se desmarcan las otras relaciones principales del mismo peligro.
        if (dto.Principal)
        {
            var principales = await _context.Set<PeligroConsecuencia>()
                .Where(x =>
                    x.Id != id &&
                    x.PeligroId == dto.PeligroId &&
                    x.Principal &&
                    x.Activo)
                .ToListAsync();

            foreach (var item in principales)
            {
                item.Principal = false;
                item.FechaActualizacion = DateTime.UtcNow;
            }
        }

        // Actualiza los datos.
        peligroConsecuencia.PeligroId = dto.PeligroId;
        peligroConsecuencia.ConsecuenciaId = dto.ConsecuenciaId;
        peligroConsecuencia.Observaciones = dto.Observaciones?.Trim();
        peligroConsecuencia.Principal = dto.Principal;
        peligroConsecuencia.Activo = dto.Activo;
        peligroConsecuencia.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva una relación peligro-consecuencia.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var peligroConsecuencia = await _context.Set<PeligroConsecuencia>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (peligroConsecuencia is null)
            return false;

        peligroConsecuencia.Activo = false;
        peligroConsecuencia.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
