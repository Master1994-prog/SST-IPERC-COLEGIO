using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar consecuencias.
/// Una consecuencia representa el daño que puede causar un peligro.
/// </summary>
[ApiController]
[Route("api/consecuencias")]
[Authorize]
public class ConsecuenciasController : ControllerBase
{
    private readonly IConsecuenciaService _consecuenciaService;

    /// <summary>
    /// Constructor del controlador.
    /// </summary>
    public ConsecuenciasController(
        IConsecuenciaService consecuenciaService)
    {
        _consecuenciaService = consecuenciaService;
    }

    /// <summary>
    /// Obtiene todas las consecuencias activas.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var consecuencias =
            await _consecuenciaService.GetAllAsync();

        return Ok(consecuencias);
    }

    /// <summary>
    /// Obtiene una consecuencia por su Id.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var consecuencia =
            await _consecuenciaService.GetByIdAsync(id);

        if (consecuencia is null)
        {
            return NotFound(new
            {
                mensaje = "Consecuencia no encontrada."
            });
        }

        return Ok(consecuencia);
    }

    /// <summary>
    /// Registra una nueva consecuencia.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Create(
        [FromBody] CreateConsecuenciaDto dto)
    {
        try
        {
            var consecuencia =
                await _consecuenciaService
                    .CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new
                {
                    id = consecuencia.Id
                },
                consecuencia);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new
            {
                mensaje = ex.Message
            });
        }
    }

    /// <summary>
    /// Actualiza una consecuencia existente.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateConsecuenciaDto dto)
    {
        try
        {
            var actualizado =
                await _consecuenciaService
                    .UpdateAsync(id, dto);

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje = "Consecuencia no encontrada."
                });
            }

            return Ok(new
            {
                mensaje =
                    "Consecuencia actualizada correctamente."
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new
            {
                mensaje = ex.Message
            });
        }
    }

    /// <summary>
    /// Desactiva una consecuencia.
    /// Solo SUPER_ADMIN puede hacerlo.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _consecuenciaService
                .DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje = "Consecuencia no encontrada."
            });
        }

        return Ok(new
        {
            mensaje =
                "Consecuencia desactivada correctamente."
        });
    }
}
