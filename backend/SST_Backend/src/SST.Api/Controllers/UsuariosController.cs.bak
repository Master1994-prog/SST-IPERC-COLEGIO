using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Gestiona los usuarios del sistema SST/IPERC.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public sealed class UsuariosController : ControllerBase
{
    private readonly SSTDbContext _dbContext;
    private readonly IPasswordHasher<Usuario> _passwordHasher;

    public UsuariosController(
        SSTDbContext dbContext,
        IPasswordHasher<Usuario> passwordHasher)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
    }

    // =========================================================
    // GET: api/Usuarios
    // =========================================================

    /// <summary>
    /// Obtiene los usuarios registrados.
    ///
    /// Permite filtrar opcionalmente por:
    /// - Institución.
    /// - Sede.
    /// - Área.
    /// - Rol.
    /// - Estado activo/inactivo.
    ///
    /// Ejemplos:
    /// GET /api/Usuarios
    /// GET /api/Usuarios?activo=true
    /// GET /api/Usuarios?activo=false
    /// GET /api/Usuarios?institucionId=1
    /// GET /api/Usuarios?rolId=2
    /// </summary>
    [HttpGet]
    [ProducesResponseType(
        typeof(List<UsuarioResponseDto>),
        StatusCodes.Status200OK)]
    public async Task<IActionResult> ObtenerTodos(
        [FromQuery] long? institucionId,
        [FromQuery] long? sedeId,
        [FromQuery] long? areaId,
        [FromQuery] long? rolId,
        [FromQuery] bool? activo,
        CancellationToken cancellationToken)
    {
        IQueryable<Usuario> consulta =
            _dbContext.Usuarios
                .AsNoTracking()
                .Where(usuario =>
                    usuario.Estado);

        // -----------------------------------------------------
        // Filtro por activo / inactivo
        // -----------------------------------------------------

        if (activo.HasValue)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.Activo == activo.Value);
        }

        // -----------------------------------------------------
        // Filtro por institución
        // -----------------------------------------------------

        if (institucionId.HasValue &&
            institucionId.Value > 0)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.InstitucionId ==
                    institucionId.Value);
        }

        // -----------------------------------------------------
        // Filtro por sede
        // -----------------------------------------------------

        if (sedeId.HasValue &&
            sedeId.Value > 0)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.SedeId ==
                    sedeId.Value);
        }

        // -----------------------------------------------------
        // Filtro por área
        // -----------------------------------------------------

        if (areaId.HasValue &&
            areaId.Value > 0)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.AreaId ==
                    areaId.Value);
        }

        // -----------------------------------------------------
        // Filtro por rol
        // -----------------------------------------------------

        if (rolId.HasValue &&
            rolId.Value > 0)
        {
            consulta = consulta.Where(
                usuario =>
                    usuario.UsuariosRoles.Any(
                        relacion =>
                            relacion.RolId ==
                                rolId.Value &&
                            relacion.Estado &&
                            relacion.Activo &&
                            relacion.Rol.Estado &&
                            relacion.Rol.Activo));
        }

        // -----------------------------------------------------
        // Resultado
        // -----------------------------------------------------

        List<UsuarioResponseDto> usuarios =
            await consulta
                .OrderBy(usuario =>
                    usuario.Apellidos)
                .ThenBy(usuario =>
                    usuario.Nombres)
                .Select(usuario =>
                    new UsuarioResponseDto
                    {
                        Id = usuario.Id,

                        Nombres =
                            usuario.Nombres,

                        Apellidos =
                            usuario.Apellidos,

                        NombreCompleto =
                            usuario.Nombres +
                            " " +
                            usuario.Apellidos,

                        NumeroDocumento =
                            usuario.NumeroDocumento,

                        TipoDocumento =
                            usuario.TipoDocumento,

                        Correo =
                            usuario.Correo,

                        Telefono =
                            usuario.Telefono,

                        NombreUsuario =
                            usuario.NombreUsuario,

                        DebeCambiarPassword =
                            usuario
                                .DebeCambiarPassword,

                        UltimoAcceso =
                            usuario.UltimoAcceso,

                        InstitucionId =
                            usuario.InstitucionId,

                        SedeId =
                            usuario.SedeId,

                        AreaId =
                            usuario.AreaId,

                        Activo =
                            usuario.Activo,

                        FechaRegistro =
                            usuario.FechaRegistro,

                        FechaActualizacion =
                            usuario
                                .FechaActualizacion,

                        Roles =
                            usuario
                                .UsuariosRoles
                                .Where(
                                    relacion =>
                                        relacion
                                            .Estado &&
                                        relacion
                                            .Activo &&
                                        relacion
                                            .Rol
                                            .Estado &&
                                        relacion
                                            .Rol
                                            .Activo)
                                .OrderBy(
                                    relacion =>
                                        relacion
                                            .Rol
                                            .Nombre)
                                .Select(
                                    relacion =>
                                        new UsuarioRolResponseDto
                                        {
                                            Id =
                                                relacion
                                                    .Rol
                                                    .Id,

                                            Codigo =
                                                relacion
                                                    .Rol
                                                    .Codigo,

                                            Nombre =
                                                relacion
                                                    .Rol
                                                    .Nombre,

                                            EsGlobal =
                                                relacion
                                                    .Rol
                                                    .EsGlobal
                                        })
                                .ToList()
                    })
                .ToListAsync(
                    cancellationToken);

        return Ok(usuarios);
    }

    // =========================================================
    // GET: api/Usuarios/{id}
    // =========================================================

    /// <summary>
    /// Obtiene un usuario mediante su identificador.
    /// Puede devolver usuarios activos o inactivos,
    /// siempre que no hayan sido eliminados lógicamente.
    /// </summary>
    [HttpGet("{id:long}")]
    [ProducesResponseType(
        typeof(UsuarioResponseDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del usuario no es válido."
            });
        }

        UsuarioResponseDto? usuario =
            await ObtenerUsuarioResponseAsync(
                id,
                cancellationToken);

        if (usuario is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el usuario solicitado."
            });
        }

        return Ok(usuario);
    }

    // =========================================================
    // POST: api/Usuarios
    // =========================================================

    /// <summary>
    /// Registra un nuevo usuario y asigna sus roles.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(
        typeof(UsuarioResponseDto),
        StatusCodes.Status201Created)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Crear(
        [FromBody] CrearUsuarioDto solicitud,
        CancellationToken cancellationToken)
    {
        string nombres =
            solicitud.Nombres.Trim();

        string apellidos =
            solicitud.Apellidos.Trim();

        string nombreUsuario =
            solicitud.NombreUsuario
                .Trim()
                .ToLowerInvariant();

        string? correo =
            LimpiarCorreo(
                solicitud.Correo);

        string? numeroDocumento =
            LimpiarTextoOpcional(
                solicitud.NumeroDocumento);

        string? tipoDocumento =
            LimpiarTextoOpcional(
                solicitud.TipoDocumento);

        string? telefono =
            LimpiarTextoOpcional(
                solicitud.Telefono);

        // -----------------------------------------------------
        // Validar roles
        // -----------------------------------------------------

        List<long> rolIds =
            solicitud.RolIds
                .Where(id => id > 0)
                .Distinct()
                .ToList();

        if (rolIds.Count == 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "Debe seleccionar al menos un rol."
            });
        }

        // -----------------------------------------------------
        // Validar nombre de usuario
        // -----------------------------------------------------

        bool nombreUsuarioDuplicado =
            await _dbContext.Usuarios
                .AsNoTracking()
                .AnyAsync(
                    usuario =>
                        usuario.Estado &&
                        usuario.NombreUsuario
                            .ToLower() ==
                        nombreUsuario,
                    cancellationToken);

        if (nombreUsuarioDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "El nombre de usuario ya está registrado."
            });
        }

        // -----------------------------------------------------
        // Validar correo
        // -----------------------------------------------------

        if (!string.IsNullOrWhiteSpace(
                correo))
        {
            bool correoDuplicado =
                await _dbContext.Usuarios
                    .AsNoTracking()
                    .AnyAsync(
                        usuario =>
                            usuario.Estado &&
                            usuario.Correo != null &&
                            usuario.Correo
                                .ToLower() ==
                            correo,
                        cancellationToken);

            if (correoDuplicado)
            {
                return Conflict(new
                {
                    mensaje =
                        "El correo electrónico ya está registrado."
                });
            }
        }

        // -----------------------------------------------------
        // Validar documento
        // -----------------------------------------------------

        if (!string.IsNullOrWhiteSpace(
                numeroDocumento))
        {
            bool documentoDuplicado =
                await _dbContext.Usuarios
                    .AsNoTracking()
                    .AnyAsync(
                        usuario =>
                            usuario.Estado &&
                            usuario.NumeroDocumento !=
                                null &&
                            usuario.NumeroDocumento ==
                                numeroDocumento,
                        cancellationToken);

            if (documentoDuplicado)
            {
                return Conflict(new
                {
                    mensaje =
                        "El número de documento ya está registrado."
                });
            }
        }

        // -----------------------------------------------------
        // Validar organización
        // -----------------------------------------------------

        IActionResult? validacionOrganizacion =
            await ValidarOrganizacionAsync(
                solicitud.InstitucionId,
                solicitud.SedeId,
                solicitud.AreaId,
                cancellationToken);

        if (validacionOrganizacion is not null)
        {
            return validacionOrganizacion;
        }

        // -----------------------------------------------------
        // Buscar roles
        // -----------------------------------------------------

        List<Rol> roles =
            await _dbContext.Roles
                .Where(
                    rol =>
                        rolIds.Contains(rol.Id) &&
                        rol.Estado &&
                        rol.Activo)
                .ToListAsync(
                    cancellationToken);

        if (roles.Count != rolIds.Count)
        {
            return BadRequest(new
            {
                mensaje =
                    "Uno o más roles seleccionados no existen o están inactivos."
            });
        }

        long usuarioRegistroId =
            ObtenerUsuarioId(
                solicitud.UsuarioRegistroId);

        // -----------------------------------------------------
        // Crear usuario
        // -----------------------------------------------------

        var usuario = new Usuario
        {
            Nombres =
                nombres,

            Apellidos =
                apellidos,

            NumeroDocumento =
                numeroDocumento,

            TipoDocumento =
                tipoDocumento,

            Correo =
                correo,

            Telefono =
                telefono,

            NombreUsuario =
                nombreUsuario,

            InstitucionId =
                solicitud.InstitucionId,

            SedeId =
                solicitud.SedeId,

            AreaId =
                solicitud.AreaId,

            Activo =
                true,

            Estado =
                true,

            DebeCambiarPassword =
                solicitud.DebeCambiarPassword,

            FechaRegistro =
                DateTime.UtcNow,

            UsuarioRegistroId =
                usuarioRegistroId
        };

        // -----------------------------------------------------
        // Generar hash de contraseña
        // -----------------------------------------------------

        usuario.PasswordHash =
            _passwordHasher.HashPassword(
                usuario,
                solicitud.Password);

        await using var transaccion =
            await _dbContext.Database
                .BeginTransactionAsync(
                    cancellationToken);

        try
        {
            _dbContext.Usuarios.Add(
                usuario);

            await _dbContext.SaveChangesAsync(
                cancellationToken);

            // -------------------------------------------------
            // Asignar roles
            // -------------------------------------------------

            foreach (Rol rol in roles)
            {
                var usuarioRol =
                    new UsuarioRol
                    {
                        UsuarioId =
                            usuario.Id,

                        RolId =
                            rol.Id,

                        Activo =
                            true,

                        Estado =
                            true,

                        FechaRegistro =
                            DateTime.UtcNow,

                        UsuarioRegistroId =
                            usuarioRegistroId
                    };

                _dbContext.UsuariosRoles.Add(
                    usuarioRol);
            }

            await _dbContext.SaveChangesAsync(
                cancellationToken);

            await transaccion.CommitAsync(
                cancellationToken);
        }
        catch
        {
            await transaccion.RollbackAsync(
                cancellationToken);

            throw;
        }

        UsuarioResponseDto? resultado =
            await ObtenerUsuarioResponseAsync(
                usuario.Id,
                cancellationToken);

        return CreatedAtAction(
            nameof(ObtenerPorId),
            new
            {
                id = usuario.Id
            },
            resultado);
    }

    // =========================================================
    // PUT: api/Usuarios/{id}
    // =========================================================

    /// <summary>
    /// Actualiza los datos generales del usuario.
    /// </summary>
    [HttpPut("{id:long}")]
    [ProducesResponseType(
        typeof(UsuarioResponseDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] ActualizarUsuarioDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del usuario no es válido."
            });
        }

        Usuario? usuario =
            await _dbContext.Usuarios
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == id &&
                        item.Estado,
                    cancellationToken);

        if (usuario is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el usuario que se desea actualizar."
            });
        }

        string nombres =
            solicitud.Nombres.Trim();

        string apellidos =
            solicitud.Apellidos.Trim();

        string nombreUsuario =
            solicitud.NombreUsuario
                .Trim()
                .ToLowerInvariant();

        string? correo =
            LimpiarCorreo(
                solicitud.Correo);

        string? numeroDocumento =
            LimpiarTextoOpcional(
                solicitud.NumeroDocumento);

        // -----------------------------------------------------
        // Validar usuario duplicado
        // -----------------------------------------------------

        bool nombreUsuarioDuplicado =
            await _dbContext.Usuarios
                .AsNoTracking()
                .AnyAsync(
                    item =>
                        item.Id != id &&
                        item.Estado &&
                        item.NombreUsuario
                            .ToLower() ==
                        nombreUsuario,
                    cancellationToken);

        if (nombreUsuarioDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "El nombre de usuario ya está registrado por otro usuario."
            });
        }

        // -----------------------------------------------------
        // Validar correo duplicado
        // -----------------------------------------------------

        if (!string.IsNullOrWhiteSpace(
                correo))
        {
            bool correoDuplicado =
                await _dbContext.Usuarios
                    .AsNoTracking()
                    .AnyAsync(
                        item =>
                            item.Id != id &&
                            item.Estado &&
                            item.Correo != null &&
                            item.Correo
                                .ToLower() ==
                            correo,
                        cancellationToken);

            if (correoDuplicado)
            {
                return Conflict(new
                {
                    mensaje =
                        "El correo electrónico ya está registrado por otro usuario."
                });
            }
        }

        // -----------------------------------------------------
        // Validar documento duplicado
        // -----------------------------------------------------

        if (!string.IsNullOrWhiteSpace(
                numeroDocumento))
        {
            bool documentoDuplicado =
                await _dbContext.Usuarios
                    .AsNoTracking()
                    .AnyAsync(
                        item =>
                            item.Id != id &&
                            item.Estado &&
                            item.NumeroDocumento !=
                                null &&
                            item.NumeroDocumento ==
                                numeroDocumento,
                        cancellationToken);

            if (documentoDuplicado)
            {
                return Conflict(new
                {
                    mensaje =
                        "El número de documento ya está registrado por otro usuario."
                });
            }
        }

        // -----------------------------------------------------
        // Validar organización
        // -----------------------------------------------------

        IActionResult? validacionOrganizacion =
            await ValidarOrganizacionAsync(
                solicitud.InstitucionId,
                solicitud.SedeId,
                solicitud.AreaId,
                cancellationToken);

        if (validacionOrganizacion is not null)
        {
            return validacionOrganizacion;
        }

        // -----------------------------------------------------
        // Actualizar usuario
        // -----------------------------------------------------

        usuario.Nombres =
            nombres;

        usuario.Apellidos =
            apellidos;

        usuario.NumeroDocumento =
            numeroDocumento;

        usuario.TipoDocumento =
            LimpiarTextoOpcional(
                solicitud.TipoDocumento);

        usuario.Correo =
            correo;

        usuario.Telefono =
            LimpiarTextoOpcional(
                solicitud.Telefono);

        usuario.NombreUsuario =
            nombreUsuario;

        usuario.InstitucionId =
            solicitud.InstitucionId;

        usuario.SedeId =
            solicitud.SedeId;

        usuario.AreaId =
            solicitud.AreaId;

        usuario.Activo =
            solicitud.Activo;

        usuario.FechaActualizacion =
            DateTime.UtcNow;

        usuario.UsuarioActualizacionId =
            ObtenerUsuarioId(
                solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        UsuarioResponseDto? resultado =
            await ObtenerUsuarioResponseAsync(
                usuario.Id,
                cancellationToken);

        return Ok(resultado);
    }

    // =========================================================
    // PUT: api/Usuarios/{id}/password
    // =========================================================

    /// <summary>
    /// Cambia la contraseña de un usuario.
    /// </summary>
    [HttpPut("{id:long}/password")]
    public async Task<IActionResult> CambiarPassword(
        long id,
        [FromBody] CambiarPasswordUsuarioDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del usuario no es válido."
            });
        }

        Usuario? usuario =
            await _dbContext.Usuarios
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == id &&
                        item.Estado,
                    cancellationToken);

        if (usuario is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el usuario solicitado."
            });
        }

        usuario.PasswordHash =
            _passwordHasher.HashPassword(
                usuario,
                solicitud.NuevaPassword);

        usuario.DebeCambiarPassword =
            solicitud.DebeCambiarPassword;

        usuario.FechaActualizacion =
            DateTime.UtcNow;

        usuario.UsuarioActualizacionId =
            ObtenerUsuarioId(
                solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                "Contraseña actualizada correctamente."
        });
    }

    // =========================================================
    // PUT: api/Usuarios/{id}/roles
    // =========================================================

    /// <summary>
    /// Reemplaza los roles asignados al usuario.
    /// </summary>
    [HttpPut("{id:long}/roles")]
    public async Task<IActionResult> ActualizarRoles(
        long id,
        [FromBody] ActualizarRolesUsuarioDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del usuario no es válido."
            });
        }

        bool usuarioExiste =
            await _dbContext.Usuarios
                .AsNoTracking()
                .AnyAsync(
                    usuario =>
                        usuario.Id == id &&
                        usuario.Estado,
                    cancellationToken);

        if (!usuarioExiste)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el usuario solicitado."
            });
        }

        List<long> rolIds =
            solicitud.RolIds
                .Where(rolId =>
                    rolId > 0)
                .Distinct()
                .ToList();

        if (rolIds.Count == 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "Debe seleccionar al menos un rol."
            });
        }

        List<Rol> roles =
            await _dbContext.Roles
                .Where(
                    rol =>
                        rolIds.Contains(rol.Id) &&
                        rol.Estado &&
                        rol.Activo)
                .ToListAsync(
                    cancellationToken);

        if (roles.Count != rolIds.Count)
        {
            return BadRequest(new
            {
                mensaje =
                    "Uno o más roles seleccionados no existen o están inactivos."
            });
        }

        long usuarioActualizacionId =
            ObtenerUsuarioId(
                solicitud.UsuarioActualizacionId);

        DateTime fecha =
            DateTime.UtcNow;

        List<UsuarioRol> relacionesActuales =
            await _dbContext.UsuariosRoles
                .Where(
                    relacion =>
                        relacion.UsuarioId ==
                            id &&
                        relacion.Estado)
                .ToListAsync(
                    cancellationToken);

        // -----------------------------------------------------
        // Desactivar roles actuales
        // -----------------------------------------------------

        foreach (UsuarioRol relacion
            in relacionesActuales)
        {
            relacion.Activo =
                false;

            relacion.Estado =
                false;

            relacion.FechaActualizacion =
                fecha;

            relacion.UsuarioActualizacionId =
                usuarioActualizacionId;
        }

        // -----------------------------------------------------
        // Crear nuevas relaciones
        // -----------------------------------------------------

        foreach (Rol rol in roles)
        {
            var nuevaRelacion =
                new UsuarioRol
                {
                    UsuarioId =
                        id,

                    RolId =
                        rol.Id,

                    Activo =
                        true,

                    Estado =
                        true,

                    FechaRegistro =
                        fecha,

                    UsuarioRegistroId =
                        usuarioActualizacionId
                };

            _dbContext.UsuariosRoles.Add(
                nuevaRelacion);
        }

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        UsuarioResponseDto? resultado =
            await ObtenerUsuarioResponseAsync(
                id,
                cancellationToken);

        return Ok(resultado);
    }

    // =========================================================
    // PATCH: api/Usuarios/{id}/estado
    // =========================================================

    /// <summary>
    /// Activa o desactiva un usuario.
    ///
    /// IMPORTANTE:
    /// Desactivar no elimina al usuario.
    /// Por eso seguirá apareciendo en GET /api/Usuarios.
    /// </summary>
    [HttpPatch("{id:long}/estado")]
    public async Task<IActionResult> CambiarEstado(
        long id,
        [FromBody] CambiarEstadoUsuarioDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del usuario no es válido."
            });
        }

        Usuario? usuario =
            await _dbContext.Usuarios
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == id &&
                        item.Estado,
                    cancellationToken);

        if (usuario is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el usuario solicitado."
            });
        }

        usuario.Activo =
            solicitud.Activo;

        usuario.FechaActualizacion =
            DateTime.UtcNow;

        usuario.UsuarioActualizacionId =
            ObtenerUsuarioId(
                solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                solicitud.Activo
                    ? "Usuario activado correctamente."
                    : "Usuario desactivado correctamente."
        });
    }

    // =========================================================
    // DELETE: api/Usuarios/{id}
    // =========================================================

    /// <summary>
    /// Realiza eliminación lógica del usuario.
    ///
    /// En este caso:
    /// Activo = false
    /// Estado = false
    ///
    /// Por lo tanto ya no aparecerá en GET /api/Usuarios.
    /// </summary>
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Eliminar(
        long id,
        [FromQuery] long? usuarioId,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del usuario no es válido."
            });
        }

        Usuario? usuario =
            await _dbContext.Usuarios
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == id &&
                        item.Estado,
                    cancellationToken);

        if (usuario is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el usuario que se desea eliminar."
            });
        }

        long usuarioActualizacionId =
            ObtenerUsuarioId(
                usuarioId);

        DateTime fecha =
            DateTime.UtcNow;

        usuario.Desactivar();

        usuario.Estado =
            false;

        usuario.FechaActualizacion =
            fecha;

        usuario.UsuarioActualizacionId =
            usuarioActualizacionId;

        // -----------------------------------------------------
        // Desactivar relaciones con roles
        // -----------------------------------------------------

        List<UsuarioRol> relaciones =
            await _dbContext.UsuariosRoles
                .Where(
                    relacion =>
                        relacion.UsuarioId ==
                            id &&
                        relacion.Estado)
                .ToListAsync(
                    cancellationToken);

        foreach (UsuarioRol relacion
            in relaciones)
        {
            relacion.Activo =
                false;

            relacion.Estado =
                false;

            relacion.FechaActualizacion =
                fecha;

            relacion.UsuarioActualizacionId =
                usuarioActualizacionId;
        }

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                "Usuario eliminado correctamente."
        });
    }

    // =========================================================
    // MÉTODOS PRIVADOS
    // =========================================================

    /// <summary>
    /// Obtiene la información completa de un usuario.
    /// Incluye usuarios activos e inactivos mientras Estado=true.
    /// </summary>
    private async Task<UsuarioResponseDto?>
        ObtenerUsuarioResponseAsync(
            long usuarioId,
            CancellationToken cancellationToken)
    {
        return await _dbContext.Usuarios
            .AsNoTracking()
            .Where(
                usuario =>
                    usuario.Id ==
                        usuarioId &&
                    usuario.Estado)
            .Select(
                usuario =>
                    new UsuarioResponseDto
                    {
                        Id =
                            usuario.Id,

                        Nombres =
                            usuario.Nombres,

                        Apellidos =
                            usuario.Apellidos,

                        NombreCompleto =
                            usuario.Nombres +
                            " " +
                            usuario.Apellidos,

                        NumeroDocumento =
                            usuario.NumeroDocumento,

                        TipoDocumento =
                            usuario.TipoDocumento,

                        Correo =
                            usuario.Correo,

                        Telefono =
                            usuario.Telefono,

                        NombreUsuario =
                            usuario.NombreUsuario,

                        DebeCambiarPassword =
                            usuario
                                .DebeCambiarPassword,

                        UltimoAcceso =
                            usuario.UltimoAcceso,

                        InstitucionId =
                            usuario.InstitucionId,

                        SedeId =
                            usuario.SedeId,

                        AreaId =
                            usuario.AreaId,

                        Activo =
                            usuario.Activo,

                        FechaRegistro =
                            usuario.FechaRegistro,

                        FechaActualizacion =
                            usuario
                                .FechaActualizacion,

                        Roles =
                            usuario
                                .UsuariosRoles
                                .Where(
                                    relacion =>
                                        relacion
                                            .Estado &&
                                        relacion
                                            .Activo &&
                                        relacion
                                            .Rol
                                            .Estado &&
                                        relacion
                                            .Rol
                                            .Activo)
                                .OrderBy(
                                    relacion =>
                                        relacion
                                            .Rol
                                            .Nombre)
                                .Select(
                                    relacion =>
                                        new UsuarioRolResponseDto
                                        {
                                            Id =
                                                relacion
                                                    .Rol
                                                    .Id,

                                            Codigo =
                                                relacion
                                                    .Rol
                                                    .Codigo,

                                            Nombre =
                                                relacion
                                                    .Rol
                                                    .Nombre,

                                            EsGlobal =
                                                relacion
                                                    .Rol
                                                    .EsGlobal
                                        })
                                .ToList()
                    })
            .FirstOrDefaultAsync(
                cancellationToken);
    }

    /// <summary>
    /// Valida institución, sede y área.
    /// </summary>
    private async Task<IActionResult?>
        ValidarOrganizacionAsync(
            long institucionId,
            long? sedeId,
            long? areaId,
            CancellationToken cancellationToken)
    {
        // -----------------------------------------------------
        // Institución
        // -----------------------------------------------------

        bool institucionExiste =
            await _dbContext.Instituciones
                .AsNoTracking()
                .AnyAsync(
                    institucion =>
                        institucion.Id ==
                            institucionId &&
                        institucion.Estado &&
                        institucion.Activo,
                    cancellationToken);

        if (!institucionExiste)
        {
            return BadRequest(new
            {
                mensaje =
                    "La institución seleccionada no existe o está inactiva."
            });
        }

        // -----------------------------------------------------
        // Sede
        // -----------------------------------------------------

        if (sedeId.HasValue &&
            sedeId.Value > 0)
        {
            bool sedeExiste =
                await _dbContext.Sedes
                    .AsNoTracking()
                    .AnyAsync(
                        sede =>
                            sede.Id ==
                                sedeId.Value &&
                            sede.InstitucionId ==
                                institucionId &&
                            sede.Estado &&
                            sede.Activo,
                        cancellationToken);

            if (!sedeExiste)
            {
                return BadRequest(new
                {
                    mensaje =
                        "La sede seleccionada no pertenece a la institución o está inactiva."
                });
            }
        }

        // -----------------------------------------------------
        // Área
        // -----------------------------------------------------

        if (areaId.HasValue &&
            areaId.Value > 0)
        {
            bool areaExiste =
                await _dbContext.Areas
                    .AsNoTracking()
                    .AnyAsync(
                        area =>
                            area.Id ==
                                areaId.Value &&
                            area.Estado &&
                            area.Activo,
                        cancellationToken);

            if (!areaExiste)
            {
                return BadRequest(new
                {
                    mensaje =
                        "El área seleccionada no existe o está inactiva."
                });
            }
        }

        return null;
    }

    /// <summary>
    /// Usuario temporal para auditoría.
    /// Posteriormente debe obtenerse desde JWT.
    /// </summary>
    private static long ObtenerUsuarioId(
        long? usuarioId)
    {
        return usuarioId.HasValue &&
               usuarioId.Value > 0
            ? usuarioId.Value
            : 1;
    }

    private static string? LimpiarCorreo(
        string? correo)
    {
        return string.IsNullOrWhiteSpace(
            correo)
            ? null
            : correo
                .Trim()
                .ToLowerInvariant();
    }

    private static string? LimpiarTextoOpcional(
        string? texto)
    {
        return string.IsNullOrWhiteSpace(
            texto)
            ? null
            : texto.Trim();
    }
}

