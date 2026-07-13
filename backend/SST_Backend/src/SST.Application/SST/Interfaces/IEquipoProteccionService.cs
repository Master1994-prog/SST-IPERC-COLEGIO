using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de Equipos de Protección Personal.
/// Define las operaciones que usará el controlador.
/// </summary>
public interface IEquipoProteccionService
{
    /// <summary>
    /// Obtiene todos los equipos de protección activos.
    /// </summary>
    Task<IEnumerable<EquipoProteccionDto>> GetAllAsync();

    /// <summary>
    /// Obtiene un equipo de protección por su Id.
    /// </summary>
    Task<EquipoProteccionDto?> GetByIdAsync(long id);

    /// <summary>
    /// Registra un nuevo equipo de protección.
    /// </summary>
    Task<EquipoProteccionDto> CreateAsync(CreateEquipoProteccionDto dto);

    /// <summary>
    /// Actualiza un equipo de protección existente.
    /// </summary>
    Task<bool> UpdateAsync(long id, UpdateEquipoProteccionDto dto);

    /// <summary>
    /// Desactiva un equipo de protección.
    /// </summary>
    Task<bool> DeleteAsync(long id);
}
