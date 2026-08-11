using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar peligros.
/// Un peligro representa una fuente, situación o condición
/// que puede causar daño.
/// </summary>
[ApiController]
[Route("api/peligros")]
[Authorize]
public class PeligrosController : ControllerBase
{
    private readonly IPeligroService _peligroService;

    /// <summary>
    /// Constructor del controlador.
    /// </summary>
    public PeligrosController(
        IPeligroService peligroService)
    {
        _peligroService = peligroService;
    }

    /// <summary>
    /// Obtiene todos los peligros activos.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var peligros =
            await _peligroService.GetAllAsync();

        return Ok(peligros);
    }

    /// <summary>
    /// Obtiene un peligro por su Id.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var peligro =
            await _peligroService.GetByIdAsync(id);

        if (peligro is null)
        {
            return NotFound(new
            {
                mensaje = "Peligro no encontrado."
            });
        }

        return Ok(peligro);
    }

    /// <summary>
    /// Registra un nuevo peligro.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPost]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Create(
        [FromBody] CreatePeligroDto dto)
    {
        try
        {
            var peligro =
                await _peligroService.CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new { id = peligro.Id },
                peligro);
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
    /// Actualiza un peligro existente.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdatePeligroDto dto)
    {
        try
        {
            var actualizado =
                await _peligroService.UpdateAsync(
                    id,
                    dto);

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje = "Peligro no encontrado."
                });
            }

            return Ok(new
            {
                mensaje =
                    "Peligro actualizado correctamente."
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
    /// Desactiva un peligro.
    /// Solo SUPER_ADMIN puede hacerlo.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _peligroService.DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje = "Peligro no encontrado."
            });
        }

        return Ok(new
        {
            mensaje =
                "Peligro desactivado correctamente."
        });
    }
}