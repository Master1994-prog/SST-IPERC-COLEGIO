using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Permite consultar los usuarios que pueden seleccionarse
/// como responsables dentro de una matriz IPERC.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public sealed class UsuariosController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    /// <summary>
    /// Recibe el contexto de la base de datos mediante
    /// inyección de dependencias.
    /// </summary>
    public UsuariosController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene los usuarios activos.
    ///
    /// Permite filtrar opcionalmente por:
    /// - Institución.
    /// - Sede.
    /// - Área.
    ///
    /// Ejemplos:
    /// GET /api/usuarios
    /// GET /api/usuarios?institucionId=1
    /// GET /api/usuarios?institucionId=1&areaId=2
    /// </summary>
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> ObtenerTodos(
        [FromQuery] long? institucionId,
        [FromQuery] long? sedeId,
        [FromQuery] long? areaId,
        CancellationToken cancellationToken)
    {
        // AsNoTracking mejora el rendimiento porque esta
        // operación solamente consulta información.
        var consulta = _dbContext.Usuarios
            .AsNoTracking()
            .Where(usuario =>
                usuario.Estado &&
                usuario.Activo);

        // Cuando se recibe una institución, se muestran
        // solamente sus usuarios.
        if (institucionId.HasValue &&
            institucionId.Value > 0)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.InstitucionId ==
                    institucionId.Value);
        }

        // Filtro opcional por sede.
        if (sedeId.HasValue && sedeId.Value > 0)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.SedeId == sedeId.Value);
        }

        // Filtro opcional por área.
        if (areaId.HasValue && areaId.Value > 0)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.AreaId == areaId.Value);
        }

        // Solo se devuelven los datos necesarios.
        // Nunca se envía PasswordHash al dispositivo.
        var usuarios = await consulta
            .OrderBy(usuario => usuario.Apellidos)
            .ThenBy(usuario => usuario.Nombres)
            .Select(usuario => new
            {
                usuario.Id,
                usuario.Nombres,
                usuario.Apellidos,

                NombreCompleto =
                    usuario.Nombres + " " +
                    usuario.Apellidos,

                usuario.NombreUsuario,
                usuario.Correo,
                usuario.Telefono,
                usuario.InstitucionId,
                usuario.SedeId,
                usuario.AreaId,
                usuario.Activo
            })
            .ToListAsync(cancellationToken);

        return Ok(usuarios);
    }

    /// <summary>
    /// Obtiene un usuario activo mediante su ID.
    ///
    /// Se utilizará para mostrar el responsable que ya
    /// está asociado con un detalle IPERC.
    /// </summary>
    [HttpGet("{id:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el usuario."
            });
        }

        var usuario = await _dbContext.Usuarios
            .AsNoTracking()
            .Where(item =>
                item.Id == id &&
                item.Estado &&
                item.Activo)
            .Select(item => new
            {
                item.Id,
                item.Nombres,
                item.Apellidos,

                NombreCompleto =
                    item.Nombres + " " +
                    item.Apellidos,

                item.NombreUsuario,
                item.Correo,
                item.Telefono,
                item.InstitucionId,
                item.SedeId,
                item.AreaId,
                item.Activo
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (usuario is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el usuario solicitado."
            });
        }

        return Ok(usuario);
    }
}
