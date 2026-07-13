using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de evaluación de riesgo.
/// </summary>
public interface IEvaluacionRiesgoService
{
    Task<IEnumerable<EvaluacionRiesgoDto>> GetAllAsync();

    Task<EvaluacionRiesgoDto?> GetByIdAsync(long id);

    Task<EvaluacionRiesgoDto> CreateAsync(CreateEvaluacionRiesgoDto dto);

    Task<bool> UpdateAsync(long id, UpdateEvaluacionRiesgoDto dto);

    Task<bool> DeleteAsync(long id);
}
