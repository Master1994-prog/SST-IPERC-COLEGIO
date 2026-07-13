using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar la relación entre peligros y controles.
/// </summary>
public class PeligroControlService : IPeligroControlService
{
    private readonly SSTDbContext _context;

    public PeligroControlService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todas las relaciones activas entre peligros y controles.
    /// </summary>
    public async Task<IEnumerable<PeligroControlDto>> GetAllAsync()
    {
        return await _context.Set<PeligroControl>()
            .AsNoTracking()
            .Include(x => x.Peligro)
            .Include(x => x.Control)
            .Where(x => x.Activo)
            .Select(x => new PeligroControlDto
            {
                Id = x.Id,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ControlId = x.ControlId,
                ControlNombre = x.Control.Nombre,
                Obligatorio = x.Obligatorio,
                Prioridad = x.Prioridad,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene una relación peligro-control por su Id.
    /// </summary>
    public async Task<PeligroControlDto?> GetByIdAsync(long id)
    {
        return await _context.Set<PeligroControl>()
            .AsNoTracking()
            .Include(x => x.Peligro)
            .Include(x => x.Control)
            .Where(x => x.Id == id)
            .Select(x => new PeligroControlDto
            {
                Id = x.Id,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ControlId = x.ControlId,
                ControlNombre = x.Control.Nombre,
                Obligatorio = x.Obligatorio,
                Prioridad = x.Prioridad,
                Activo = x.Activo
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Obtiene los controles asociados a un peligro específico.
    /// </summary>
    public async Task<IEnumerable<PeligroControlDto>> GetByPeligroIdAsync(long peligroId)
    {
        return await _context.Set<PeligroControl>()
            .AsNoTracking()
            .Include(x => x.Peligro)
            .Include(x => x.Control)
            .Where(x => x.PeligroId == peligroId && x.Activo)
            .OrderBy(x => x.Prioridad)
            .Select(x => new PeligroControlDto
            {
                Id = x.Id,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ControlId = x.ControlId,
                ControlNombre = x.Control.Nombre,
                Obligatorio = x.Obligatorio,
                Prioridad = x.Prioridad,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Registra una nueva relación entre peligro y control.
    /// </summary>
    public async Task<PeligroControlDto> CreateAsync(CreatePeligroControlDto dto)
    {
        var peligro = await _context.Peligros
            .FirstOrDefaultAsync(x => x.Id == dto.PeligroId && x.Activo);

        if (peligro is null)
            throw new InvalidOperationException("El peligro seleccionado no existe o está inactivo.");

        var control = await _context.Controles
            .FirstOrDefaultAsync(x => x.Id == dto.ControlId && x.Activo);

        if (control is null)
            throw new InvalidOperationException("El control seleccionado no existe o está inactivo.");

        var existeRelacion = await _context.Set<PeligroControl>()
            .AnyAsync(x =>
                x.PeligroId == dto.PeligroId &&
                x.ControlId == dto.ControlId &&
                x.Activo);

        if (existeRelacion)
            throw new InvalidOperationException("Este control ya está asociado al peligro seleccionado.");

        var peligroControl = new PeligroControl
        {
            PeligroId = dto.PeligroId,
            ControlId = dto.ControlId,
            Obligatorio = dto.Obligatorio,
            Prioridad = dto.Prioridad,
            Activo = true
        };

        _context.Set<PeligroControl>().Add(peligroControl);
        await _context.SaveChangesAsync();

        return new PeligroControlDto
        {
            Id = peligroControl.Id,
            PeligroId = peligroControl.PeligroId,
            PeligroNombre = peligro.Nombre,
            ControlId = peligroControl.ControlId,
            ControlNombre = control.Nombre,
            Obligatorio = peligroControl.Obligatorio,
            Prioridad = peligroControl.Prioridad,
            Activo = peligroControl.Activo
        };
    }

    /// <summary>
    /// Actualiza una relación peligro-control existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdatePeligroControlDto dto)
    {
        var peligroControl = await _context.Set<PeligroControl>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (peligroControl is null)
            return false;

        var existePeligro = await _context.Peligros
            .AnyAsync(x => x.Id == dto.PeligroId && x.Activo);

        if (!existePeligro)
            throw new InvalidOperationException("El peligro seleccionado no existe o está inactivo.");

        var existeControl = await _context.Controles
            .AnyAsync(x => x.Id == dto.ControlId && x.Activo);

        if (!existeControl)
            throw new InvalidOperationException("El control seleccionado no existe o está inactivo.");

        var existeRelacion = await _context.Set<PeligroControl>()
            .AnyAsync(x =>
                x.Id != id &&
                x.PeligroId == dto.PeligroId &&
                x.ControlId == dto.ControlId &&
                x.Activo);

        if (existeRelacion)
            throw new InvalidOperationException("Este control ya está asociado al peligro seleccionado.");

        peligroControl.PeligroId = dto.PeligroId;
        peligroControl.ControlId = dto.ControlId;
        peligroControl.Obligatorio = dto.Obligatorio;
        peligroControl.Prioridad = dto.Prioridad;
        peligroControl.Activo = dto.Activo;
        peligroControl.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva una relación peligro-control.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var peligroControl = await _context.Set<PeligroControl>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (peligroControl is null)
            return false;

        peligroControl.Activo = false;
        peligroControl.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
