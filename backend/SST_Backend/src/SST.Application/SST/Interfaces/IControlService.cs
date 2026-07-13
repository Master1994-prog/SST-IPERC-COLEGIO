using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de controles.
/// Define las operaciones que debe implementar la capa de infraestructura.
/// </summary>
public interface IControlService
{
    /// <summary>
    /// Obtiene todos los controles activos.
    /// </summary>
    Task<IEnumerable<ControlDto>> GetAllAsync();

    /// <summary>
    /// Obtiene un control por su Id.
    /// </summary>
    Task<ControlDto?> GetByIdAsync(long id);

    /// <summary>
    /// Registra un nuevo control.
    /// </summary>
    Task<ControlDto> CreateAsync(CreateControlDto dto);

    /// <summary>
    /// Actualiza un control existente.
    /// </summary>
    Task<bool> UpdateAsync(long id, UpdateControlDto dto);

    /// <summary>
    /// Desactiva un control.
    /// </summary>
    Task<bool> DeleteAsync(long id);
}
