using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

public interface ICategoriaPeligroService
{
    Task<List<CategoriaPeligroDto>> GetAllAsync();

    Task<CategoriaPeligroDto?> GetByIdAsync(long id);

    Task<CategoriaPeligroDto> CreateAsync(CreateCategoriaPeligroDto dto);

    Task<bool> UpdateAsync(long id, UpdateCategoriaPeligroDto dto);

    Task<bool> DeleteAsync(long id);
}
