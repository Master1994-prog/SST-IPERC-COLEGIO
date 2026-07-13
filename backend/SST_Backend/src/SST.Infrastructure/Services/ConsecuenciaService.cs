using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar las consecuencias.
/// Aquí se realizan las operaciones contra la base de datos.
/// </summary>
public class ConsecuenciaService : IConsecuenciaService
{
    private readonly SSTDbContext _context;

    /// <summary>
    /// Constructor del servicio.
    /// Recibe el contexto de base de datos mediante inyección de dependencias.
    /// </summary>
    public ConsecuenciaService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todas las consecuencias activas.
    /// </summary>
    public async Task<IEnumerable<ConsecuenciaDto>> GetAllAsync()
    {
        return await _context.Consecuencias
            .AsNoTracking()
            .Where(x => x.Activo)
            .Select(x => new ConsecuenciaDto
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
    /// Obtiene una consecuencia por su Id.
    /// </summary>
    public async Task<ConsecuenciaDto?> GetByIdAsync(long id)
    {
        return await _context.Consecuencias
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new ConsecuenciaDto
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
    /// Registra una nueva consecuencia.
    /// </summary>
    public async Task<ConsecuenciaDto> CreateAsync(CreateConsecuenciaDto dto)
    {
        // Verifica si ya existe una consecuencia activa con el mismo código.
        var existeCodigo = await _context.Consecuencias
            .AnyAsync(x => x.Codigo.ToLower() == dto.Codigo.ToLower() && x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe una consecuencia activa con ese código.");

        // Verifica si ya existe una consecuencia activa con el mismo nombre.
        var existeNombre = await _context.Consecuencias
            .AnyAsync(x => x.Nombre.ToLower() == dto.Nombre.ToLower() && x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe una consecuencia activa con ese nombre.");

        // Crea la entidad consecuencia.
        var consecuencia = new Consecuencia
        {
            Codigo = dto.Codigo.Trim().ToUpper(),
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion?.Trim(),
            Activo = true
        };

        _context.Consecuencias.Add(consecuencia);
        await _context.SaveChangesAsync();

        return new ConsecuenciaDto
        {
            Id = consecuencia.Id,
            Codigo = consecuencia.Codigo,
            Nombre = consecuencia.Nombre,
            Descripcion = consecuencia.Descripcion,
            Activo = consecuencia.Activo
        };
    }

    /// <summary>
    /// Actualiza una consecuencia existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateConsecuenciaDto dto)
    {
        var consecuencia = await _context.Consecuencias
            .FirstOrDefaultAsync(x => x.Id == id);

        if (consecuencia is null)
            return false;

        // Evita duplicar el código en otro registro activo.
        var existeCodigo = await _context.Consecuencias
            .AnyAsync(x =>
                x.Id != id &&
                x.Codigo.ToLower() == dto.Codigo.ToLower() &&
                x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe otra consecuencia activa con ese código.");

        // Evita duplicar el nombre en otro registro activo.
        var existeNombre = await _context.Consecuencias
            .AnyAsync(x =>
                x.Id != id &&
                x.Nombre.ToLower() == dto.Nombre.ToLower() &&
                x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe otra consecuencia activa con ese nombre.");

        consecuencia.Codigo = dto.Codigo.Trim().ToUpper();
        consecuencia.Nombre = dto.Nombre.Trim();
        consecuencia.Descripcion = dto.Descripcion?.Trim();
        consecuencia.Activo = dto.Activo;
        consecuencia.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva una consecuencia.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var consecuencia = await _context.Consecuencias
            .FirstOrDefaultAsync(x => x.Id == id);

        if (consecuencia is null)
            return false;

        consecuencia.Activo = false;
        consecuencia.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
