using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar consecuencias.
/// Una consecuencia representa el daño que puede causar un peligro.
/// </summary>
[ApiController]
[Route("api/consecuencias")]
public class ConsecuenciasController : ControllerBase
{
    private readonly IConsecuenciaService _consecuenciaService;

    /// <summary>
    /// Constructor del controlador.
    /// Recibe el servicio de consecuencias mediante inyección de dependencias.
    /// </summary>
    public ConsecuenciasController(IConsecuenciaService consecuenciaService)
    {
        _consecuenciaService = consecuenciaService;
    }

    /// <summary>
    /// Obtiene todas las consecuencias activas.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var consecuencias = await _consecuenciaService.GetAllAsync();

        return Ok(consecuencias);
    }

    /// <summary>
    /// Obtiene una consecuencia por su Id.
    /// </summary>
    /// <param name="id">Id de la consecuencia.</param>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var consecuencia = await _consecuenciaService.GetByIdAsync(id);

        if (consecuencia is null)
            return NotFound(new { mensaje = "Consecuencia no encontrada." });

        return Ok(consecuencia);
    }

    /// <summary>
    /// Registra una nueva consecuencia.
    /// </summary>
    /// <param name="dto">Datos de la consecuencia.</param>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateConsecuenciaDto dto)
    {
        try
        {
            var consecuencia = await _consecuenciaService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = consecuencia.Id }, consecuencia);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    /// <summary>
    /// Actualiza una consecuencia existente.
    /// </summary>
    /// <param name="id">Id de la consecuencia.</param>
    /// <param name="dto">Datos actualizados de la consecuencia.</param>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateConsecuenciaDto dto)
    {
        try
        {
            var actualizado = await _consecuenciaService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Consecuencia no encontrada." });

            return Ok(new { mensaje = "Consecuencia actualizada correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    /// <summary>
    /// Desactiva una consecuencia.
    /// No elimina físicamente el registro.
    /// </summary>
    /// <param name="id">Id de la consecuencia.</param>
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _consecuenciaService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Consecuencia no encontrada." });

        return Ok(new { mensaje = "Consecuencia desactivada correctamente." });
    }
}
