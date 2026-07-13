using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de Detalle IPERC.
/// </summary>
public interface IDetalleIPERCService
{
    Task<IEnumerable<DetalleIPERCDto>> GetAllAsync();

    Task<DetalleIPERCDto?> GetByIdAsync(long id);

    Task<IEnumerable<DetalleIPERCDto>> GetByMatrizIdAsync(long matrizIPERCId);

    Task<DetalleIPERCDto> CreateAsync(CreateDetalleIPERCDto dto);

    Task<bool> UpdateAsync(long id, UpdateDetalleIPERCDto dto);

    Task<bool> DeleteAsync(long id);
}
