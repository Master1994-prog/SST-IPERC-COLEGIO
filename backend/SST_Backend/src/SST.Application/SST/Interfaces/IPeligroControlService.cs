using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de relación peligro-control.
/// </summary>
public interface IPeligroControlService
{
    Task<IEnumerable<PeligroControlDto>> GetAllAsync();

    Task<PeligroControlDto?> GetByIdAsync(long id);

    Task<IEnumerable<PeligroControlDto>> GetByPeligroIdAsync(long peligroId);

    Task<PeligroControlDto> CreateAsync(CreatePeligroControlDto dto);

    Task<bool> UpdateAsync(long id, UpdatePeligroControlDto dto);

    Task<bool> DeleteAsync(long id);
}
