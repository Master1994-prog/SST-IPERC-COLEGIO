using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class PuestosTrabajoController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public PuestosTrabajoController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene los puestos de trabajo activos.
    /// Puede filtrar por área.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodos(
        [FromQuery] long? areaId,
        CancellationToken cancellationToken)
    {
        var consulta = _dbContext.PuestosTrabajo
            .AsNoTracking()
            .Where(x => x.Estado && x.Activo);

        if (areaId.HasValue && areaId.Value > 0)
        {
            consulta = consulta.Where(
                x => x.AreaId == areaId.Value);
        }

        var puestos = await consulta
            .OrderBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre
            })
            .ToListAsync(cancellationToken);

        return Ok(puestos);
    }
}
