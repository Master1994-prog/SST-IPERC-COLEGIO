using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar Matrices IPERC.
/// </summary>
[ApiController]
[Route("api/matrices-iperc")]
public class MatricesIPERCController : ControllerBase
{
    private readonly IMatrizIPERCService _matrizIPERCService;

    public MatricesIPERCController(IMatrizIPERCService matrizIPERCService)
    {
        _matrizIPERCService = matrizIPERCService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var matrices = await _matrizIPERCService.GetAllAsync();

        return Ok(matrices);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var matriz = await _matrizIPERCService.GetByIdAsync(id);

        if (matriz is null)
            return NotFound(new { mensaje = "Matriz IPERC no encontrada." });

        return Ok(matriz);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMatrizIPERCDto dto)
    {
        try
        {
            var matriz = await _matrizIPERCService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = matriz.Id }, matriz);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateMatrizIPERCDto dto)
    {
        try
        {
            var actualizado = await _matrizIPERCService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Matriz IPERC no encontrada." });

            return Ok(new { mensaje = "Matriz IPERC actualizada correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _matrizIPERCService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Matriz IPERC no encontrada." });

        return Ok(new { mensaje = "Matriz IPERC cerrada correctamente." });
    }
}
