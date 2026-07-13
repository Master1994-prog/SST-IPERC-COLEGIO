using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar los controles.
/// Aquí se realizan las operaciones contra la base de datos.
/// </summary>
public class ControlService : IControlService
{
    private readonly SSTDbContext _context;

    /// <summary>
    /// Constructor del servicio.
    /// Recibe el contexto de base de datos mediante inyección de dependencias.
    /// </summary>
    public ControlService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todos los controles activos.
    /// </summary>
    public async Task<IEnumerable<ControlDto>> GetAllAsync()
    {
        return await _context.Controles
            .AsNoTracking()
            .Where(x => x.Activo)
            .Select(x => new ControlDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un control por su Id.
    /// </summary>
    public async Task<ControlDto?> GetByIdAsync(long id)
    {
        return await _context.Controles
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new ControlDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Registra un nuevo control.
    /// </summary>
    public async Task<ControlDto> CreateAsync(CreateControlDto dto)
    {
        // Verifica si ya existe un control activo con el mismo código.
        var existeCodigo = await _context.Controles
            .AnyAsync(x => x.Codigo.ToLower() == dto.Codigo.ToLower() && x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe un control activo con ese código.");

        // Verifica si ya existe un control activo con el mismo nombre.
        var existeNombre = await _context.Controles
            .AnyAsync(x => x.Nombre.ToLower() == dto.Nombre.ToLower() && x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe un control activo con ese nombre.");

        // Crea la entidad control.
        var control = new Control
        {
            Codigo = dto.Codigo.Trim().ToUpper(),
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion?.Trim(),
            Activo = true
        };

        _context.Controles.Add(control);
        await _context.SaveChangesAsync();

        return new ControlDto
        {
            Id = control.Id,
            Codigo = control.Codigo,
            Nombre = control.Nombre,
            Descripcion = control.Descripcion,
            Activo = control.Activo
        };
    }

    /// <summary>
    /// Actualiza un control existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateControlDto dto)
    {
        var control = await _context.Controles
            .FirstOrDefaultAsync(x => x.Id == id);

        if (control is null)
            return false;

        // Evita duplicar el código en otro registro activo.
        var existeCodigo = await _context.Controles
            .AnyAsync(x =>
                x.Id != id &&
                x.Codigo.ToLower() == dto.Codigo.ToLower() &&
                x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe otro control activo con ese código.");

        // Evita duplicar el nombre en otro registro activo.
        var existeNombre = await _context.Controles
            .AnyAsync(x =>
                x.Id != id &&
                x.Nombre.ToLower() == dto.Nombre.ToLower() &&
                x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe otro control activo con ese nombre.");

        // Actualiza los datos del control.
        control.Codigo = dto.Codigo.Trim().ToUpper();
        control.Nombre = dto.Nombre.Trim();
        control.Descripcion = dto.Descripcion?.Trim();
        control.Activo = dto.Activo;
        control.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva un control.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var control = await _context.Controles
            .FirstOrDefaultAsync(x => x.Id == id);

        if (control is null)
            return false;

        control.Activo = false;
        control.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
