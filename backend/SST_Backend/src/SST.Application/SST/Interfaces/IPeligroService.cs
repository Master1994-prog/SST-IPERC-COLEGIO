using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de peligros.
/// Define las operaciones que usará el controlador.
/// </summary>
public interface IPeligroService
{
    /// <summary>
    /// Obtiene todos los peligros activos.
    /// </summary>
    Task<IEnumerable<PeligroDto>> GetAllAsync();

    /// <summary>
    /// Obtiene un peligro por su Id.
    /// </summary>
    Task<PeligroDto?> GetByIdAsync(long id);

    /// <summary>
    /// Registra un nuevo peligro.
    /// </summary>
    Task<PeligroDto> CreateAsync(CreatePeligroDto dto);

    /// <summary>
    /// Actualiza un peligro existente.
    /// </summary>
    Task<bool> UpdateAsync(long id, UpdatePeligroDto dto);

    /// <summary>
    /// Desactiva un peligro.
    /// </summary>
    Task<bool> DeleteAsync(long id);
}
