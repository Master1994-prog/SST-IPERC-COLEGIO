using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de consecuencias.
/// Define las operaciones que debe implementar la capa de infraestructura.
/// </summary>
public interface IConsecuenciaService
{
    /// <summary>
    /// Obtiene todas las consecuencias activas.
    /// </summary>
    Task<IEnumerable<ConsecuenciaDto>> GetAllAsync();

    /// <summary>
    /// Obtiene una consecuencia por su Id.
    /// </summary>
    Task<ConsecuenciaDto?> GetByIdAsync(long id);

    /// <summary>
    /// Registra una nueva consecuencia.
    /// </summary>
    Task<ConsecuenciaDto> CreateAsync(CreateConsecuenciaDto dto);

    /// <summary>
    /// Actualiza una consecuencia existente.
    /// </summary>
    Task<bool> UpdateAsync(long id, UpdateConsecuenciaDto dto);

    /// <summary>
    /// Desactiva una consecuencia.
    /// </summary>
    Task<bool> DeleteAsync(long id);
}
