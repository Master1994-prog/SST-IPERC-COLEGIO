using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador de consulta del catálogo de probabilidades IPERC.
/// </summary>
[ApiController]
[Route("api/probabilidades")]
[Authorize]
public class ProbabilidadesController : ControllerBase
{
    private readonly SSTDbContext _context;

    public ProbabilidadesController(
        SSTDbContext context)
    {
        _context = context;
    }

    // ============================================================
    // GET ALL
    // ============================================================

    /// <summary>
    /// Obtiene todas las probabilidades registradas.
    /// Devuelve el Id REAL de la base de datos.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var probabilidades =
            await _context
                .Probabilidades
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

        return Ok(probabilidades);
    }

    // ============================================================
    // GET BY ID
    // ============================================================

    /// <summary>
    /// Obtiene una probabilidad por su Id real.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(
        long id)
    {
        var probabilidad =
            await _context
                .Probabilidades
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

        if (probabilidad is null)
        {
            return NotFound(new
            {
                mensaje =
                    "Probabilidad no encontrada."
            });
        }

        return Ok(probabilidad);
    }
}