using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar los detalles de una Matriz IPERC.
/// </summary>
[ApiController]
[Route("api/detalles-iperc")]
public class DetallesIPERCController : ControllerBase
{
    private readonly IDetalleIPERCService _detalleIPERCService;

    public DetallesIPERCController(IDetalleIPERCService detalleIPERCService)
    {
        _detalleIPERCService = detalleIPERCService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var detalles = await _detalleIPERCService.GetAllAsync();

        return Ok(detalles);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var detalle = await _detalleIPERCService.GetByIdAsync(id);

        if (detalle is null)
            return NotFound(new { mensaje = "Detalle IPERC no encontrado." });

        return Ok(detalle);
    }

    [HttpGet("matriz/{matrizIPERCId:long}")]
    public async Task<IActionResult> GetByMatrizId(long matrizIPERCId)
    {
        var detalles = await _detalleIPERCService.GetByMatrizIdAsync(matrizIPERCId);

        return Ok(detalles);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateDetalleIPERCDto dto)
    {
        try
        {
            var detalle = await _detalleIPERCService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = detalle.Id }, detalle);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateDetalleIPERCDto dto)
    {
        try
        {
            var actualizado = await _detalleIPERCService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Detalle IPERC no encontrado." });

            return Ok(new { mensaje = "Detalle IPERC actualizado correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _detalleIPERCService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Detalle IPERC no encontrado." });

        return Ok(new { mensaje = "Detalle IPERC cerrado correctamente." });
    }
}
