using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar Equipos de Protección Personal.
/// </summary>
[ApiController]
[Route("api/equipos-proteccion")]
[Authorize]
public class EquiposProteccionController : ControllerBase
{
    private readonly IEquipoProteccionService
        _equipoProteccionService;

    /// <summary>
    /// Constructor del controlador.
    /// </summary>
    public EquiposProteccionController(
        IEquipoProteccionService equipoProteccionService)
    {
        _equipoProteccionService =
            equipoProteccionService;
    }

    /// <summary>
    /// Obtiene todos los equipos de protección activos.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var equipos =
            await _equipoProteccionService
                .GetAllAsync();

        return Ok(equipos);
    }

    /// <summary>
    /// Obtiene un equipo de protección por su Id.
    /// Disponible para cualquier usuario autenticado.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var equipo =
            await _equipoProteccionService
                .GetByIdAsync(id);

        if (equipo is null)
        {
            return NotFound(new
            {
                mensaje =
                    "Equipo de protección no encontrado."
            });
        }

        return Ok(equipo);
    }

    /// <summary>
    /// Registra un nuevo equipo de protección.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPost]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Create(
        [FromBody] CreateEquipoProteccionDto dto)
    {
        try
        {
            var equipo =
                await _equipoProteccionService
                    .CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new
                {
                    id = equipo.Id
                },
                equipo);
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
    /// Actualiza un equipo de protección.
    /// Solo SUPER_ADMIN, ADMIN y COORDINADOR.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(
        Roles = "SUPER_ADMIN,ADMIN,COORDINADOR")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateEquipoProteccionDto dto)
    {
        try
        {
            var actualizado =
                await _equipoProteccionService
                    .UpdateAsync(id, dto);

            if (!actualizado)
            {
                return NotFound(new
                {
                    mensaje =
                        "Equipo de protección no encontrado."
                });
            }

            return Ok(new
            {
                mensaje =
                    "Equipo de protección actualizado correctamente."
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
    /// Desactiva un equipo de protección.
    /// Solo SUPER_ADMIN.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _equipoProteccionService
                .DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(new
            {
                mensaje =
                    "Equipo de protección no encontrado."
            });
        }

        return Ok(new
        {
            mensaje =
                "Equipo de protección desactivado correctamente."
        });
    }
}