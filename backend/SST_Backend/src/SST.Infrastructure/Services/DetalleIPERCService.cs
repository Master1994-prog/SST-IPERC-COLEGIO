using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.IPERC.Entities;
using SST.Domain.IPERC.Enums;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar los detalles de una Matriz IPERC.
/// Aquí se registra cada peligro evaluado dentro de una matriz.
/// </summary>
public class DetalleIPERCService : IDetalleIPERCService
{
    private readonly SSTDbContext _context;

    public DetalleIPERCService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todos los detalles IPERC.
    /// </summary>
    public async Task<IEnumerable<DetalleIPERCDto>> GetAllAsync()
    {
        return await _context.Set<DetalleIPERC>()
            .AsNoTracking()
            .Include(x => x.MatrizIPERC)
            .Include(x => x.Peligro)
            .Include(x => x.Consecuencia)
            .Select(x => new DetalleIPERCDto
            {
                Id = x.Id,
                MatrizIPERCId = x.MatrizIPERCId,
                MatrizIPERCCodigo = x.MatrizIPERC.Codigo,
                Item = x.Item,
                Tarea = x.Tarea,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ConsecuenciaId = x.ConsecuenciaId,
                ConsecuenciaNombre = x.Consecuencia.Nombre,
                DescripcionPeligro = x.DescripcionPeligro,
                EvaluacionInicialId = x.EvaluacionInicialId,
                EvaluacionResidualId = x.EvaluacionResidualId,
                ResponsableImplementacionId = x.ResponsableImplementacionId,
                FechaCompromiso = x.FechaCompromiso,
                FechaImplementacion = x.FechaImplementacion,
                EstadoImplementacionId = (int)x.EstadoImplementacion,
                EstadoImplementacionNombre = x.EstadoImplementacion.ToString()
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un detalle IPERC por su Id.
    /// </summary>
    public async Task<DetalleIPERCDto?> GetByIdAsync(long id)
    {
        return await _context.Set<DetalleIPERC>()
            .AsNoTracking()
            .Include(x => x.MatrizIPERC)
            .Include(x => x.Peligro)
            .Include(x => x.Consecuencia)
            .Where(x => x.Id == id)
            .Select(x => new DetalleIPERCDto
            {
                Id = x.Id,
                MatrizIPERCId = x.MatrizIPERCId,
                MatrizIPERCCodigo = x.MatrizIPERC.Codigo,
                Item = x.Item,
                Tarea = x.Tarea,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ConsecuenciaId = x.ConsecuenciaId,
                ConsecuenciaNombre = x.Consecuencia.Nombre,
                DescripcionPeligro = x.DescripcionPeligro,
                EvaluacionInicialId = x.EvaluacionInicialId,
                EvaluacionResidualId = x.EvaluacionResidualId,
                ResponsableImplementacionId = x.ResponsableImplementacionId,
                FechaCompromiso = x.FechaCompromiso,
                FechaImplementacion = x.FechaImplementacion,
                EstadoImplementacionId = (int)x.EstadoImplementacion,
                EstadoImplementacionNombre = x.EstadoImplementacion.ToString()
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Obtiene todos los detalles asociados a una Matriz IPERC.
    /// </summary>
    public async Task<IEnumerable<DetalleIPERCDto>> GetByMatrizIdAsync(long matrizIPERCId)
    {
        return await _context.Set<DetalleIPERC>()
            .AsNoTracking()
            .Include(x => x.MatrizIPERC)
            .Include(x => x.Peligro)
            .Include(x => x.Consecuencia)
            .Where(x => x.MatrizIPERCId == matrizIPERCId)
            .OrderBy(x => x.Item)
            .Select(x => new DetalleIPERCDto
            {
                Id = x.Id,
                MatrizIPERCId = x.MatrizIPERCId,
                MatrizIPERCCodigo = x.MatrizIPERC.Codigo,
                Item = x.Item,
                Tarea = x.Tarea,
                PeligroId = x.PeligroId,
                PeligroNombre = x.Peligro.Nombre,
                ConsecuenciaId = x.ConsecuenciaId,
                ConsecuenciaNombre = x.Consecuencia.Nombre,
                DescripcionPeligro = x.DescripcionPeligro,
                EvaluacionInicialId = x.EvaluacionInicialId,
                EvaluacionResidualId = x.EvaluacionResidualId,
                ResponsableImplementacionId = x.ResponsableImplementacionId,
                FechaCompromiso = x.FechaCompromiso,
                FechaImplementacion = x.FechaImplementacion,
                EstadoImplementacionId = (int)x.EstadoImplementacion,
                EstadoImplementacionNombre = x.EstadoImplementacion.ToString()
            })
            .ToListAsync();
    }

    /// <summary>
    /// Registra un nuevo detalle dentro de una Matriz IPERC.
    /// </summary>
    public async Task<DetalleIPERCDto> CreateAsync(CreateDetalleIPERCDto dto)
    {
        var matriz = await _context.Set<MatrizIPERC>()
            .FirstOrDefaultAsync(x => x.Id == dto.MatrizIPERCId);

        if (matriz is null)
            throw new InvalidOperationException("La Matriz IPERC seleccionada no existe.");

        var peligro = await _context.Peligros
            .FirstOrDefaultAsync(x => x.Id == dto.PeligroId && x.Activo);

        if (peligro is null)
            throw new InvalidOperationException("El peligro seleccionado no existe o está inactivo.");

        var consecuencia = await _context.Consecuencias
            .FirstOrDefaultAsync(x => x.Id == dto.ConsecuenciaId && x.Activo);

        if (consecuencia is null)
            throw new InvalidOperationException("La consecuencia seleccionada no existe o está inactiva.");

        var evaluacionInicialExiste = await _context.Set<EvaluacionRiesgo>()
            .AnyAsync(x => x.Id == dto.EvaluacionInicialId);

        if (!evaluacionInicialExiste)
            throw new InvalidOperationException("La evaluación inicial seleccionada no existe.");

        if (dto.EvaluacionResidualId.HasValue)
        {
            var evaluacionResidualExiste = await _context.Set<EvaluacionRiesgo>()
                .AnyAsync(x => x.Id == dto.EvaluacionResidualId.Value);

            if (!evaluacionResidualExiste)
                throw new InvalidOperationException("La evaluación residual seleccionada no existe.");
        }

        if (dto.ResponsableImplementacionId.HasValue)
        {
            var responsableExiste = await _context.Set<Usuario>()
                .AnyAsync(x => x.Id == dto.ResponsableImplementacionId.Value);

            if (!responsableExiste)
                throw new InvalidOperationException("El responsable de implementación seleccionado no existe.");
        }

        var item = dto.Item;

        if (item <= 0)
        {
            var ultimoItem = await _context.Set<DetalleIPERC>()
                .Where(x => x.MatrizIPERCId == dto.MatrizIPERCId)
                .OrderByDescending(x => x.Item)
                .Select(x => x.Item)
                .FirstOrDefaultAsync();

            item = ultimoItem + 1;
        }

        var existeItem = await _context.Set<DetalleIPERC>()
            .AnyAsync(x =>
                x.MatrizIPERCId == dto.MatrizIPERCId &&
                x.Item == item);

        if (existeItem)
            throw new InvalidOperationException("Ya existe un detalle con ese número de item en la matriz seleccionada.");

        var detalle = new DetalleIPERC
        {
            MatrizIPERCId = dto.MatrizIPERCId,
            Item = item,
            Tarea = dto.Tarea.Trim(),
            PeligroId = dto.PeligroId,
            ConsecuenciaId = dto.ConsecuenciaId,
            DescripcionPeligro = dto.DescripcionPeligro?.Trim(),
            EvaluacionInicialId = dto.EvaluacionInicialId,
            EvaluacionResidualId = dto.EvaluacionResidualId,
            ResponsableImplementacionId = dto.ResponsableImplementacionId,
            FechaCompromiso = dto.FechaCompromiso,
            FechaImplementacion = dto.FechaImplementacion,
            EstadoImplementacion = (EstadoImplementacion)dto.EstadoImplementacion
        };

        _context.Set<DetalleIPERC>().Add(detalle);
        await _context.SaveChangesAsync();

        return new DetalleIPERCDto
        {
            Id = detalle.Id,
            MatrizIPERCId = detalle.MatrizIPERCId,
            MatrizIPERCCodigo = matriz.Codigo,
            Item = detalle.Item,
            Tarea = detalle.Tarea,
            PeligroId = detalle.PeligroId,
            PeligroNombre = peligro.Nombre,
            ConsecuenciaId = detalle.ConsecuenciaId,
            ConsecuenciaNombre = consecuencia.Nombre,
            DescripcionPeligro = detalle.DescripcionPeligro,
            EvaluacionInicialId = detalle.EvaluacionInicialId,
            EvaluacionResidualId = detalle.EvaluacionResidualId,
            ResponsableImplementacionId = detalle.ResponsableImplementacionId,
            FechaCompromiso = detalle.FechaCompromiso,
            FechaImplementacion = detalle.FechaImplementacion,
            EstadoImplementacionId = (int)detalle.EstadoImplementacion,
            EstadoImplementacionNombre = detalle.EstadoImplementacion.ToString()
        };
    }

    /// <summary>
    /// Actualiza un detalle IPERC existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateDetalleIPERCDto dto)
    {
        var detalle = await _context.Set<DetalleIPERC>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (detalle is null)
            return false;

        var matrizExiste = await _context.Set<MatrizIPERC>()
            .AnyAsync(x => x.Id == dto.MatrizIPERCId);

        if (!matrizExiste)
            throw new InvalidOperationException("La Matriz IPERC seleccionada no existe.");

        var peligroExiste = await _context.Peligros
            .AnyAsync(x => x.Id == dto.PeligroId && x.Activo);

        if (!peligroExiste)
            throw new InvalidOperationException("El peligro seleccionado no existe o está inactivo.");

        var consecuenciaExiste = await _context.Consecuencias
            .AnyAsync(x => x.Id == dto.ConsecuenciaId && x.Activo);

        if (!consecuenciaExiste)
            throw new InvalidOperationException("La consecuencia seleccionada no existe o está inactiva.");

        var evaluacionInicialExiste = await _context.Set<EvaluacionRiesgo>()
            .AnyAsync(x => x.Id == dto.EvaluacionInicialId);

        if (!evaluacionInicialExiste)
            throw new InvalidOperationException("La evaluación inicial seleccionada no existe.");

        if (dto.EvaluacionResidualId.HasValue)
        {
            var evaluacionResidualExiste = await _context.Set<EvaluacionRiesgo>()
                .AnyAsync(x => x.Id == dto.EvaluacionResidualId.Value);

            if (!evaluacionResidualExiste)
                throw new InvalidOperationException("La evaluación residual seleccionada no existe.");
        }

        if (dto.ResponsableImplementacionId.HasValue)
        {
            var responsableExiste = await _context.Set<Usuario>()
                .AnyAsync(x => x.Id == dto.ResponsableImplementacionId.Value);

            if (!responsableExiste)
                throw new InvalidOperationException("El responsable de implementación seleccionado no existe.");
        }

        var item = dto.Item <= 0 ? detalle.Item : dto.Item;

        var existeItem = await _context.Set<DetalleIPERC>()
            .AnyAsync(x =>
                x.Id != id &&
                x.MatrizIPERCId == dto.MatrizIPERCId &&
                x.Item == item);

        if (existeItem)
            throw new InvalidOperationException("Ya existe otro detalle con ese número de item en la matriz seleccionada.");

        detalle.MatrizIPERCId = dto.MatrizIPERCId;
        detalle.Item = item;
        detalle.Tarea = dto.Tarea.Trim();
        detalle.PeligroId = dto.PeligroId;
        detalle.ConsecuenciaId = dto.ConsecuenciaId;
        detalle.DescripcionPeligro = dto.DescripcionPeligro?.Trim();
        detalle.EvaluacionInicialId = dto.EvaluacionInicialId;
        detalle.EvaluacionResidualId = dto.EvaluacionResidualId;
        detalle.ResponsableImplementacionId = dto.ResponsableImplementacionId;
        detalle.FechaCompromiso = dto.FechaCompromiso;
        detalle.FechaImplementacion = dto.FechaImplementacion;
        detalle.EstadoImplementacion = (EstadoImplementacion)dto.EstadoImplementacion;
        detalle.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Cierra un detalle IPERC.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var detalle = await _context.Set<DetalleIPERC>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (detalle is null)
            return false;

        detalle.EstadoImplementacion = EstadoImplementacion.Cerrado;
        detalle.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
