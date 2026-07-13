using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de mapas de riesgo.
/// </summary>
public interface IMapaRiesgoService
{
    Task<IEnumerable<MapaRiesgoDto>> GetAllAsync();

    Task<MapaRiesgoDto?> GetByIdAsync(long id);

    Task<IEnumerable<MapaRiesgoDto>> GetByMatrizIdAsync(long matrizIPERCId);

    Task<MapaRiesgoDto> CreateAsync(CreateMapaRiesgoDto dto);

    Task<bool> UpdateAsync(long id, UpdateMapaRiesgoDto dto);

    Task<bool> DeleteAsync(long id);
}
