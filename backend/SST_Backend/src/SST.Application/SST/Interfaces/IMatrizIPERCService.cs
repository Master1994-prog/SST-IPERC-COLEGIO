using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de Matriz IPERC.
/// </summary>
public interface IMatrizIPERCService
{
    Task<IEnumerable<MatrizIPERCDto>> GetAllAsync();

    Task<MatrizIPERCDto?> GetByIdAsync(long id);

    Task<MatrizIPERCDto> CreateAsync(CreateMatrizIPERCDto dto);

    Task<bool> UpdateAsync(long id, UpdateMatrizIPERCDto dto);

    Task<bool> DeleteAsync(long id);
}
