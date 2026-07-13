using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar tipos de Equipo de Protección Personal.
/// </summary>
public class TipoEquipoProteccionService : ITipoEquipoProteccionService
{
    private readonly SSTDbContext _context;

    public TipoEquipoProteccionService(SSTDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<TipoEquipoProteccionDto>> GetAllAsync()
    {
        return await _context.Set<TipoEquipoProteccion>()
            .AsNoTracking()
            .Where(x => x.Activo)
            .OrderBy(x => x.Orden)
            .Select(x => new TipoEquipoProteccionDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Orden = x.Orden,
                Activo = x.Activo,
                EsGlobal = x.EsGlobal,
                ColegioId = x.ColegioId
            })
            .ToListAsync();
    }

    public async Task<TipoEquipoProteccionDto?> GetByIdAsync(long id)
    {
        return await _context.Set<TipoEquipoProteccion>()
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new TipoEquipoProteccionDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Orden = x.Orden,
                Activo = x.Activo,
                EsGlobal = x.EsGlobal,
                ColegioId = x.ColegioId
            })
            .FirstOrDefaultAsync();
    }

    public async Task<TipoEquipoProteccionDto> CreateAsync(CreateTipoEquipoProteccionDto dto)
    {
        var existeCodigo = await _context.Set<TipoEquipoProteccion>()
            .AnyAsync(x => x.Codigo.ToLower() == dto.Codigo.ToLower() && x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe un tipo de equipo de protección activo con ese código.");

        var existeNombre = await _context.Set<TipoEquipoProteccion>()
            .AnyAsync(x => x.Nombre.ToLower() == dto.Nombre.ToLower() && x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe un tipo de equipo de protección activo con ese nombre.");

        var tipo = new TipoEquipoProteccion
        {
            Codigo = dto.Codigo.Trim().ToUpper(),
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion?.Trim(),
            Orden = dto.Orden,
            Activo = true,
            EsGlobal = dto.EsGlobal,
            ColegioId = dto.ColegioId
        };

        _context.Set<TipoEquipoProteccion>().Add(tipo);
        await _context.SaveChangesAsync();

        return new TipoEquipoProteccionDto
        {
            Id = tipo.Id,
            Codigo = tipo.Codigo,
            Nombre = tipo.Nombre,
            Descripcion = tipo.Descripcion,
            Orden = tipo.Orden,
            Activo = tipo.Activo,
            EsGlobal = tipo.EsGlobal,
            ColegioId = tipo.ColegioId
        };
    }

    public async Task<bool> UpdateAsync(long id, UpdateTipoEquipoProteccionDto dto)
    {
        var tipo = await _context.Set<TipoEquipoProteccion>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (tipo is null)
            return false;

        var existeCodigo = await _context.Set<TipoEquipoProteccion>()
            .AnyAsync(x =>
                x.Id != id &&
                x.Codigo.ToLower() == dto.Codigo.ToLower() &&
                x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe otro tipo de equipo de protección activo con ese código.");

        var existeNombre = await _context.Set<TipoEquipoProteccion>()
            .AnyAsync(x =>
                x.Id != id &&
                x.Nombre.ToLower() == dto.Nombre.ToLower() &&
                x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe otro tipo de equipo de protección activo con ese nombre.");

        tipo.Codigo = dto.Codigo.Trim().ToUpper();
        tipo.Nombre = dto.Nombre.Trim();
        tipo.Descripcion = dto.Descripcion?.Trim();
        tipo.Orden = dto.Orden;
        tipo.Activo = dto.Activo;
        tipo.EsGlobal = dto.EsGlobal;
        tipo.ColegioId = dto.ColegioId;
        tipo.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(long id)
    {
        var tipo = await _context.Set<TipoEquipoProteccion>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (tipo is null)
            return false;

        tipo.Activo = false;
        tipo.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
