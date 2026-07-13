using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar la relación entre peligros y consecuencias.
/// </summary>
[ApiController]
[Route("api/peligros-consecuencias")]
public class PeligrosConsecuenciasController : ControllerBase
{
    private readonly IPeligroConsecuenciaService _peligroConsecuenciaService;

    /// <summary>
    /// Constructor del controlador.
    /// Recibe el servicio mediante inyección de dependencias.
    /// </summary>
    public PeligrosConsecuenciasController(IPeligroConsecuenciaService peligroConsecuenciaService)
    {
        _peligroConsecuenciaService = peligroConsecuenciaService;
    }

    /// <summary>
    /// Obtiene todas las relaciones activas entre peligros y consecuencias.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var relaciones = await _peligroConsecuenciaService.GetAllAsync();

        return Ok(relaciones);
    }

    /// <summary>
    /// Obtiene una relación peligro-consecuencia por su Id.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var relacion = await _peligroConsecuenciaService.GetByIdAsync(id);

        if (relacion is null)
            return NotFound(new { mensaje = "Relación peligro-consecuencia no encontrada." });

        return Ok(relacion);
    }

    /// <summary>
    /// Obtiene las consecuencias asociadas a un peligro específico.
    /// </summary>
    [HttpGet("peligro/{peligroId:long}")]
    public async Task<IActionResult> GetByPeligroId(long peligroId)
    {
        var relaciones = await _peligroConsecuenciaService.GetByPeligroIdAsync(peligroId);

        return Ok(relaciones);
    }

    /// <summary>
    /// Registra una nueva relación peligro-consecuencia.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePeligroConsecuenciaDto dto)
    {
        try
        {
            var relacion = await _peligroConsecuenciaService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = relacion.Id }, relacion);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    /// <summary>
    /// Actualiza una relación peligro-consecuencia existente.
    /// </summary>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdatePeligroConsecuenciaDto dto)
    {
        try
        {
            var actualizado = await _peligroConsecuenciaService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Relación peligro-consecuencia no encontrada." });

            return Ok(new { mensaje = "Relación peligro-consecuencia actualizada correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    /// <summary>
    /// Desactiva una relación peligro-consecuencia.
    /// </summary>
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _peligroConsecuenciaService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Relación peligro-consecuencia no encontrada." });

        return Ok(new { mensaje = "Relación peligro-consecuencia desactivada correctamente." });
    }
}
