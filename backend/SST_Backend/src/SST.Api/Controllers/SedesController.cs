using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class SedesController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public SedesController(
        SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene las sedes activas.
    /// Puede filtrarse por institución.
    ///
    /// IMPORTANTE:
    /// Se devuelve InstitucionId porque Flutter lo necesita
    /// para el dropdown dependiente Institución -> Sede.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        [FromQuery] long? institucionId,
        CancellationToken cancellationToken)
    {
        var consulta =
            _dbContext.Sedes
                .AsNoTracking()
                .Where(x =>
                    x.Estado &&
                    x.Activo);

        if (institucionId.HasValue &&
            institucionId.Value > 0)
        {
            consulta = consulta.Where(
                x =>
                    x.InstitucionId ==
                    institucionId.Value);
        }

        var sedes =
            await consulta
                .OrderBy(x => x.Nombre)
                .Select(x => new
                {
                    x.Id,
                    x.Nombre,
                    x.Direccion,
                    x.InstitucionId,
                    x.Activo
                })
                .ToListAsync(
                    cancellationToken);

        return Ok(sedes);
    }
}
