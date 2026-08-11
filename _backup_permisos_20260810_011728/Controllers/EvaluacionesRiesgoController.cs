using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar evaluaciones de riesgo IPERC.
/// </summary>
[ApiController]
[Route("api/evaluaciones-riesgo")]
public class EvaluacionesRiesgoController : ControllerBase
{
    private readonly IEvaluacionRiesgoService _evaluacionRiesgoService;

    public EvaluacionesRiesgoController(IEvaluacionRiesgoService evaluacionRiesgoService)
    {
        _evaluacionRiesgoService = evaluacionRiesgoService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var evaluaciones = await _evaluacionRiesgoService.GetAllAsync();
        return Ok(evaluaciones);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var evaluacion = await _evaluacionRiesgoService.GetByIdAsync(id);

        if (evaluacion is null)
            return NotFound(new { mensaje = "Evaluación de riesgo no encontrada." });

        return Ok(evaluacion);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateEvaluacionRiesgoDto dto)
    {
        try
        {
            var evaluacion = await _evaluacionRiesgoService.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = evaluacion.Id }, evaluacion);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateEvaluacionRiesgoDto dto)
    {
        try
        {
            var actualizado = await _evaluacionRiesgoService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Evaluación de riesgo no encontrada." });

            return Ok(new { mensaje = "Evaluación de riesgo actualizada correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _evaluacionRiesgoService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Evaluación de riesgo no encontrada." });

        return Ok(new { mensaje = "Evaluación de riesgo eliminada correctamente." });
    }
}
