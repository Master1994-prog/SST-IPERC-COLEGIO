using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador encargado de administrar las clasificaciones
/// pertenecientes a la jerarquía de controles SST.
/// </summary>
[ApiController]
[Route("api/clasificaciones-control")]
[Produces("application/json")]
[Authorize]
public class ClasificacionesControlController : ControllerBase
{
    private readonly IClasificacionControlService
        _clasificacionControlService;

    public ClasificacionesControlController(
        IClasificacionControlService clasificacionControlService)
    {
        _clasificacionControlService =
            clasificacionControlService;
    }

    // =========================================================
    // GET: api/clasificaciones-control
    // Cualquier usuario autenticado
    // =========================================================

    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ObtenerTodos(
        CancellationToken cancellationToken)
    {
        try
        {
            var clasificaciones =
                await _clasificacionControlService
                    .ObtenerTodosAsync(
                        cancellationToken);

            return Ok(clasificaciones);
        }
        catch (Exception ex)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    mensaje =
                        "Ocurrió un error al obtener las clasificaciones de control.",
                    detalle = ex.Message
                });
        }
    }

    // =========================================================
    // GET: api/clasificaciones-control/activos
    // Cualquier usuario autenticado
    // =========================================================

    [HttpGet("activos")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ObtenerActivos(
        CancellationToken cancellationToken)
    {
        try
        {
            var clasificaciones =
                await _clasificacionControlService
                    .ObtenerActivosAsync(
                        cancellationToken);

            return Ok(clasificaciones);
        }
        catch (Exception ex)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    mensaje =
                        "Ocurrió un error al obtener las clasificaciones activas.",
                    detalle = ex.Message
                });
        }
    }

    // =========================================================
    // GET: api/clasificaciones-control/{id}
    // Cualquier usuario autenticado
    // =========================================================

    [HttpGet("{id:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "El identificador de la clasificación no es válido."
                });
        }

        try
        {
            var clasificacion =
                await _clasificacionControlService
                    .ObtenerPorIdAsync(
                        id,
                        cancellationToken);

            if (clasificacion is null)
            {
                return NotFound(
                    new
                    {
                        mensaje =
                            "No se encontró la clasificación de control."
                    });
            }

            return Ok(clasificacion);
        }
        catch (Exception ex)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    mensaje =
                        "Ocurrió un error al obtener la clasificación de control.",
                    detalle = ex.Message
                });
        }
    }

    // =========================================================
    // POST
    // SUPER_ADMIN, ADMIN y COORDINADOR
    // =========================================================

    [HttpPost]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    [ProducesResponseType(
        StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Crear(
        [FromBody] CreateClasificacionControlDto dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        try
        {
            var clasificacionCreada =
                await _clasificacionControlService
                    .CrearAsync(
                        dto,
                        cancellationToken);

            return CreatedAtAction(
                nameof(ObtenerPorId),
                new
                {
                    id = clasificacionCreada.Id
                },
                clasificacionCreada);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(
                new
                {
                    mensaje = ex.Message
                });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(
                new
                {
                    mensaje = ex.Message
                });
        }
        catch (Exception ex)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    mensaje =
                        "Ocurrió un error al registrar la clasificación de control.",
                    detalle = ex.Message
                });
        }
    }

    // =========================================================
    // PUT
    // SUPER_ADMIN, ADMIN y COORDINADOR
    // =========================================================

    [HttpPut("{id:long}")]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    [ProducesResponseType(
        StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] UpdateClasificacionControlDto dto,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "El identificador de la clasificación no es válido."
                });
        }

        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        try
        {
            var actualizado =
                await _clasificacionControlService
                    .ActualizarAsync(
                        id,
                        dto,
                        cancellationToken);

            if (!actualizado)
            {
                return NotFound(
                    new
                    {
                        mensaje =
                            "No se encontró la clasificación de control."
                    });
            }

            return Ok(
                new
                {
                    mensaje =
                        "Clasificación de control actualizada correctamente."
                });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(
                new
                {
                    mensaje = ex.Message
                });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(
                new
                {
                    mensaje = ex.Message
                });
        }
        catch (Exception ex)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    mensaje =
                        "Ocurrió un error al actualizar la clasificación de control.",
                    detalle = ex.Message
                });
        }
    }

    // =========================================================
    // DELETE
    // Solo SUPER_ADMIN
    // =========================================================

    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    [ProducesResponseType(
        StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Eliminar(
        long id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "El identificador de la clasificación no es válido."
                });
        }

        try
        {
            var eliminado =
                await _clasificacionControlService
                    .EliminarAsync(
                        id,
                        cancellationToken);

            if (!eliminado)
            {
                return NotFound(
                    new
                    {
                        mensaje =
                            "No se encontró la clasificación de control."
                    });
            }

            return Ok(
                new
                {
                    mensaje =
                        "Clasificación de control eliminada o desactivada correctamente."
                });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(
                new
                {
                    mensaje = ex.Message
                });
        }
        catch (Exception ex)
        {
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                new
                {
                    mensaje =
                        "Ocurrió un error al eliminar la clasificación de control.",
                    detalle = ex.Message
                });
        }
    }
}
