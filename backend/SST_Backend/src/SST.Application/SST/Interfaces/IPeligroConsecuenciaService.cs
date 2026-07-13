using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de relación peligro-consecuencia.
/// Define las operaciones que usará el controlador.
/// </summary>
public interface IPeligroConsecuenciaService
{
    /// <summary>
    /// Obtiene todas las relaciones activas entre peligros y consecuencias.
    /// </summary>
    Task<IEnumerable<PeligroConsecuenciaDto>> GetAllAsync();

    /// <summary>
    /// Obtiene una relación peligro-consecuencia por su Id.
    /// </summary>
    Task<PeligroConsecuenciaDto?> GetByIdAsync(long id);

    /// <summary>
    /// Obtiene las consecuencias asociadas a un peligro específico.
    /// </summary>
    Task<IEnumerable<PeligroConsecuenciaDto>> GetByPeligroIdAsync(long peligroId);

    /// <summary>
    /// Registra una nueva relación peligro-consecuencia.
    /// </summary>
    Task<PeligroConsecuenciaDto> CreateAsync(CreatePeligroConsecuenciaDto dto);

    /// <summary>
    /// Actualiza una relación peligro-consecuencia existente.
    /// </summary>
    Task<bool> UpdateAsync(long id, UpdatePeligroConsecuenciaDto dto);

    /// <summary>
    /// Desactiva una relación peligro-consecuencia.
    /// </summary>
    Task<bool> DeleteAsync(long id);
}
