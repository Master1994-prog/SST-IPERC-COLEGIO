using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador de consulta del catálogo de severidades IPERC.
/// </summary>
[ApiController]
[Route("api/severidades")]
[Authorize]
public class SeveridadesController : ControllerBase
{
    private readonly SSTDbContext _context;

    public SeveridadesController(
        SSTDbContext context)
    {
        _context = context;
    }

    // ============================================================
    // GET ALL
    // ============================================================

    /// <summary>
    /// Obtiene todas las severidades registradas.
    /// Devuelve el Id REAL de la base de datos.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var severidades =
            await _context
                .Severidades
                .AsNoTracking()
                .OrderBy(x => x.Valor)
                .Select(x => new
                {
                    id = x.Id,
                    valor = x.Valor,
                    nombre = x.Nombre,
                    descripcion = x.Descripcion
                })
                .ToListAsync();

        return Ok(severidades);
    }

    // ============================================================
    // GET BY ID
    // ============================================================

    /// <summary>
    /// Obtiene una severidad por su Id real.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(
        long id)
    {
        var severidad =
            await _context
                .Severidades
                .AsNoTracking()
                .Where(x => x.Id == id)
                .Select(x => new
                {
                    id = x.Id,
                    valor = x.Valor,
                    nombre = x.Nombre,
                    descripcion = x.Descripcion
                })
                .FirstOrDefaultAsync();

        if (severidad is null)
        {
            return NotFound(new
            {
                mensaje =
                    "Severidad no encontrada."
            });
        }

        return Ok(severidad);
    }
}
