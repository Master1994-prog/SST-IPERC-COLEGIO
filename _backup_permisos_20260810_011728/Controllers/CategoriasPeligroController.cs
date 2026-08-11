using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar las categorías de peligro.
/// Una categoría de peligro permite clasificar los peligros usados
/// en la matriz IPERC.
/// </summary>
[ApiController]
[Route("api/categorias-peligro")]
[Authorize]
public class CategoriasPeligroController : ControllerBase
{
    private readonly ICategoriaPeligroService _categoriaPeligroService;

    public CategoriasPeligroController(
        ICategoriaPeligroService categoriaPeligroService)
    {
        _categoriaPeligroService = categoriaPeligroService;
    }

    /// <summary>
    /// Todos los usuarios autenticados pueden consultar.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var categorias =
            await _categoriaPeligroService.GetAllAsync();

        return Ok(categorias);
    }

    /// <summary>
    /// Todos los usuarios autenticados pueden consultar.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var categoria =
            await _categoriaPeligroService.GetByIdAsync(id);

        if (categoria is null)
        {
            return NotFound(new
            {
                mensaje =
                    "Categoría de peligro no encontrada."
            });
        }

        return Ok(categoria);
    }

    /// <summary>
    /// Solo roles administrativos pueden registrar.
    /// </summary>
    [HttpPost]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Create(
        [FromBody] CreateCategoriaPeligroDto dto)
    {
        try
        {
            var categoria =
                await _categoriaPeligroService
                    .CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new { id = categoria.Id },
                categoria);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new
            {
                mensaje = ex.Message
            });
        }
    }

    /// <summary>
    /// Solo roles administrativos pueden actualizar.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateCategoriaPeligroDto dto)
    {
        var actualizado =
            await _categoriaPeligroService
                .UpdateAsync(id, dto);

        if (!actualizado)
        {
            return NotFound(new
            {
                mensaje =
                    "Categoría de peligro no encontrada."
            });
        }

        return Ok(new
        {
            mensaje =
                "Categoría de peligro actualizada correctamente."
        });
    }

    /// <summary>
    /// Solo SUPER_ADMIN puede eliminar/desactivar.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _categoriaPeligroService
                .DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje =
                    "Categoría de peligro no encontrada."
            });
        }

        return Ok(new
        {
            mensaje =
                "Categoría de peligro desactivada correctamente."
        });
    }
}
