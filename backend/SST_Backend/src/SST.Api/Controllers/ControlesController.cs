using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar controles.
/// Un control es una medida preventiva, correctiva o de protección aplicada frente a un riesgo.
/// </summary>
[ApiController]
[Route("api/controles")]
public class ControlesController : ControllerBase
{
    private readonly IControlService _controlService;

    /// <summary>
    /// Constructor del controlador.
    /// Recibe el servicio de controles mediante inyección de dependencias.
    /// </summary>
    public ControlesController(IControlService controlService)
    {
        _controlService = controlService;
    }

    /// <summary>
    /// Obtiene todos los controles activos.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var controles = await _controlService.GetAllAsync();

        return Ok(controles);
    }

    /// <summary>
    /// Obtiene un control por su Id.
    /// </summary>
    /// <param name="id">Id del control.</param>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var control = await _controlService.GetByIdAsync(id);

        if (control is null)
            return NotFound(new { mensaje = "Control no encontrado." });

        return Ok(control);
    }

    /// <summary>
    /// Registra un nuevo control.
    /// </summary>
    /// <param name="dto">Datos del control.</param>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateControlDto dto)
    {
        try
        {
            var control = await _controlService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = control.Id }, control);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    /// <summary>
    /// Actualiza un control existente.
    /// </summary>
    /// <param name="id">Id del control.</param>
    /// <param name="dto">Datos actualizados del control.</param>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateControlDto dto)
    {
        try
        {
            var actualizado = await _controlService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Control no encontrado." });

            return Ok(new { mensaje = "Control actualizado correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    /// <summary>
    /// Desactiva un control.
    /// No elimina físicamente el registro.
    /// </summary>
    /// <param name="id">Id del control.</param>
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _controlService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Control no encontrado." });

        return Ok(new { mensaje = "Control desactivado correctamente." });
    }
}
