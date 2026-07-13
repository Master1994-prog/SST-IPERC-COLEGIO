using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de la lógica de negocio para los tipos de peligro.
/// Aquí se realizan las operaciones contra la base de datos.
/// </summary>
public class TipoPeligroService : ITipoPeligroService
{
    private readonly SSTDbContext _context;

    /// <summary>
    /// Constructor del servicio.
    /// Recibe el contexto de base de datos mediante inyección de dependencias.
    /// </summary>
    public TipoPeligroService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todos los tipos de peligro activos.
    /// </summary>
    public async Task<IEnumerable<TipoPeligroDto>> GetAllAsync()
    {
        return await _context.TiposPeligro
            .AsNoTracking()
            .Include(x => x.CategoriaPeligro)
            .Where(x => x.Activo)
            .Select(x => new TipoPeligroDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                CategoriaPeligroId = x.CategoriaPeligroId,
                CategoriaPeligroNombre = x.CategoriaPeligro != null ? x.CategoriaPeligro.Nombre : null,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un tipo de peligro por su Id.
    /// </summary>
    public async Task<TipoPeligroDto?> GetByIdAsync(long id)
    {
        return await _context.TiposPeligro
            .AsNoTracking()
            .Include(x => x.CategoriaPeligro)
            .Where(x => x.Id == id)
            .Select(x => new TipoPeligroDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                CategoriaPeligroId = x.CategoriaPeligroId,
                CategoriaPeligroNombre = x.CategoriaPeligro != null ? x.CategoriaPeligro.Nombre : null,
                Activo = x.Activo
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Registra un nuevo tipo de peligro.
    /// </summary>
    public async Task<TipoPeligroDto> CreateAsync(CreateTipoPeligroDto dto)
    {
        var existeCodigo = await _context.TiposPeligro
            .AnyAsync(x => x.Codigo.ToLower() == dto.Codigo.ToLower() && x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe un tipo de peligro activo con ese código.");

        // Verifica que la categoría de peligro exista.
        var existeCategoria = await _context.CategoriasPeligro
            .AnyAsync(x => x.Id == dto.CategoriaPeligroId && x.Activo);

        if (!existeCategoria)
            throw new InvalidOperationException("La categoría de peligro seleccionada no existe o está inactiva.");

        // Evita registrar tipos de peligro duplicados dentro de la misma categoría.
        var existeTipo = await _context.TiposPeligro
            .AnyAsync(x =>
                x.Nombre.ToLower() == dto.Nombre.ToLower()
                && x.CategoriaPeligroId == dto.CategoriaPeligroId
                && x.Activo);

        if (existeTipo)
            throw new InvalidOperationException("Ya existe un tipo de peligro con ese nombre en la categoría seleccionada.");

        var tipoPeligro = new TipoPeligro
        {
            Codigo = dto.Codigo.Trim().ToUpper(),
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion?.Trim(),
            CategoriaPeligroId = dto.CategoriaPeligroId,
            Activo = true
        };

        _context.TiposPeligro.Add(tipoPeligro);
        await _context.SaveChangesAsync();

        return new TipoPeligroDto
        {
            Id = tipoPeligro.Id,
            Nombre = tipoPeligro.Nombre,
            Descripcion = tipoPeligro.Descripcion,
            CategoriaPeligroId = tipoPeligro.CategoriaPeligroId,
            Codigo = tipoPeligro.Codigo,
            Activo = tipoPeligro.Activo
        };
    }

    /// <summary>
    /// Actualiza un tipo de peligro existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateTipoPeligroDto dto)
    {
        var existeCodigo = await _context.TiposPeligro
            .AnyAsync(x =>
                x.Id != id &&
                x.Codigo.ToLower() == dto.Codigo.ToLower() &&
                x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe otro tipo de peligro activo con ese código.");

        var tipoPeligro = await _context.TiposPeligro
            .FirstOrDefaultAsync(x => x.Id == id);

        if (tipoPeligro is null)
            return false;

        // Verifica que la categoría de peligro exista.
        var existeCategoria = await _context.CategoriasPeligro
            .AnyAsync(x => x.Id == dto.CategoriaPeligroId && x.Activo);

        if (!existeCategoria)
            throw new InvalidOperationException("La categoría de peligro seleccionada no existe o está inactiva.");

        // Evita duplicados en otra fila diferente al registro actual.
        var existeTipo = await _context.TiposPeligro
            .AnyAsync(x =>
                x.Id != id
                && x.Nombre.ToLower() == dto.Nombre.ToLower()
                && x.CategoriaPeligroId == dto.CategoriaPeligroId
                && x.Activo);

        if (existeTipo)
            throw new InvalidOperationException("Ya existe otro tipo de peligro con ese nombre en la categoría seleccionada.");

        tipoPeligro.Codigo = dto.Codigo.Trim().ToUpper();
        tipoPeligro.Nombre = dto.Nombre.Trim();
        tipoPeligro.Descripcion = dto.Descripcion?.Trim();
        tipoPeligro.CategoriaPeligroId = dto.CategoriaPeligroId;
        tipoPeligro.Activo = dto.Activo;
        tipoPeligro.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva un tipo de peligro.
    /// No elimina físicamente el registro de la base de datos.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var tipoPeligro = await _context.TiposPeligro
            .FirstOrDefaultAsync(x => x.Id == id);

        if (tipoPeligro is null)
            return false;

        tipoPeligro.Activo = false;
        tipoPeligro.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
