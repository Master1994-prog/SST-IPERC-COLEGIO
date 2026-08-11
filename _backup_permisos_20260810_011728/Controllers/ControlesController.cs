using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar controles.
/// Un control es una medida preventiva, correctiva o de protección
/// aplicada frente a un riesgo.
/// </summary>
[ApiController]
[Route("api/controles")]
[Authorize]
public class ControlesController : ControllerBase
{
    private readonly IControlService _controlService;

    /// <summary>
    /// Constructor del controlador.
    /// </summary>
    public ControlesController(
        IControlService controlService)
    {
        _controlService = controlService;
    }

    /// <summary>
    /// Obtiene todos los controles activos.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var controles =
            await _controlService.GetAllAsync();

        return Ok(controles);
    }

    /// <summary>
    /// Obtiene un control por su Id.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var control =
            await _controlService.GetByIdAsync(id);

        if (control is null)
        {
            return NotFound(new
            {
                mensaje = "Control no encontrado."
            });
        }

        return Ok(control);
    }

    /// <summary>
    /// Registra un nuevo control.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPost]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Create(
        [FromBody] CreateControlDto dto)
    {
        try
        {
            var control =
                await _controlService
                    .CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new
                {
                    id = control.Id
                },
                control);
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
    /// Actualiza un control existente.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateControlDto dto)
    {
        try
        {
            var actualizado =
                await _controlService.UpdateAsync(
                    id,
                    dto);

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje =
                        "Control no encontrado."
                });
            }

            return Ok(new
            {
                mensaje =
                    "Control actualizado correctamente."
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
    /// Desactiva un control.
    /// Solo SUPER_ADMIN puede hacerlo.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _controlService.DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje =
                    "Control no encontrado."
            });
        }

        return Ok(new
        {
            mensaje =
                "Control desactivado correctamente."
        });
    }
}
