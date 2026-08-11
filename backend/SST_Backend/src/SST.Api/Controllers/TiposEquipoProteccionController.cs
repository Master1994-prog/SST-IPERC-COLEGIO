using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar tipos de Equipos de Protección Personal.
/// </summary>
[ApiController]
[Route("api/tipos-equipo-proteccion")]
[Authorize]
public class TiposEquipoProteccionController : ControllerBase
{
    private readonly ITipoEquipoProteccionService
        _tipoEquipoProteccionService;

    public TiposEquipoProteccionController(
        ITipoEquipoProteccionService tipoEquipoProteccionService)
    {
        _tipoEquipoProteccionService =
            tipoEquipoProteccionService;
    }

    /// <summary>
    /// Obtiene todos los tipos de EPP.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var tipos =
            await _tipoEquipoProteccionService
                .GetAllAsync();

        return Ok(tipos);
    }

    /// <summary>
    /// Obtiene un tipo de EPP por Id.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var tipo =
            await _tipoEquipoProteccionService
                .GetByIdAsync(id);

        if (tipo is null)
        {
            return NotFound(new
            {
                mensaje =
                    "Tipo de equipo de protección no encontrado."
            });
        }

        return Ok(tipo);
    }

    /// <summary>
    /// Registra un nuevo tipo de EPP.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Create(
        [FromBody] CreateTipoEquipoProteccionDto dto)
    {
        try
        {
            var tipo =
                await _tipoEquipoProteccionService
                    .CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new
                {
                    id = tipo.Id
                },
                tipo);
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
    /// Actualiza un tipo de EPP.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateTipoEquipoProteccionDto dto)
    {
        try
        {
            var actualizado =
                await _tipoEquipoProteccionService
                    .UpdateAsync(id, dto);

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje =
                        "Tipo de equipo de protección no encontrado."
                });
            }

            return Ok(new
            {
                mensaje =
                    "Tipo de equipo de protección actualizado correctamente."
            });
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
    /// Desactiva un tipo de EPP.
    /// Solo SUPER_ADMIN.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _tipoEquipoProteccionService
                .DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje =
                    "Tipo de equipo de protección no encontrado."
            });
        }

        return Ok(new
        {
            mensaje =
                "Tipo de equipo de protección desactivado correctamente."
        });
    }
}