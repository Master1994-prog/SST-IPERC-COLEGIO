using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AreasController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public AreasController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        [FromQuery] long? institucionId,
        CancellationToken cancellationToken)
    {
        var consulta = _dbContext.Areas
            .AsNoTracking()
            .Where(x => x.Estado);

        if (institucionId.HasValue)
        {
            consulta = consulta.Where(
                x => x.InstitucionId == institucionId.Value);
        }

        var areas = await consulta
            .OrderBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre
            })
            .ToListAsync(cancellationToken);

        return Ok(areas);
    }
}
