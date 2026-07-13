using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.IPERC.Entities;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar los seguimientos IPERC.
/// Permite registrar avances, evidencias y verificaciones.
/// </summary>
public class SeguimientoIPERCService : ISeguimientoIPERCService
{
    private readonly SSTDbContext _context;

    public SeguimientoIPERCService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todos los seguimientos IPERC.
    /// </summary>
    public async Task<IEnumerable<SeguimientoIPERCDto>> GetAllAsync()
    {
        return await _context.Set<SeguimientoIPERC>()
            .AsNoTracking()
            .Include(x => x.DetalleIPERC)
            .Include(x => x.Usuario)
            .Select(x => new SeguimientoIPERCDto
            {
                Id = x.Id,
                DetalleIPERCId = x.DetalleIPERCId,
                DetalleItem = x.DetalleIPERC.Item,
                DetalleTarea = x.DetalleIPERC.Tarea,
                FechaSeguimiento = x.FechaSeguimiento,
                UsuarioId = x.UsuarioId,

                // Se muestra un texto simple porque la entidad Usuario no tiene propiedad Nombre.
                UsuarioNombre = "Usuario ID: " + x.UsuarioId,

                Descripcion = x.Descripcion,
                PorcentajeAvance = x.PorcentajeAvance,
                Verificado = x.Verificado,
                FechaVerificacion = x.FechaVerificacion,
                Observaciones = x.Observaciones,
                Archivo = x.Archivo,
                NombreArchivo = x.NombreArchivo,
                TipoArchivo = x.TipoArchivo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un seguimiento IPERC por su Id.
    /// </summary>
    public async Task<SeguimientoIPERCDto?> GetByIdAsync(long id)
    {
        return await _context.Set<SeguimientoIPERC>()
            .AsNoTracking()
            .Include(x => x.DetalleIPERC)
            .Include(x => x.Usuario)
            .Where(x => x.Id == id)
            .Select(x => new SeguimientoIPERCDto
            {
                Id = x.Id,
                DetalleIPERCId = x.DetalleIPERCId,
                DetalleItem = x.DetalleIPERC.Item,
                DetalleTarea = x.DetalleIPERC.Tarea,
                FechaSeguimiento = x.FechaSeguimiento,
                UsuarioId = x.UsuarioId,

                // Se muestra un texto simple porque la entidad Usuario no tiene propiedad Nombre.
                UsuarioNombre = "Usuario ID: " + x.UsuarioId,

                Descripcion = x.Descripcion,
                PorcentajeAvance = x.PorcentajeAvance,
                Verificado = x.Verificado,
                FechaVerificacion = x.FechaVerificacion,
                Observaciones = x.Observaciones,
                Archivo = x.Archivo,
                NombreArchivo = x.NombreArchivo,
                TipoArchivo = x.TipoArchivo
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Obtiene los seguimientos asociados a un detalle IPERC.
    /// </summary>
    public async Task<IEnumerable<SeguimientoIPERCDto>> GetByDetalleIdAsync(long detalleIPERCId)
    {
        return await _context.Set<SeguimientoIPERC>()
            .AsNoTracking()
            .Include(x => x.DetalleIPERC)
            .Include(x => x.Usuario)
            .Where(x => x.DetalleIPERCId == detalleIPERCId)
            .OrderByDescending(x => x.FechaSeguimiento)
            .Select(x => new SeguimientoIPERCDto
            {
                Id = x.Id,
                DetalleIPERCId = x.DetalleIPERCId,
                DetalleItem = x.DetalleIPERC.Item,
                DetalleTarea = x.DetalleIPERC.Tarea,
                FechaSeguimiento = x.FechaSeguimiento,
                UsuarioId = x.UsuarioId,

                // Se muestra un texto simple porque la entidad Usuario no tiene propiedad Nombre.
                UsuarioNombre = "Usuario ID: " + x.UsuarioId,

                Descripcion = x.Descripcion,
                PorcentajeAvance = x.PorcentajeAvance,
                Verificado = x.Verificado,
                FechaVerificacion = x.FechaVerificacion,
                Observaciones = x.Observaciones,
                Archivo = x.Archivo,
                NombreArchivo = x.NombreArchivo,
                TipoArchivo = x.TipoArchivo
            })
            .ToListAsync();
    }

    /// <summary>
    /// Registra un nuevo seguimiento IPERC.
    /// </summary>
    public async Task<SeguimientoIPERCDto> CreateAsync(CreateSeguimientoIPERCDto dto)
    {
        var detalle = await _context.Set<DetalleIPERC>()
            .FirstOrDefaultAsync(x => x.Id == dto.DetalleIPERCId);

        if (detalle is null)
            throw new InvalidOperationException("El detalle IPERC seleccionado no existe.");

        var usuario = await _context.Set<Usuario>()
            .FirstOrDefaultAsync(x => x.Id == dto.UsuarioId);

        if (usuario is null)
            throw new InvalidOperationException("El usuario responsable del seguimiento no existe.");

        // Corrección: declarar como DateTime? para permitir null.
        DateTime? fechaVerificacion = dto.Verificado
            ? dto.FechaVerificacion ?? DateTime.UtcNow
            : null;

        var seguimiento = new SeguimientoIPERC
        {
            DetalleIPERCId = dto.DetalleIPERCId,
            FechaSeguimiento = dto.FechaSeguimiento == default
                ? DateTime.UtcNow
                : dto.FechaSeguimiento,
            UsuarioId = dto.UsuarioId,
            Descripcion = dto.Descripcion.Trim(),
            PorcentajeAvance = dto.PorcentajeAvance,
            Verificado = dto.Verificado,
            FechaVerificacion = fechaVerificacion,
            Observaciones = dto.Observaciones?.Trim(),
            Archivo = dto.Archivo?.Trim(),
            NombreArchivo = dto.NombreArchivo?.Trim(),
            TipoArchivo = dto.TipoArchivo?.Trim()
        };

        _context.Set<SeguimientoIPERC>().Add(seguimiento);
        await _context.SaveChangesAsync();

        return new SeguimientoIPERCDto
        {
            Id = seguimiento.Id,
            DetalleIPERCId = seguimiento.DetalleIPERCId,
            DetalleItem = detalle.Item,
            DetalleTarea = detalle.Tarea,
            FechaSeguimiento = seguimiento.FechaSeguimiento,
            UsuarioId = seguimiento.UsuarioId,

            // Se muestra un texto simple porque la entidad Usuario no tiene propiedad Nombre.
            UsuarioNombre = "Usuario ID: " + seguimiento.UsuarioId,

            Descripcion = seguimiento.Descripcion,
            PorcentajeAvance = seguimiento.PorcentajeAvance,
            Verificado = seguimiento.Verificado,
            FechaVerificacion = seguimiento.FechaVerificacion,
            Observaciones = seguimiento.Observaciones,
            Archivo = seguimiento.Archivo,
            NombreArchivo = seguimiento.NombreArchivo,
            TipoArchivo = seguimiento.TipoArchivo
        };
    }

    /// <summary>
    /// Actualiza un seguimiento IPERC existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateSeguimientoIPERCDto dto)
    {
        var seguimiento = await _context.Set<SeguimientoIPERC>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (seguimiento is null)
            return false;

        var detalleExiste = await _context.Set<DetalleIPERC>()
            .AnyAsync(x => x.Id == dto.DetalleIPERCId);

        if (!detalleExiste)
            throw new InvalidOperationException("El detalle IPERC seleccionado no existe.");

        var usuarioExiste = await _context.Set<Usuario>()
            .AnyAsync(x => x.Id == dto.UsuarioId);

        if (!usuarioExiste)
            throw new InvalidOperationException("El usuario responsable del seguimiento no existe.");

        // Corrección: declarar como DateTime? para permitir null.
        DateTime? fechaVerificacion = dto.Verificado
            ? dto.FechaVerificacion ?? DateTime.UtcNow
            : null;

        seguimiento.DetalleIPERCId = dto.DetalleIPERCId;
        seguimiento.FechaSeguimiento = dto.FechaSeguimiento == default
            ? DateTime.UtcNow
            : dto.FechaSeguimiento;
        seguimiento.UsuarioId = dto.UsuarioId;
        seguimiento.Descripcion = dto.Descripcion.Trim();
        seguimiento.PorcentajeAvance = dto.PorcentajeAvance;
        seguimiento.Verificado = dto.Verificado;
        seguimiento.FechaVerificacion = fechaVerificacion;
        seguimiento.Observaciones = dto.Observaciones?.Trim();
        seguimiento.Archivo = dto.Archivo?.Trim();
        seguimiento.NombreArchivo = dto.NombreArchivo?.Trim();
        seguimiento.TipoArchivo = dto.TipoArchivo?.Trim();
        seguimiento.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Elimina físicamente un seguimiento IPERC.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var seguimiento = await _context.Set<SeguimientoIPERC>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (seguimiento is null)
            return false;

        _context.Set<SeguimientoIPERC>().Remove(seguimiento);
        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Marca un seguimiento como verificado.
    /// </summary>
    public async Task<bool> VerificarAsync(long id)
    {
        var seguimiento = await _context.Set<SeguimientoIPERC>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (seguimiento is null)
            return false;

        seguimiento.Verificado = true;
        seguimiento.FechaVerificacion = DateTime.UtcNow;
        seguimiento.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
