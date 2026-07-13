using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de tipos de peligro.
/// Define las operaciones que debe implementar la capa de infraestructura.
/// </summary>
public interface ITipoPeligroService
{
    /// <summary>
    /// Obtiene todos los tipos de peligro activos.
    /// </summary>
    Task<IEnumerable<TipoPeligroDto>> GetAllAsync();

    /// <summary>
    /// Obtiene un tipo de peligro por su Id.
    /// </summary>
    Task<TipoPeligroDto?> GetByIdAsync(long id);

    /// <summary>
    /// Registra un nuevo tipo de peligro.
    /// </summary>
    Task<TipoPeligroDto> CreateAsync(CreateTipoPeligroDto dto);

    /// <summary>
    /// Actualiza un tipo de peligro existente.
    /// </summary>
    Task<bool> UpdateAsync(long id, UpdateTipoPeligroDto dto);

    /// <summary>
    /// Desactiva un tipo de peligro.
    /// </summary>
    Task<bool> DeleteAsync(long id);
}
