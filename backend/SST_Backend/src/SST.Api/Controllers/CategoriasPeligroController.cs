using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar las categorías de peligro.
/// Una categoría de peligro permite clasificar los peligros usados en la matriz IPERC.
/// Ejemplo: Físico, Químico, Biológico, Ergonómico, Psicosocial, Seguridad, etc.
/// </summary>
[ApiController]
[Route("api/categorias-peligro")]
public class CategoriasPeligroController : ControllerBase
{
    private readonly ICategoriaPeligroService _categoriaPeligroService;

    /// <summary>
    /// Constructor del controlador.
    /// Recibe el servicio de categorías de peligro mediante inyección de dependencias.
    /// </summary>
    public CategoriasPeligroController(ICategoriaPeligroService categoriaPeligroService)
    {
        _categoriaPeligroService = categoriaPeligroService;
    }

    /// <summary>
    /// Obtiene todas las categorías de peligro activas.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var categorias = await _categoriaPeligroService.GetAllAsync();

        return Ok(categorias);
    }

    /// <summary>
    /// Obtiene una categoría de peligro por su identificador.
    /// </summary>
    /// <param name="id">Id de la categoría de peligro.</param>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var categoria = await _categoriaPeligroService.GetByIdAsync(id);

        if (categoria is null)
            return NotFound(new { mensaje = "Categoría de peligro no encontrada." });

        return Ok(categoria);
    }

    /// <summary>
    /// Registra una nueva categoría de peligro.
    /// </summary>
    /// <param name="dto">Datos de la categoría de peligro a registrar.</param>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateCategoriaPeligroDto dto)
    {
        try
        {
            var categoria = await _categoriaPeligroService.CreateAsync(dto);

            return CreatedAtAction(nameof(GetById), new { id = categoria.Id }, categoria);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }

    /// <summary>
    /// Actualiza una categoría de peligro existente.
    /// </summary>
    /// <param name="id">Id de la categoría de peligro.</param>
    /// <param name="dto">Datos actualizados de la categoría de peligro.</param>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateCategoriaPeligroDto dto)
    {
        var actualizado = await _categoriaPeligroService.UpdateAsync(id, dto);

        if (!actualizado)
            return NotFound(new { mensaje = "Categoría de peligro no encontrada." });

        return Ok(new { mensaje = "Categoría de peligro actualizada correctamente." });
    }

    /// <summary>
    /// Desactiva una categoría de peligro.
    /// No se elimina físicamente de la base de datos, solo cambia su estado.
    /// </summary>
    /// <param name="id">Id de la categoría de peligro.</param>
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado = await _categoriaPeligroService.DeleteAsync(id);

        if (!eliminado)
            return NotFound(new { mensaje = "Categoría de peligro no encontrada." });

        return Ok(new { mensaje = "Categoría de peligro desactivada correctamente." });
    }
}
