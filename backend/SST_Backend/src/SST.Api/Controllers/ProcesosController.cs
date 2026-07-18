using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ProcesosController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public ProcesosController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene los procesos registrados.
    /// Puede filtrar por área cuando la entidad Proceso tiene AreaId.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodos(
        [FromQuery] long? areaId,
        CancellationToken cancellationToken)
    {
        var consulta = _dbContext.Procesos
            .AsNoTracking()
            .Where(x => x.Estado);

        if (areaId.HasValue)
        {
            consulta = consulta.Where(
                x => x.AreaId == areaId.Value);
        }

        var procesos = await consulta
            .OrderBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre
            })
            .ToListAsync(cancellationToken);

        return Ok(procesos);
    }
}