// =============================================================
// DTO: CREAR USUARIO
// =============================================================

public sealed class CrearUsuarioDto
{
    [Required(
        ErrorMessage =
            "Los nombres son obligatorios.")]
    [StringLength(
        100,
        MinimumLength = 2)]
    public string Nombres { get; set; } =
        string.Empty;

    [Required(
        ErrorMessage =
            "Los apellidos son obligatorios.")]
    [StringLength(
        100,
        MinimumLength = 2)]
    public string Apellidos { get; set; } =
        string.Empty;

    [StringLength(20)]
    public string? NumeroDocumento { get; set; }

    [StringLength(20)]
    public string? TipoDocumento { get; set; }

    [EmailAddress(
        ErrorMessage =
            "El correo electrónico no es válido.")]
    [StringLength(150)]
    public string? Correo { get; set; }

    [StringLength(20)]
    public string? Telefono { get; set; }

    [Required(
        ErrorMessage =
            "El nombre de usuario es obligatorio.")]
    [StringLength(
        80,
        MinimumLength = 4)]
    public string NombreUsuario { get; set; } =
        string.Empty;

    [Required(
        ErrorMessage =
            "La contraseña es obligatoria.")]
    [StringLength(
        100,
        MinimumLength = 8,
        ErrorMessage =
            "La contraseña debe tener al menos 8 caracteres.")]
    public string Password { get; set; } =
        string.Empty;

    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar una institución válida.")]
    public long InstitucionId { get; set; }

