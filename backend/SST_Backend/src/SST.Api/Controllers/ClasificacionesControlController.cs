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
public class ClasificacionesControlController : ControllerBase
{
    private readonly IClasificacionControlService
        _clasificacionControlService;

    /// <summary>
    /// Constructor del controlador.
    /// </summary>
    /// <param name="clasificacionControlService">
    /// Servicio de clasificaciones de control.
    /// </param>
    public ClasificacionesControlController(
        IClasificacionControlService clasificacionControlService
    )
    {
        _clasificacionControlService =
            clasificacionControlService;
    }

    /// <summary>
    /// Obtiene todas las clasificaciones de control.
    /// </summary>
    /// <returns>
    /// Lista de clasificaciones registradas.
    /// </returns>
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ObtenerTodos(
        CancellationToken cancellationToken
    )
    {
        try
        {
            var clasificaciones =
                await _clasificacionControlService
                    .ObtenerTodosAsync(cancellationToken);

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
                }
            );
        }
    }

    /// <summary>
    /// Obtiene solamente las clasificaciones activas.
    /// </summary>
    /// <returns>
    /// Lista de clasificaciones activas.
    /// </returns>
    [HttpGet("activos")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ObtenerActivos(
        CancellationToken cancellationToken
    )
    {
        try
        {
            var clasificaciones =
                await _clasificacionControlService
                    .ObtenerActivosAsync(cancellationToken);

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
                }
            );
        }
    }

    /// <summary>
    /// Obtiene una clasificación mediante su identificador.
    /// </summary>
    /// <param name="id">
    /// Identificador de la clasificación.
    /// </param>
    /// <returns>
    /// Clasificación encontrada.
    /// </returns>
    [HttpGet("{id:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken
    )
    {
        if (id <= 0)
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "El identificador de la clasificación no es válido."
                }
            );
        }

        try
        {
            var clasificacion =
                await _clasificacionControlService
                    .ObtenerPorIdAsync(
                        id,
                        cancellationToken
                    );

            if (clasificacion is null)
            {
                return NotFound(
                    new
                    {
                        mensaje =
                            "No se encontró la clasificación de control."
                    }
                );
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
                }
            );
        }
    }

    /// <summary>
    /// Registra una nueva clasificación de control.
    /// </summary>
    /// <param name="dto">
    /// Información de la nueva clasificación.
    /// </param>
    /// <returns>
    /// Clasificación registrada.
    /// </returns>
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Crear(
        [FromBody] CreateClasificacionControlDto dto,
        CancellationToken cancellationToken
    )
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
                        cancellationToken
                    );

            return CreatedAtAction(
                nameof(ObtenerPorId),
                new
                {
                    id = clasificacionCreada.Id
                },
                clasificacionCreada
            );
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(
                new
                {
                    mensaje = ex.Message
                }
            );
        }
        catch (ArgumentException ex)
        {
            return BadRequest(
                new
                {
                    mensaje = ex.Message
                }
            );
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
                }
            );
        }
    }

    /// <summary>
    /// Actualiza una clasificación de control.
    /// </summary>
    /// <param name="id">
    /// Identificador de la clasificación.
    /// </param>
    /// <param name="dto">
    /// Información actualizada.
    /// </param>
    [HttpPut("{id:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] UpdateClasificacionControlDto dto,
        CancellationToken cancellationToken
    )
    {
        if (id <= 0)
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "El identificador de la clasificación no es válido."
                }
            );
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
                        cancellationToken
                    );

            if (!actualizado)
            {
                return NotFound(
                    new
                    {
                        mensaje =
                            "No se encontró la clasificación de control."
                    }
                );
            }

            return Ok(
                new
                {
                    mensaje =
                        "Clasificación de control actualizada correctamente."
                }
            );
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(
                new
                {
                    mensaje = ex.Message
                }
            );
        }
        catch (ArgumentException ex)
        {
            return BadRequest(
                new
                {
                    mensaje = ex.Message
                }
            );
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
                }
            );
        }
    }

    /// <summary>
    /// Elimina o desactiva una clasificación de control.
    /// </summary>
    /// <param name="id">
    /// Identificador de la clasificación.
    /// </param>
    [HttpDelete("{id:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Eliminar(
        long id,
        CancellationToken cancellationToken
    )
    {
        if (id <= 0)
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "El identificador de la clasificación no es válido."
                }
            );
        }

        try
        {
            var eliminado =
                await _clasificacionControlService
                    .EliminarAsync(
                        id,
                        cancellationToken
                    );

            if (!eliminado)
            {
                return NotFound(
                    new
                    {
                        mensaje =
                            "No se encontró la clasificación de control."
                    }
                );
            }

            return Ok(
                new
                {
                    mensaje =
                        "Clasificación de control eliminada o desactivada correctamente."
                }
            );
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(
                new
                {
                    mensaje = ex.Message
                }
            );
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
                }
            );
        }
    }
}
