using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar mapas de riesgo.
/// </summary>
[ApiController]
[Route("api/mapas-riesgo")]
public class MapasRiesgoController : ControllerBase
{
    private readonly IMapaRiesgoService _mapaRiesgoService;

    public MapasRiesgoController(IMapaRiesgoService mapaRiesgoService)
    {
        _mapaRiesgoService = mapaRiesgoService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var mapas = await _mapaRiesgoService.GetAllAsync();

        return Ok(mapas);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var mapa = await _mapaRiesgoService.GetByIdAsync(id);

        if (mapa is null)
            return NotFound(new { mensaje = "Mapa de riesgo no encontrado." });

        return Ok(mapa);
    }

    [HttpGet("matriz/{matrizIPERCId:long}")]
    public async Task<IActionResult> GetByMatrizId(long matrizIPERCId)
    {
        var mapas = await _mapaRiesgoService.GetByMatrizIdAsync(matrizIPERCId);

        return Ok(mapas);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMapaRiesgoDto dto)
    {
        try
        {
            var mapa = await _mapaRiesgoService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = mapa.Id }, mapa);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateMapaRiesgoDto dto)
    {
        try
        {
            var actualizado = await _mapaRiesgoService.UpdateAsync(id, dto);

            if (!actualizado)
                return NotFound(new { mensaje = "Mapa de riesgo no encontrado." });

            return Ok(new { mensaje = "Mapa de riesgo actualizado correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _mapaRiesgoService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Mapa de riesgo no encontrado." });

        return Ok(new { mensaje = "Mapa de riesgo cerrado correctamente." });
    }
}
