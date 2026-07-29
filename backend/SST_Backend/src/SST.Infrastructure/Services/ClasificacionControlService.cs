using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Implementa las operaciones del catálogo
/// Clasificaciones de Control.
/// </summary>
public class ClasificacionControlService
    : IClasificacionControlService
{
    private readonly SSTDbContext _context;

    /// <summary>
    /// Constructor del servicio.
    /// </summary>
    public ClasificacionControlService(
        SSTDbContext context
    )
    {
        _context = context;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ClasificacionControl>>
        ObtenerTodosAsync(
            CancellationToken cancellationToken = default
        )
    {
        return await _context.ClasificacionesControl
            .AsNoTracking()
            .OrderBy(
                clasificacion =>
                    clasificacion.Prioridad
            )
            .ThenBy(
                clasificacion =>
                    clasificacion.Nombre
            )
            .ToListAsync(cancellationToken);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ClasificacionControl>>
        ObtenerActivosAsync(
            CancellationToken cancellationToken = default
        )
    {
        return await _context.ClasificacionesControl
            .AsNoTracking()
            .Where(
                clasificacion =>
                    clasificacion.Activo &&
                    clasificacion.Estado
            )
            .OrderBy(
                clasificacion =>
                    clasificacion.Prioridad
            )
            .ThenBy(
                clasificacion =>
                    clasificacion.Nombre
            )
            .ToListAsync(cancellationToken);
    }

    /// <inheritdoc />
    public async Task<ClasificacionControl?>
        ObtenerPorIdAsync(
            long id,
            CancellationToken cancellationToken = default
        )
    {
        if (id <= 0)
        {
            return null;
        }

        return await _context.ClasificacionesControl
            .AsNoTracking()
            .FirstOrDefaultAsync(
                clasificacion =>
                    clasificacion.Id == id,
                cancellationToken
            );
    }

    /// <inheritdoc />
    public async Task<ClasificacionControl>
        CrearAsync(
            CreateClasificacionControlDto dto,
            CancellationToken cancellationToken = default
        )
    {
        ArgumentNullException.ThrowIfNull(dto);

        var codigo = NormalizarCodigo(dto.Codigo);
        var nombre = NormalizarTexto(dto.Nombre);
        var descripcion =
            NormalizarTextoNullable(dto.Descripcion);

        ValidarDatos(
            codigo,
            nombre,
            descripcion,
            dto.Prioridad
        );

        var codigoExiste =
            await _context.ClasificacionesControl
                .AnyAsync(
                    clasificacion =>
                        clasificacion.Codigo
                            .ToUpper() == codigo,
                    cancellationToken
                );

        if (codigoExiste)
        {
            throw new InvalidOperationException(
                $"Ya existe una clasificación con el código {codigo}."
            );
        }

        var nombreExiste =
            await _context.ClasificacionesControl
                .AnyAsync(
                    clasificacion =>
                        clasificacion.Nombre
                            .ToUpper() ==
                        nombre.ToUpper(),
                    cancellationToken
                );

        if (nombreExiste)
        {
            throw new InvalidOperationException(
                $"Ya existe una clasificación con el nombre {nombre}."
            );
        }

        var clasificacion =
            new ClasificacionControl
            {
                Codigo = codigo,
                Nombre = nombre,
                Descripcion = descripcion,
                Prioridad = dto.Prioridad,
                Activo = dto.Activo,
                Estado = true,
                FechaRegistro = DateTime.UtcNow,

                // Se reemplazará posteriormente
                // por el usuario autenticado.
                UsuarioRegistroId = 1
            };

        await _context.ClasificacionesControl.AddAsync(
            clasificacion,
            cancellationToken
        );

        await _context.SaveChangesAsync(
            cancellationToken
        );

        return clasificacion;
    }

    /// <inheritdoc />
    public async Task<bool> ActualizarAsync(
        long id,
        UpdateClasificacionControlDto dto,
        CancellationToken cancellationToken = default
    )
    {
        if (id <= 0)
        {
            throw new ArgumentException(
                "El identificador no es válido.",
                nameof(id)
            );
        }

        ArgumentNullException.ThrowIfNull(dto);

        var clasificacion =
            await _context.ClasificacionesControl
                .FirstOrDefaultAsync(
                    elemento =>
                        elemento.Id == id,
                    cancellationToken
                );

        if (clasificacion is null)
        {
            return false;
        }

        var codigo = NormalizarCodigo(dto.Codigo);
        var nombre = NormalizarTexto(dto.Nombre);
        var descripcion =
            NormalizarTextoNullable(dto.Descripcion);

        ValidarDatos(
            codigo,
            nombre,
            descripcion,
            dto.Prioridad
        );

        var codigoExiste =
            await _context.ClasificacionesControl
                .AnyAsync(
                    elemento =>
                        elemento.Id != id &&
                        elemento.Codigo.ToUpper() ==
                        codigo,
                    cancellationToken
                );

        if (codigoExiste)
        {
            throw new InvalidOperationException(
                $"Ya existe otra clasificación con el código {codigo}."
            );
        }

        var nombreExiste =
            await _context.ClasificacionesControl
                .AnyAsync(
                    elemento =>
                        elemento.Id != id &&
                        elemento.Nombre.ToUpper() ==
                        nombre.ToUpper(),
                    cancellationToken
                );

        if (nombreExiste)
        {
            throw new InvalidOperationException(
                $"Ya existe otra clasificación con el nombre {nombre}."
            );
        }

        clasificacion.Codigo = codigo;
        clasificacion.Nombre = nombre;
        clasificacion.Descripcion = descripcion;
        clasificacion.Prioridad = dto.Prioridad;
        clasificacion.Activo = dto.Activo;
        clasificacion.FechaActualizacion =
            DateTime.UtcNow;

        // Se reemplazará posteriormente
        // por el usuario autenticado.
        clasificacion.UsuarioActualizacionId = 1;

        await _context.SaveChangesAsync(
            cancellationToken
        );

        return true;
    }

    /// <inheritdoc />
    public async Task<bool> EliminarAsync(
        long id,
        CancellationToken cancellationToken = default
    )
    {
        if (id <= 0)
        {
            throw new ArgumentException(
                "El identificador no es válido.",
                nameof(id)
            );
        }

        var clasificacion =
            await _context.ClasificacionesControl
                .FirstOrDefaultAsync(
                    elemento =>
                        elemento.Id == id,
                    cancellationToken
                );

        if (clasificacion is null)
        {
            return false;
        }

        /*
         * Si la clasificación ya está relacionada
         * con controles, se realiza una desactivación
         * lógica para conservar la integridad histórica.
         */
        var tieneControles =
            await _context.Controles
                .AnyAsync(
                    control =>
                        control.ClasificacionControlId ==
                        id,
                    cancellationToken
                );

        if (tieneControles)
        {
            clasificacion.Activo = false;
            clasificacion.Estado = false;
            clasificacion.FechaActualizacion =
                DateTime.UtcNow;
            clasificacion.UsuarioActualizacionId = 1;
        }
        else
        {
            _context.ClasificacionesControl.Remove(
                clasificacion
            );
        }

        await _context.SaveChangesAsync(
            cancellationToken
        );

        return true;
    }

    /// <summary>
    /// Valida los campos principales.
    /// </summary>
    private static void ValidarDatos(
        string codigo,
        string nombre,
        string? descripcion,
        int prioridad
    )
    {
        if (string.IsNullOrWhiteSpace(codigo))
        {
            throw new ArgumentException(
                "El código es obligatorio."
            );
        }

        if (codigo.Length > 20)
        {
            throw new ArgumentException(
                "El código no puede superar los 20 caracteres."
            );
        }

        if (string.IsNullOrWhiteSpace(nombre))
        {
            throw new ArgumentException(
                "El nombre es obligatorio."
            );
        }

        if (nombre.Length > 150)
        {
            throw new ArgumentException(
                "El nombre no puede superar los 150 caracteres."
            );
        }

        if (descripcion?.Length > 1000)
        {
            throw new ArgumentException(
                "La descripción no puede superar los 1000 caracteres."
            );
        }

        if (prioridad < 0)
        {
            throw new ArgumentException(
                "La prioridad no puede ser negativa."
            );
        }
    }

    /// <summary>
    /// Normaliza un código.
    /// </summary>
    private static string NormalizarCodigo(
        string codigo
    )
    {
        return codigo
            .Trim()
            .ToUpperInvariant();
    }

    /// <summary>
    /// Normaliza un texto obligatorio.
    /// </summary>
    private static string NormalizarTexto(
        string texto
    )
    {
        return texto.Trim();
    }

    /// <summary>
    /// Normaliza un texto opcional.
    /// </summary>
    private static string? NormalizarTextoNullable(
        string? texto
    )
    {
        if (string.IsNullOrWhiteSpace(texto))
        {
            return null;
        }

        return texto.Trim();
    }
}
