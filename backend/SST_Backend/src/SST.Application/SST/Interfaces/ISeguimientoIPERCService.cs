using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de seguimientos IPERC.
/// </summary>
public interface ISeguimientoIPERCService
{
    Task<IEnumerable<SeguimientoIPERCDto>> GetAllAsync();

    Task<SeguimientoIPERCDto?> GetByIdAsync(long id);

    Task<IEnumerable<SeguimientoIPERCDto>> GetByDetalleIdAsync(long detalleIPERCId);

    Task<SeguimientoIPERCDto> CreateAsync(CreateSeguimientoIPERCDto dto);

    Task<bool> UpdateAsync(long id, UpdateSeguimientoIPERCDto dto);

    Task<bool> DeleteAsync(long id);

    Task<bool> VerificarAsync(long id);
}