    public long? SedeId { get; set; }

    public long? AreaId { get; set; }

    public List<long> RolIds { get; set; } =
        new();

    public bool DebeCambiarPassword { get; set; } =
        true;

    public long? UsuarioRegistroId { get; set; }
}

// =============================================================
// DTO: ACTUALIZAR USUARIO
// =============================================================

public sealed class ActualizarUsuarioDto
{
    [Required]
    [StringLength(
        100,
        MinimumLength = 2)]
    public string Nombres { get; set; } =
        string.Empty;

    [Required]
    [StringLength(
        100,
        MinimumLength = 2)]
    public string Apellidos { get; set; } =
        string.Empty;

    [StringLength(20)]
    public string? NumeroDocumento { get; set; }

    [StringLength(20)]
    public string? TipoDocumento { get; set; }

    [EmailAddress]
    [StringLength(150)]
    public string? Correo { get; set; }

    [StringLength(20)]
    public string? Telefono { get; set; }

    [Required]
    [StringLength(
        80,
        MinimumLength = 4)]
    public string NombreUsuario { get; set; } =
        string.Empty;

    [Range(
        1,
        long.MaxValue)]
    public long InstitucionId { get; set; }

    public long? SedeId { get; set; }

    public long? AreaId { get; set; }

    public bool Activo { get; set; } =
        true;

