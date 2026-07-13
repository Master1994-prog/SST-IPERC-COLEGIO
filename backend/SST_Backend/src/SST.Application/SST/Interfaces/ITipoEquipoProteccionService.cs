using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de tipos de Equipo de Protección Personal.
/// </summary>
public interface ITipoEquipoProteccionService
{
    Task<IEnumerable<TipoEquipoProteccionDto>> GetAllAsync();

    Task<TipoEquipoProteccionDto?> GetByIdAsync(long id);

    Task<TipoEquipoProteccionDto> CreateAsync(CreateTipoEquipoProteccionDto dto);

    Task<bool> UpdateAsync(long id, UpdateTipoEquipoProteccionDto dto);

    Task<bool> DeleteAsync(long id);
}
