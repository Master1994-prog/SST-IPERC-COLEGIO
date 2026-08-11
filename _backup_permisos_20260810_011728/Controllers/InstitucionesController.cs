using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class InstitucionesController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public InstitucionesController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        CancellationToken cancellationToken)
    {
        var instituciones = await _dbContext.Instituciones
            .AsNoTracking()
            .Where(x => x.Estado)
            .OrderBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre
            })
            .ToListAsync(cancellationToken);

        return Ok(instituciones);
    }
}