    public long? UsuarioActualizacionId
    {
        get;
        set;
    }
}

// =============================================================
// DTO: CAMBIAR CONTRASEÑA
// =============================================================

public sealed class CambiarPasswordUsuarioDto
{
    [Required]
    [StringLength(
        100,
        MinimumLength = 8,
        ErrorMessage =
            "La contraseña debe tener al menos 8 caracteres.")]
    public string NuevaPassword { get; set; } =
        string.Empty;

    public bool DebeCambiarPassword { get; set; } =
        true;

    public long? UsuarioActualizacionId
    {
        get;
        set;
    }
}

// =============================================================
// DTO: ACTUALIZAR ROLES
// =============================================================

public sealed class ActualizarRolesUsuarioDto
{
    public List<long> RolIds { get; set; } =
        new();

    public long? UsuarioActualizacionId
    {
        get;
        set;
    }
}

// =============================================================
// DTO: CAMBIAR ESTADO
// =============================================================

public sealed class CambiarEstadoUsuarioDto
{
    public bool Activo { get; set; }

    public long? UsuarioActualizacionId
    {
        get;
        set;
    }
}

// =============================================================
// RESPONSE: ROL DEL USUARIO
// =============================================================

public sealed class UsuarioRolResponseDto
{
    public long Id { get; set; }

    public string Codigo { get; set; } =
        string.Empty;

    public string Nombre { get; set; } =
        string.Empty;

    public bool EsGlobal { get; set; }
}

// =============================================================
// RESPONSE: USUARIO
// =============================================================

public sealed class UsuarioResponseDto
{
    public long Id { get; set; }

    public string Nombres { get; set; } =
        string.Empty;

    public string Apellidos { get; set; } =
        string.Empty;

    public string NombreCompleto { get; set; } =
        string.Empty;

    public string? NumeroDocumento { get; set; }

    public string? TipoDocumento { get; set; }

    public string? Correo { get; set; }

    public string? Telefono { get; set; }

    public string NombreUsuario { get; set; } =
        string.Empty;

    public bool DebeCambiarPassword { get; set; }

    public DateTime? UltimoAcceso { get; set; }

    public long InstitucionId { get; set; }

    public long? SedeId { get; set; }

    public long? AreaId { get; set; }

    public bool Activo { get; set; }

    public DateTime FechaRegistro { get; set; }

    public DateTime? FechaActualizacion { get; set; }

    public List<UsuarioRolResponseDto> Roles
    {
        get;
        set;
    } = new();
}