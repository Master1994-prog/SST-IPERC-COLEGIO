using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar la relación entre peligros y controles.
/// </summary>
[ApiController]
[Route("api/peligros-controles")]
public class PeligrosControlesController : ControllerBase
{
    private readonly IPeligroControlService _peligroControlService;

    public PeligrosControlesController(IPeligroControlService peligroControlService)
    {
        _peligroControlService = peligroControlService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var relaciones = await _peligroControlService.GetAllAsync();

        return Ok(relaciones);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var relacion = await _peligroControlService.GetByIdAsync(id);

        if (relacion is null)
            return NotFound(new { mensaje = "Relación peligro-control no encontrada." });

        return Ok(relacion);
    }

    [HttpGet("peligro/{peligroId:long}")]
    public async Task<IActionResult> GetByPeligroId(long peligroId)
    {
        var relaciones = await _peligroControlService.GetByPeligroIdAsync(peligroId);

        return Ok(relaciones);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePeligroControlDto dto)
    {
        try
        {
            var relacion = await _peligroControlService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = relacion.Id }, relacion);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdatePeligroControlDto dto)
    {
        try
        {
            var actualizado = await _peligroControlService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Relación peligro-control no encontrada." });

            return Ok(new { mensaje = "Relación peligro-control actualizada correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _peligroControlService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Relación peligro-control no encontrada." });

        return Ok(new { mensaje = "Relación peligro-control desactivada correctamente." });
    }
}
