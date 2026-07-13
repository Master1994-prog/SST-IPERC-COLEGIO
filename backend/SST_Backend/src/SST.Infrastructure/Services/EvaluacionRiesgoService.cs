using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.IPERC.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar evaluaciones de riesgo.
/// Calcula el valor del riesgo usando Probabilidad x Severidad.
/// </summary>
public class EvaluacionRiesgoService : IEvaluacionRiesgoService
{
    private readonly SSTDbContext _context;

    public EvaluacionRiesgoService(SSTDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<EvaluacionRiesgoDto>> GetAllAsync()
    {
        return await _context.Set<EvaluacionRiesgo>()
            .AsNoTracking()
            .Select(x => new EvaluacionRiesgoDto
            {
                Id = x.Id,
                ProbabilidadId = x.ProbabilidadId,
                SeveridadId = x.SeveridadId,
                NivelRiesgoId = x.NivelRiesgoId,
                Valor = x.Valor,
                EsAceptable = x.EsAceptable,
                RequiereAccion = x.RequiereAccion,
                Observaciones = x.Observaciones
            })
            .ToListAsync();
    }

    public async Task<EvaluacionRiesgoDto?> GetByIdAsync(long id)
    {
        return await _context.Set<EvaluacionRiesgo>()
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new EvaluacionRiesgoDto
            {
                Id = x.Id,
                ProbabilidadId = x.ProbabilidadId,
                SeveridadId = x.SeveridadId,
                NivelRiesgoId = x.NivelRiesgoId,
                Valor = x.Valor,
                EsAceptable = x.EsAceptable,
                RequiereAccion = x.RequiereAccion,
                Observaciones = x.Observaciones
            })
            .FirstOrDefaultAsync();
    }

    public async Task<EvaluacionRiesgoDto> CreateAsync(CreateEvaluacionRiesgoDto dto)
    {
        var probabilidad = await _context.Set<Probabilidad>()
            .FirstOrDefaultAsync(x => x.Id == dto.ProbabilidadId);

        if (probabilidad is null)
            throw new InvalidOperationException("La probabilidad seleccionada no existe.");

        var severidad = await _context.Set<Severidad>()
            .FirstOrDefaultAsync(x => x.Id == dto.SeveridadId);

        if (severidad is null)
            throw new InvalidOperationException("La severidad seleccionada no existe.");

        var nivelRiesgo = await _context.Set<NivelRiesgo>()
            .FirstOrDefaultAsync(x => x.Id == dto.NivelRiesgoId);

        if (nivelRiesgo is null)
            throw new InvalidOperationException("El nivel de riesgo seleccionado no existe.");

        var evaluacion = new EvaluacionRiesgo
        {
            ProbabilidadId = dto.ProbabilidadId,
            SeveridadId = dto.SeveridadId,
            NivelRiesgoId = dto.NivelRiesgoId,
            Observaciones = dto.Observaciones?.Trim(),

            // Se asignan las navegaciones para que el método Calcular() pueda usar Valor y Aceptable.
            Probabilidad = probabilidad,
            Severidad = severidad,
            NivelRiesgo = nivelRiesgo
        };

        evaluacion.Calcular();

        _context.Set<EvaluacionRiesgo>().Add(evaluacion);
        await _context.SaveChangesAsync();

        return new EvaluacionRiesgoDto
        {
            Id = evaluacion.Id,
            ProbabilidadId = evaluacion.ProbabilidadId,
            SeveridadId = evaluacion.SeveridadId,
            NivelRiesgoId = evaluacion.NivelRiesgoId,
            Valor = evaluacion.Valor,
            EsAceptable = evaluacion.EsAceptable,
            RequiereAccion = evaluacion.RequiereAccion,
            Observaciones = evaluacion.Observaciones
        };
    }

    public async Task<bool> UpdateAsync(long id, UpdateEvaluacionRiesgoDto dto)
    {
        var evaluacion = await _context.Set<EvaluacionRiesgo>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (evaluacion is null)
            return false;

        var probabilidad = await _context.Set<Probabilidad>()
            .FirstOrDefaultAsync(x => x.Id == dto.ProbabilidadId);

        if (probabilidad is null)
            throw new InvalidOperationException("La probabilidad seleccionada no existe.");

        var severidad = await _context.Set<Severidad>()
            .FirstOrDefaultAsync(x => x.Id == dto.SeveridadId);

        if (severidad is null)
            throw new InvalidOperationException("La severidad seleccionada no existe.");

        var nivelRiesgo = await _context.Set<NivelRiesgo>()
            .FirstOrDefaultAsync(x => x.Id == dto.NivelRiesgoId);

        if (nivelRiesgo is null)
            throw new InvalidOperationException("El nivel de riesgo seleccionado no existe.");

        evaluacion.ProbabilidadId = dto.ProbabilidadId;
        evaluacion.SeveridadId = dto.SeveridadId;
        evaluacion.NivelRiesgoId = dto.NivelRiesgoId;
        evaluacion.Observaciones = dto.Observaciones?.Trim();
        evaluacion.Probabilidad = probabilidad;
        evaluacion.Severidad = severidad;
        evaluacion.NivelRiesgo = nivelRiesgo;
        evaluacion.FechaActualizacion = DateTime.UtcNow;

        evaluacion.Calcular();

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(long id)
    {
        var evaluacion = await _context.Set<EvaluacionRiesgo>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (evaluacion is null)
            return false;

        _context.Set<EvaluacionRiesgo>().Remove(evaluacion);
        await _context.SaveChangesAsync();

        return true;
    }
}
