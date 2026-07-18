using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class SedesController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public SedesController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene las sedes activas. Permite filtrar por institución.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        [FromQuery] long? institucionId,
        CancellationToken cancellationToken)
    {
        var consulta = _dbContext.Sedes
            .AsNoTracking()
            .Where(x => x.Estado);

        if (institucionId.HasValue &&
            institucionId.Value > 0)
        {
            consulta = consulta.Where(
                x => x.InstitucionId == institucionId.Value);
        }

        var sedes = await consulta
            .OrderBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre
            })
            .ToListAsync(cancellationToken);

        return Ok(sedes);
    }
}