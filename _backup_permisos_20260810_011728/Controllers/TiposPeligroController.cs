using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar los tipos de peligro.
/// Los tipos de peligro pertenecen a una categoría de peligro.
/// </summary>
[ApiController]
[Route("api/tipos-peligro")]
[Authorize]
public class TiposPeligroController : ControllerBase
{
    private readonly ITipoPeligroService _tipoPeligroService;

    /// <summary>
    /// Constructor del controlador.
    /// </summary>
    public TiposPeligroController(
        ITipoPeligroService tipoPeligroService)
    {
        _tipoPeligroService = tipoPeligroService;
    }

    /// <summary>
    /// Obtiene todos los tipos de peligro activos.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var tipos =
            await _tipoPeligroService.GetAllAsync();

        return Ok(tipos);
    }

    /// <summary>
    /// Obtiene un tipo de peligro por su Id.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var tipo =
            await _tipoPeligroService.GetByIdAsync(id);

        if (tipo is null)
        {
            return NotFound(new
            {
                mensaje =
                    "Tipo de peligro no encontrado."
            });
        }

        return Ok(tipo);
    }

    /// <summary>
    /// Registra un nuevo tipo de peligro.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPost]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Create(
        [FromBody] CreateTipoPeligroDto dto)
    {
        try
        {
            var tipo =
                await _tipoPeligroService
                    .CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new
                {
                    id = tipo.Id
                },
                tipo);
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
    /// Actualiza un tipo de peligro.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateTipoPeligroDto dto)
    {
        try
        {
            var actualizado =
                await _tipoPeligroService
                    .UpdateAsync(id, dto);

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje =
                        "Tipo de peligro no encontrado."
                });
            }

            return Ok(new
            {
                mensaje =
                    "Tipo de peligro actualizado correctamente."
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
    /// Desactiva un tipo de peligro.
    /// Solo SUPER_ADMIN puede hacerlo.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _tipoPeligroService
                .DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje =
                    "Tipo de peligro no encontrado."
            });
        }

        return Ok(new
        {
            mensaje =
                "Tipo de peligro desactivado correctamente."
        });
    }
}