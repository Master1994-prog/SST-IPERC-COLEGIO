using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

public class CategoriaPeligroService : ICategoriaPeligroService
{
    private readonly SSTDbContext _context;

    public CategoriaPeligroService(SSTDbContext context)
    {
        _context = context;
    }

    public async Task<List<CategoriaPeligroDto>> GetAllAsync()
    {
        return await _context.CategoriasPeligro
            .AsNoTracking()
            .OrderBy(x => x.Orden)
            .Select(x => new CategoriaPeligroDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Color = x.Color,
                Icono = x.Icono,
                Orden = x.Orden,
                Activo = x.Activo
            })
            .ToListAsync();
    }

    public async Task<CategoriaPeligroDto?> GetByIdAsync(long id)
    {
        return await _context.CategoriasPeligro
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new CategoriaPeligroDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Color = x.Color,
                Icono = x.Icono,
                Orden = x.Orden,
                Activo = x.Activo
            })
            .FirstOrDefaultAsync();
    }

    public async Task<CategoriaPeligroDto> CreateAsync(CreateCategoriaPeligroDto dto)
    {
        var codigo = dto.Codigo.Trim().ToUpper();

        var existeCodigo = await _context.CategoriasPeligro
            .AnyAsync(x => x.Codigo == codigo);

        if (existeCodigo)
            throw new InvalidOperationException("Ya existe una categoría de peligro con el mismo código.");

        var categoria = new CategoriaPeligro
        {
            Codigo = codigo,
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion,
            Color = dto.Color,
            Icono = dto.Icono,
            Orden = dto.Orden,
            Activo = true,
            Estado = true,
            FechaRegistro = DateTime.UtcNow,
            UsuarioRegistroId = 1
        };

        await _context.CategoriasPeligro.AddAsync(categoria);
        await _context.SaveChangesAsync();

        return new CategoriaPeligroDto
        {
            Id = categoria.Id,
            Codigo = categoria.Codigo,
            Nombre = categoria.Nombre,
            Descripcion = categoria.Descripcion,
            Color = categoria.Color,
            Icono = categoria.Icono,
            Orden = categoria.Orden,
            Activo = categoria.Activo
        };
    }

    public async Task<bool> UpdateAsync(long id, UpdateCategoriaPeligroDto dto)
    {
        var categoria = await _context.CategoriasPeligro
            .FirstOrDefaultAsync(x => x.Id == id);

        if (categoria is null)
            return false;

        categoria.Nombre = dto.Nombre.Trim();
        categoria.Descripcion = dto.Descripcion;
        categoria.Color = dto.Color;
        categoria.Icono = dto.Icono;
        categoria.Orden = dto.Orden;
        categoria.Activo = dto.Activo;
        categoria.Estado = dto.Activo;
        categoria.FechaActualizacion = DateTime.UtcNow;
        categoria.UsuarioActualizacionId = 1;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(long id)
    {
        var categoria = await _context.CategoriasPeligro
            .FirstOrDefaultAsync(x => x.Id == id);

        if (categoria is null)
            return false;

        categoria.Activo = false;
        categoria.Estado = false;
        categoria.FechaActualizacion = DateTime.UtcNow;
        categoria.UsuarioActualizacionId = 1;

        await _context.SaveChangesAsync();

        return true;
    }
}
