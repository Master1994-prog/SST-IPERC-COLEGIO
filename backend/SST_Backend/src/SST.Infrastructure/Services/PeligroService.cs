using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar los peligros.
/// Aquí se realiza la lógica de negocio y el acceso a la base de datos.
/// </summary>
public class PeligroService : IPeligroService
{
    private readonly SSTDbContext _context;

    /// <summary>
    /// Constructor del servicio.
    /// Recibe el contexto de base de datos mediante inyección de dependencias.
    /// </summary>
    public PeligroService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todos los peligros activos.
    /// La categoría se obtiene desde TipoPeligro.
    /// </summary>
    public async Task<IEnumerable<PeligroDto>> GetAllAsync()
    {
        return await _context.Peligros
            .AsNoTracking()
            .Include(x => x.TipoPeligro)
                .ThenInclude(x => x.CategoriaPeligro)
            .Where(x => x.Activo)
            .Select(x => new PeligroDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,

                TipoPeligroId = x.TipoPeligroId,
                TipoPeligroNombre = x.TipoPeligro.Nombre,

                CategoriaPeligroId = x.TipoPeligro.CategoriaPeligroId,
                CategoriaPeligroNombre = x.TipoPeligro.CategoriaPeligro.Nombre,

                Fuente = x.Fuente,
                Medio = x.Medio,
                Receptor = x.Receptor,
                RequisitoLegal = x.RequisitoLegal,
                Recomendaciones = x.Recomendaciones,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un peligro por su Id.
    /// </summary>
    public async Task<PeligroDto?> GetByIdAsync(long id)
    {
        return await _context.Peligros
            .AsNoTracking()
            .Include(x => x.TipoPeligro)
                .ThenInclude(x => x.CategoriaPeligro)
            .Where(x => x.Id == id)
            .Select(x => new PeligroDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,

                TipoPeligroId = x.TipoPeligroId,
                TipoPeligroNombre = x.TipoPeligro.Nombre,

                CategoriaPeligroId = x.TipoPeligro.CategoriaPeligroId,
                CategoriaPeligroNombre = x.TipoPeligro.CategoriaPeligro.Nombre,

                Fuente = x.Fuente,
                Medio = x.Medio,
                Receptor = x.Receptor,
                RequisitoLegal = x.RequisitoLegal,
                Recomendaciones = x.Recomendaciones,
                Activo = x.Activo
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Registra un nuevo peligro.
    /// </summary>
    public async Task<PeligroDto> CreateAsync(CreatePeligroDto dto)
    {
        // Verifica que el tipo de peligro exista y esté activo.
        var tipoPeligro = await _context.TiposPeligro
            .Include(x => x.CategoriaPeligro)
            .FirstOrDefaultAsync(x => x.Id == dto.TipoPeligroId && x.Activo);

        if (tipoPeligro is null)
            throw new InvalidOperationException("El tipo de peligro seleccionado no existe o está inactivo.");

        // Evita registrar dos peligros activos con el mismo código.
        var existeCodigo = await _context.Peligros
            .AnyAsync(x => x.Codigo.ToLower() == dto.Codigo.ToLower() && x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe un peligro activo con ese código.");

        // Evita registrar dos peligros activos con el mismo nombre dentro del mismo tipo.
        var existeNombre = await _context.Peligros
            .AnyAsync(x =>
                x.Nombre.ToLower() == dto.Nombre.ToLower() &&
                x.TipoPeligroId == dto.TipoPeligroId &&
                x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe un peligro con ese nombre para el tipo seleccionado.");

        // Crea la entidad peligro.
        var peligro = new Peligro
        {
            Codigo = dto.Codigo.Trim().ToUpper(),
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion?.Trim(),
            TipoPeligroId = dto.TipoPeligroId,
            Fuente = dto.Fuente?.Trim(),
            Medio = dto.Medio?.Trim(),
            Receptor = dto.Receptor?.Trim(),
            RequisitoLegal = dto.RequisitoLegal?.Trim(),
            Recomendaciones = dto.Recomendaciones?.Trim(),
            Activo = true
        };

        _context.Peligros.Add(peligro);
        await _context.SaveChangesAsync();

        return new PeligroDto
        {
            Id = peligro.Id,
            Codigo = peligro.Codigo,
            Nombre = peligro.Nombre,
            Descripcion = peligro.Descripcion,

            TipoPeligroId = peligro.TipoPeligroId,
            TipoPeligroNombre = tipoPeligro.Nombre,

            CategoriaPeligroId = tipoPeligro.CategoriaPeligroId,
            CategoriaPeligroNombre = tipoPeligro.CategoriaPeligro.Nombre,

            Fuente = peligro.Fuente,
            Medio = peligro.Medio,
            Receptor = peligro.Receptor,
            RequisitoLegal = peligro.RequisitoLegal,
            Recomendaciones = peligro.Recomendaciones,
            Activo = peligro.Activo
        };
    }

    /// <summary>
    /// Actualiza un peligro existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdatePeligroDto dto)
    {
        // Busca el peligro.
        var peligro = await _context.Peligros
            .FirstOrDefaultAsync(x => x.Id == id);

        if (peligro is null)
            return false;

        // Verifica que el tipo de peligro exista y esté activo.
        var existeTipo = await _context.TiposPeligro
            .AnyAsync(x => x.Id == dto.TipoPeligroId && x.Activo);

        if (!existeTipo)
            throw new InvalidOperationException("El tipo de peligro seleccionado no existe o está inactivo.");

        // Evita duplicar código en otro registro activo.
        var existeCodigo = await _context.Peligros
            .AnyAsync(x =>
                x.Id != id &&
                x.Codigo.ToLower() == dto.Codigo.ToLower() &&
                x.Activo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe otro peligro activo con ese código.");

        // Evita duplicar nombre dentro del mismo tipo.
        var existeNombre = await _context.Peligros
            .AnyAsync(x =>
                x.Id != id &&
                x.Nombre.ToLower() == dto.Nombre.ToLower() &&
                x.TipoPeligroId == dto.TipoPeligroId &&
                x.Activo);

        if (existeNombre)
            throw new InvalidOperationException("Ya existe otro peligro con ese nombre para el tipo seleccionado.");

        // Actualiza los datos.
        peligro.Codigo = dto.Codigo.Trim().ToUpper();
        peligro.Nombre = dto.Nombre.Trim();
        peligro.Descripcion = dto.Descripcion?.Trim();
        peligro.TipoPeligroId = dto.TipoPeligroId;
        peligro.Fuente = dto.Fuente?.Trim();
        peligro.Medio = dto.Medio?.Trim();
        peligro.Receptor = dto.Receptor?.Trim();
        peligro.RequisitoLegal = dto.RequisitoLegal?.Trim();
        peligro.Recomendaciones = dto.Recomendaciones?.Trim();
        peligro.Activo = dto.Activo;
        peligro.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva un peligro.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var peligro = await _context.Peligros
            .FirstOrDefaultAsync(x => x.Id == id);

        if (peligro is null)
            return false;

        peligro.Activo = false;
        peligro.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
