using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar seguimientos IPERC.
/// </summary>
[ApiController]
[Route("api/seguimientos-iperc")]
public class SeguimientosIPERCController : ControllerBase
{
    private readonly ISeguimientoIPERCService _seguimientoIPERCService;

    public SeguimientosIPERCController(ISeguimientoIPERCService seguimientoIPERCService)
    {
        _seguimientoIPERCService = seguimientoIPERCService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var seguimientos = await _seguimientoIPERCService.GetAllAsync();

        return Ok(seguimientos);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var seguimiento = await _seguimientoIPERCService.GetByIdAsync(id);

        if (seguimiento is null)
            return NotFound(new { mensaje = "Seguimiento IPERC no encontrado." });

        return Ok(seguimiento);
    }

    [HttpGet("detalle/{detalleIPERCId:long}")]
    public async Task<IActionResult> GetByDetalleId(long detalleIPERCId)
    {
        var seguimientos = await _seguimientoIPERCService.GetByDetalleIdAsync(detalleIPERCId);

        return Ok(seguimientos);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateSeguimientoIPERCDto dto)
    {
        try
        {
            var seguimiento = await _seguimientoIPERCService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = seguimiento.Id }, seguimiento);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateSeguimientoIPERCDto dto)
    {
        try
        {
            var actualizado = await _seguimientoIPERCService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Seguimiento IPERC no encontrado." });

            return Ok(new { mensaje = "Seguimiento IPERC actualizado correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPatch("{id:long}/verificar")]
    public async Task<IActionResult> Verificar(long id)
    {
        var verificado = await _seguimientoIPERCService.VerificarAsync(id);

        if (!verificado)
            return NotFound(new { mensaje = "Seguimiento IPERC no encontrado." });

        return Ok(new { mensaje = "Seguimiento IPERC verificado correctamente." });
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _seguimientoIPERCService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Seguimiento IPERC no encontrado." });

        return Ok(new { mensaje = "Seguimiento IPERC eliminado correctamente." });
    }
}
