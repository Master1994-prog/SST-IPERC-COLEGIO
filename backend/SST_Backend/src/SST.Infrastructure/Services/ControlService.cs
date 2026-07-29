using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de administrar
/// las medidas de control.
/// </summary>
public class ControlService : IControlService
{
    private readonly SSTDbContext _context;

    public ControlService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene todos los controles registrados.
    /// </summary>
    public async Task<IEnumerable<ControlDto>> GetAllAsync()
    {
        return await _context.Controles
            .AsNoTracking()
            .OrderBy(x => x.Codigo)
            .Select(x => new ControlDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,

                ClasificacionControlId =
                    x.ClasificacionControlId,

                ClasificacionControlNombre =
                    x.ClasificacionControl.Nombre,

                Activo = x.Activo,
                Estado = x.Estado,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion =
                    x.FechaActualizacion
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene un control por su identificador.
    /// </summary>
    public async Task<ControlDto?> GetByIdAsync(long id)
    {
        if (id <= 0)
            return null;

        return await _context.Controles
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new ControlDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,

                ClasificacionControlId =
                    x.ClasificacionControlId,

                ClasificacionControlNombre =
                    x.ClasificacionControl.Nombre,

                Activo = x.Activo,
                Estado = x.Estado,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion =
                    x.FechaActualizacion
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Registra una nueva medida de control.
    /// </summary>
    public async Task<ControlDto> CreateAsync(
        CreateControlDto dto
    )
    {
        string nombre = dto.Nombre.Trim();

        if (string.IsNullOrWhiteSpace(nombre))
        {
            throw new InvalidOperationException(
                "El nombre del control es obligatorio."
            );
        }

        bool existeNombre = await _context.Controles
            .AnyAsync(x =>
                x.Nombre.ToLower() == nombre.ToLower() &&
                x.Estado
            );

        if (existeNombre)
        {
            throw new InvalidOperationException(
                "Ya existe un control con ese nombre."
            );
        }

        ClasificacionControl? clasificacion =
            await _context.ClasificacionesControl
                .AsNoTracking()
                .FirstOrDefaultAsync(x =>
                    x.Id == dto.ClasificacionControlId &&
                    x.Activo &&
                    x.Estado
                );

        if (clasificacion is null)
        {
            throw new InvalidOperationException(
                "La clasificación seleccionada no existe o está inactiva."
            );
        }

        string codigo = await GenerarCodigoAsync();

        Control control = new()
        {
            Codigo = codigo,
            Nombre = nombre,
            Descripcion = NormalizarTexto(
                dto.Descripcion
            ),

            ClasificacionControlId =
                dto.ClasificacionControlId,

            Prioridad = clasificacion.Prioridad,
            Obligatorio = false,

            Activo = dto.Activo,
            Estado = true,

            FechaRegistro = DateTime.UtcNow,
            UsuarioRegistroId =
                dto.UsuarioRegistroId,

            EsGlobal = true
        };

        _context.Controles.Add(control);
        await _context.SaveChangesAsync();

        return new ControlDto
        {
            Id = control.Id,
            Codigo = control.Codigo,
            Nombre = control.Nombre,
            Descripcion = control.Descripcion,

            ClasificacionControlId =
                control.ClasificacionControlId,

            ClasificacionControlNombre =
                clasificacion.Nombre,

            Activo = control.Activo,
            Estado = control.Estado,
            FechaRegistro = control.FechaRegistro,
            FechaActualizacion =
                control.FechaActualizacion
        };
    }

    /// <summary>
    /// Actualiza una medida de control existente.
    /// </summary>
    public async Task<bool> UpdateAsync(
        long id,
        UpdateControlDto dto
    )
    {
        Control? control =
            await _context.Controles
                .FirstOrDefaultAsync(x => x.Id == id);

        if (control is null)
            return false;

        string codigo =
            dto.Codigo.Trim().ToUpperInvariant();

        string nombre =
            dto.Nombre.Trim();

        if (string.IsNullOrWhiteSpace(codigo))
        {
            throw new InvalidOperationException(
                "El código del control es obligatorio."
            );
        }

        if (string.IsNullOrWhiteSpace(nombre))
        {
            throw new InvalidOperationException(
                "El nombre del control es obligatorio."
            );
        }

        bool existeCodigo =
            await _context.Controles.AnyAsync(x =>
                x.Id != id &&
                x.Codigo.ToLower() ==
                    codigo.ToLower() &&
                x.Estado
            );

        if (existeCodigo)
        {
            throw new InvalidOperationException(
                "Ya existe otro control con ese código."
            );
        }

        bool existeNombre =
            await _context.Controles.AnyAsync(x =>
                x.Id != id &&
                x.Nombre.ToLower() ==
                    nombre.ToLower() &&
                x.Estado
            );

        if (existeNombre)
        {
            throw new InvalidOperationException(
                "Ya existe otro control con ese nombre."
            );
        }

        ClasificacionControl? clasificacion =
            await _context.ClasificacionesControl
                .AsNoTracking()
                .FirstOrDefaultAsync(x =>
                    x.Id ==
                        dto.ClasificacionControlId &&
                    x.Activo &&
                    x.Estado
                );

        if (clasificacion is null)
        {
            throw new InvalidOperationException(
                "La clasificación seleccionada no existe o está inactiva."
            );
        }

        control.Codigo = codigo;
        control.Nombre = nombre;
        control.Descripcion =
            NormalizarTexto(dto.Descripcion);

        control.ClasificacionControlId =
            dto.ClasificacionControlId;

        /*
         * La prioridad del control adopta la prioridad
         * definida en la clasificación seleccionada.
         */
        control.Prioridad =
            clasificacion.Prioridad;

        control.Activo = dto.Activo;

        control.FechaActualizacion =
            DateTime.UtcNow;

        control.UsuarioActualizacionId =
            dto.UsuarioActualizacionId;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Desactiva lógicamente un control.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        Control? control =
            await _context.Controles
                .FirstOrDefaultAsync(x => x.Id == id);

        if (control is null)
            return false;

        control.Activo = false;
        control.Estado = false;
        control.FechaActualizacion =
            DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Genera códigos consecutivos:
    /// CTRL-0001, CTRL-0002, etc.
    /// </summary>
    private async Task<string> GenerarCodigoAsync()
    {
        long ultimoId = await _context.Controles
            .AsNoTracking()
            .MaxAsync(x => (long?)x.Id) ?? 0;

        long numero = ultimoId + 1;

        string codigo;

        do
        {
            codigo = $"CTRL-{numero:D4}";
            numero++;
        }
        while (await _context.Controles.AnyAsync(
            x => x.Codigo == codigo
        ));

        return codigo;
    }

    /// <summary>
    /// Elimina espacios y convierte textos vacíos
    /// en null.
    /// </summary>
    private static string? NormalizarTexto(
        string? valor
    )
    {
        string texto = valor?.Trim() ?? string.Empty;

        return string.IsNullOrWhiteSpace(texto)
            ? null
            : texto;
    }
}
