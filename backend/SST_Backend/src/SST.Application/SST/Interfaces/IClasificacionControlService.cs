using SST.Application.SST.Dtos;
using SST.Domain.SST.Entities;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Define las operaciones disponibles para administrar
/// las clasificaciones de control.
/// </summary>
public interface IClasificacionControlService
{
    /// <summary>
    /// Obtiene todas las clasificaciones registradas.
    /// </summary>
    Task<IReadOnlyList<ClasificacionControl>> ObtenerTodosAsync(
        CancellationToken cancellationToken = default
    );

    /// <summary>
    /// Obtiene únicamente las clasificaciones activas.
    /// </summary>
    Task<IReadOnlyList<ClasificacionControl>> ObtenerActivosAsync(
        CancellationToken cancellationToken = default
    );

    /// <summary>
    /// Obtiene una clasificación mediante su identificador.
    /// </summary>
    Task<ClasificacionControl?> ObtenerPorIdAsync(
        long id,
        CancellationToken cancellationToken = default
    );

    /// <summary>
    /// Registra una nueva clasificación.
    /// </summary>
    Task<ClasificacionControl> CrearAsync(
        CreateClasificacionControlDto dto,
        CancellationToken cancellationToken = default
    );

    /// <summary>
    /// Actualiza una clasificación existente.
    /// </summary>
    Task<bool> ActualizarAsync(
        long id,
        UpdateClasificacionControlDto dto,
        CancellationToken cancellationToken = default
    );

    /// <summary>
    /// Elimina o desactiva una clasificación.
    /// </summary>
    Task<bool> EliminarAsync(
        long id,
        CancellationToken cancellationToken = default
    );
}