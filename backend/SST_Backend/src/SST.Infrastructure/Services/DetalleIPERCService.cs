using System.Linq.Expressions;
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

    /// <summary>
    /// Proyección reutilizable que devuelve un detalle IPERC
    /// junto con sus evaluaciones inicial y residual.
    /// </summary>
    private static readonly Expression<Func<DetalleIPERC, DetalleIPERCDto>>
        ProyectarDetalle = x => new DetalleIPERCDto
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
            EvaluacionInicial = new EvaluacionDetalleIPERCDto
            {
                Id = x.EvaluacionInicial.Id,
                ProbabilidadId = x.EvaluacionInicial.ProbabilidadId,
                ProbabilidadNombre =
                    x.EvaluacionInicial.Probabilidad.Nombre,
                ValorProbabilidad =
                    x.EvaluacionInicial.Probabilidad.Valor,
                SeveridadId = x.EvaluacionInicial.SeveridadId,
                SeveridadNombre =
                    x.EvaluacionInicial.Severidad.Nombre,
                ValorSeveridad =
                    x.EvaluacionInicial.Severidad.Valor,
                NivelRiesgoId = x.EvaluacionInicial.NivelRiesgoId,
                NivelRiesgoNombre =
                    x.EvaluacionInicial.NivelRiesgo.Nombre,
                Color = x.EvaluacionInicial.NivelRiesgo.Color,
                ValorRiesgo = x.EvaluacionInicial.Valor,
                EsAceptable = x.EvaluacionInicial.EsAceptable,
                RequiereAccion =
                    x.EvaluacionInicial.RequiereAccion,
                Observaciones =
                    x.EvaluacionInicial.Observaciones
            },

            EvaluacionResidualId = x.EvaluacionResidualId,
            EvaluacionResidual = x.EvaluacionResidual == null
                ? null
                : new EvaluacionDetalleIPERCDto
                {
                    Id = x.EvaluacionResidual.Id,
                    ProbabilidadId =
                        x.EvaluacionResidual.ProbabilidadId,
                    ProbabilidadNombre =
                        x.EvaluacionResidual.Probabilidad.Nombre,
                    ValorProbabilidad =
                        x.EvaluacionResidual.Probabilidad.Valor,
                    SeveridadId =
                        x.EvaluacionResidual.SeveridadId,
                    SeveridadNombre =
                        x.EvaluacionResidual.Severidad.Nombre,
                    ValorSeveridad =
                        x.EvaluacionResidual.Severidad.Valor,
                    NivelRiesgoId =
                        x.EvaluacionResidual.NivelRiesgoId,
                    NivelRiesgoNombre =
                        x.EvaluacionResidual.NivelRiesgo.Nombre,
                    Color =
                        x.EvaluacionResidual.NivelRiesgo.Color,
                    ValorRiesgo =
                        x.EvaluacionResidual.Valor,
                    EsAceptable =
                        x.EvaluacionResidual.EsAceptable,
                    RequiereAccion =
                        x.EvaluacionResidual.RequiereAccion,
                    Observaciones =
                        x.EvaluacionResidual.Observaciones
                },

            ControlIds = x.Controles
                .Select(c => c.ControlId)
                .ToList(),

            EquipoProteccionIds = x.EquiposProteccion
                .Select(e => e.EquipoProteccionId)
                .ToList(),

            ResponsableImplementacionId =
                x.ResponsableImplementacionId,
            FechaCompromiso = x.FechaCompromiso,
            FechaImplementacion = x.FechaImplementacion,
            EstadoImplementacionId =
                (int)x.EstadoImplementacion,
            EstadoImplementacionNombre =
                x.EstadoImplementacion.ToString()
        };

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
            .OrderBy(x => x.MatrizIPERCId)
            .ThenBy(x => x.Item)
            .Select(ProyectarDetalle)
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un detalle IPERC por su identificador.
    /// </summary>
    public async Task<DetalleIPERCDto?> GetByIdAsync(long id)
    {
        return await _context.Set<DetalleIPERC>()
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(ProyectarDetalle)
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Obtiene los detalles asociados a una Matriz IPERC.
    /// </summary>
    public async Task<IEnumerable<DetalleIPERCDto>> GetByMatrizIdAsync(
        long matrizIPERCId)
    {
        return await _context.Set<DetalleIPERC>()
            .AsNoTracking()
            .Where(x => x.MatrizIPERCId == matrizIPERCId)
            .OrderBy(x => x.Item)
            .Select(ProyectarDetalle)
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

        var controlIds = NormalizarIds(dto.ControlIds);
        var equipoProteccionIds = NormalizarIds(dto.EquipoProteccionIds);

        await ValidarControlesAsync(controlIds);
        await ValidarEquiposProteccionAsync(equipoProteccionIds);

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
            EstadoImplementacion = (EstadoImplementacion)dto.EstadoImplementacion,
            Controles = controlIds
                .Select(controlId => new DetalleIPERCControl
                {
                    ControlId = controlId
                })
                .ToList(),
            EquiposProteccion = equipoProteccionIds
                .Select(equipoProteccionId => new DetalleIPERCEPP
                {
                    EquipoProteccionId = equipoProteccionId
                })
                .ToList()
        };

        _context.Set<DetalleIPERC>().Add(detalle);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(detalle.Id)
            ?? throw new InvalidOperationException(
                "No se pudo recuperar el detalle IPERC registrado.");
    }

    /// <summary>
    /// Actualiza un detalle IPERC existente.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateDetalleIPERCDto dto)
    {
        var detalle = await _context.Set<DetalleIPERC>()
            .Include(x => x.Controles)
            .Include(x => x.EquiposProteccion)
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

        var controlIds = NormalizarIds(dto.ControlIds);
        var equipoProteccionIds = NormalizarIds(dto.EquipoProteccionIds);

        await ValidarControlesAsync(controlIds);
        await ValidarEquiposProteccionAsync(equipoProteccionIds);

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

        SincronizarControles(detalle, controlIds);
        SincronizarEquiposProteccion(detalle, equipoProteccionIds);

        await _context.SaveChangesAsync();

        return true;
    }

    private static List<long> NormalizarIds(IEnumerable<long>? ids)
    {
        return ids?
            .Where(id => id > 0)
            .Distinct()
            .ToList() ?? new List<long>();
    }

    private async Task ValidarControlesAsync(List<long> controlIds)
    {
        if (controlIds.Count == 0)
            return;

        var controlesExistentes = await _context.Controles
            .CountAsync(x => controlIds.Contains(x.Id) && x.Activo);

        if (controlesExistentes != controlIds.Count)
            throw new InvalidOperationException("Uno o más controles seleccionados no existen o están inactivos.");
    }

    private async Task ValidarEquiposProteccionAsync(List<long> equipoProteccionIds)
    {
        if (equipoProteccionIds.Count == 0)
            return;

        var equiposExistentes = await _context.EquiposProteccion
            .CountAsync(x => equipoProteccionIds.Contains(x.Id) && x.Activo);

        if (equiposExistentes != equipoProteccionIds.Count)
            throw new InvalidOperationException("Uno o más equipos de protección seleccionados no existen o están inactivos.");
    }

    private void SincronizarControles(DetalleIPERC detalle, List<long> controlIds)
    {
        var actuales = detalle.Controles.ToList();
        var eliminar = actuales
            .Where(x => !controlIds.Contains(x.ControlId))
            .ToList();

        if (eliminar.Count > 0)
            _context.Set<DetalleIPERCControl>().RemoveRange(eliminar);

        var actualesIds = actuales
            .Select(x => x.ControlId)
            .ToHashSet();

        foreach (var controlId in controlIds.Where(id => !actualesIds.Contains(id)))
        {
            detalle.Controles.Add(new DetalleIPERCControl
            {
                DetalleIPERCId = detalle.Id,
                ControlId = controlId
            });
        }
    }

    private void SincronizarEquiposProteccion(DetalleIPERC detalle, List<long> equipoProteccionIds)
    {
        var actuales = detalle.EquiposProteccion.ToList();
        var eliminar = actuales
            .Where(x => !equipoProteccionIds.Contains(x.EquipoProteccionId))
            .ToList();

        if (eliminar.Count > 0)
            _context.Set<DetalleIPERCEPP>().RemoveRange(eliminar);

        var actualesIds = actuales
            .Select(x => x.EquipoProteccionId)
            .ToHashSet();

        foreach (var equipoProteccionId in equipoProteccionIds.Where(id => !actualesIds.Contains(id)))
        {
            detalle.EquiposProteccion.Add(new DetalleIPERCEPP
            {
                DetalleIPERCId = detalle.Id,
                EquipoProteccionId = equipoProteccionId
            });
        }
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
