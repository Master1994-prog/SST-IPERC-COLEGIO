using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ActividadesController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public ActividadesController(
        SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        CancellationToken cancellationToken)
    {
        var actividades =
            await _dbContext.Actividades
                .AsNoTracking()
                .Where(x => x.Estado)
                .OrderBy(x => x.Nombre)
                .Select(x => new
                {
                    x.Id,
                    x.Nombre
                })
                .ToListAsync(cancellationToken);

        return Ok(actividades);
    }
}
