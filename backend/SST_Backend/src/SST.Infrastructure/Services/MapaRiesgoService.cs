using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.IPERC.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar mapas de riesgo.
/// </summary>
public class MapaRiesgoService : IMapaRiesgoService
{
    private readonly SSTDbContext _context;

    public MapaRiesgoService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Genera automáticamente:
    /// MAP-AAAA-0001.
    /// </summary>
    private async Task<string> GenerarCodigoAsync()
    {
        var anio = DateTime.Now.Year;
        var prefijo = $"MAP-{anio}-";

        var ultimoCodigo = await _context.Set<MapaRiesgo>()
            .AsNoTracking()
            .Where(x => x.Codigo.StartsWith(prefijo))
            .OrderByDescending(x => x.Codigo)
            .Select(x => x.Codigo)
            .FirstOrDefaultAsync();

        var correlativo = 1;

        if (!string.IsNullOrWhiteSpace(ultimoCodigo))
        {
            var numeroTexto = ultimoCodigo.Replace(prefijo, "");

            if (int.TryParse(numeroTexto, out var ultimoNumero))
            {
                correlativo = ultimoNumero + 1;
            }
        }

        return $"{prefijo}{correlativo:D4}";
    }

    private static MapaRiesgoDto ToDto(
        MapaRiesgo mapa,
        string? codigoMatriz)
    {
        return new MapaRiesgoDto
        {
            Id = mapa.Id,
            Codigo = mapa.Codigo,
            Nombre = mapa.Nombre,
            Descripcion = mapa.Descripcion,
            Ubicacion = mapa.Ubicacion,
            ArchivoUrl = mapa.ArchivoUrl,
            TipoArchivo = mapa.TipoArchivo,
            MarcadoresJson = mapa.MarcadoresJson,
            FechaElaboracion = mapa.FechaElaboracion,
            FechaRevision = mapa.FechaRevision,
            Version = mapa.Version,
            EstadoMapa = mapa.EstadoMapa,
            Activo = mapa.Activo,
            MatrizIPERCId = mapa.MatrizIPERCId,
            MatrizIPERCCodigo = codigoMatriz
        };
    }

    public async Task<IEnumerable<MapaRiesgoDto>> GetAllAsync()
    {
        return await _context.Set<MapaRiesgo>()
            .AsNoTracking()
            .Include(x => x.MatrizIPERC)
            .Where(x => x.Activo)
            .Select(x => new MapaRiesgoDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Ubicacion = x.Ubicacion,
                ArchivoUrl = x.ArchivoUrl,
                TipoArchivo = x.TipoArchivo,
                MarcadoresJson = x.MarcadoresJson,
                FechaElaboracion = x.FechaElaboracion,
                FechaRevision = x.FechaRevision,
                Version = x.Version,
                EstadoMapa = x.EstadoMapa,
                Activo = x.Activo,
                MatrizIPERCId = x.MatrizIPERCId,
                MatrizIPERCCodigo = x.MatrizIPERC.Codigo
            })
            .ToListAsync();
    }

    public async Task<MapaRiesgoDto?> GetByIdAsync(long id)
    {
        return await _context.Set<MapaRiesgo>()
            .AsNoTracking()
            .Include(x => x.MatrizIPERC)
            .Where(x => x.Id == id)
            .Select(x => new MapaRiesgoDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Ubicacion = x.Ubicacion,
                ArchivoUrl = x.ArchivoUrl,
                TipoArchivo = x.TipoArchivo,
                MarcadoresJson = x.MarcadoresJson,
                FechaElaboracion = x.FechaElaboracion,
                FechaRevision = x.FechaRevision,
                Version = x.Version,
                EstadoMapa = x.EstadoMapa,
                Activo = x.Activo,
                MatrizIPERCId = x.MatrizIPERCId,
                MatrizIPERCCodigo = x.MatrizIPERC.Codigo
            })
            .FirstOrDefaultAsync();
    }

    public async Task<IEnumerable<MapaRiesgoDto>> GetByMatrizIdAsync(
        long matrizIPERCId)
    {
        return await _context.Set<MapaRiesgo>()
            .AsNoTracking()
            .Include(x => x.MatrizIPERC)
            .Where(x =>
                x.MatrizIPERCId == matrizIPERCId &&
                x.Activo)
            .Select(x => new MapaRiesgoDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Ubicacion = x.Ubicacion,
                ArchivoUrl = x.ArchivoUrl,
                TipoArchivo = x.TipoArchivo,
                MarcadoresJson = x.MarcadoresJson,
                FechaElaboracion = x.FechaElaboracion,
                FechaRevision = x.FechaRevision,
                Version = x.Version,
                EstadoMapa = x.EstadoMapa,
                Activo = x.Activo,
                MatrizIPERCId = x.MatrizIPERCId,
                MatrizIPERCCodigo = x.MatrizIPERC.Codigo
            })
            .ToListAsync();
    }

    public async Task<MapaRiesgoDto> CreateAsync(
        CreateMapaRiesgoDto dto)
    {
        var matriz = await _context.Set<MatrizIPERC>()
            .FirstOrDefaultAsync(x =>
                x.Id == dto.MatrizIPERCId);

        if (matriz is null)
        {
            throw new InvalidOperationException(
                "La Matriz IPERC seleccionada no existe.");
        }

        var codigoGenerado = await GenerarCodigoAsync();

        var mapa = new MapaRiesgo
        {
            Codigo = codigoGenerado,
            Nombre = dto.Nombre.Trim(),
            Descripcion = dto.Descripcion?.Trim(),
            Ubicacion = dto.Ubicacion?.Trim(),
            ArchivoUrl = dto.ArchivoUrl?.Trim(),
            TipoArchivo = dto.TipoArchivo?.Trim(),
            MarcadoresJson = dto.MarcadoresJson,
            FechaElaboracion = dto.FechaElaboracion,
            FechaRevision = dto.FechaRevision,
            Version = dto.Version <= 0 ? 1 : dto.Version,
            EstadoMapa = string.IsNullOrWhiteSpace(dto.EstadoMapa)
                ? "Borrador"
                : dto.EstadoMapa.Trim(),
            Activo = true,
            MatrizIPERCId = dto.MatrizIPERCId
        };

        _context.Set<MapaRiesgo>().Add(mapa);

        await _context.SaveChangesAsync();

        return ToDto(mapa, matriz.Codigo);
    }

    public async Task<bool> UpdateAsync(
        long id,
        UpdateMapaRiesgoDto dto)
    {
        var mapa = await _context.Set<MapaRiesgo>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (mapa is null)
        {
            return false;
        }

        var matrizExiste = await _context.Set<MatrizIPERC>()
            .AnyAsync(x => x.Id == dto.MatrizIPERCId);

        if (!matrizExiste)
        {
            throw new InvalidOperationException(
                "La Matriz IPERC seleccionada no existe.");
        }

        mapa.Nombre = dto.Nombre.Trim();
        mapa.Descripcion = dto.Descripcion?.Trim();
        mapa.Ubicacion = dto.Ubicacion?.Trim();
        mapa.ArchivoUrl = dto.ArchivoUrl?.Trim();
        mapa.TipoArchivo = dto.TipoArchivo?.Trim();
        mapa.MarcadoresJson = dto.MarcadoresJson;
        mapa.FechaElaboracion = dto.FechaElaboracion;
        mapa.FechaRevision = dto.FechaRevision;
        mapa.Version = dto.Version <= 0 ? 1 : dto.Version;
        mapa.EstadoMapa =
            string.IsNullOrWhiteSpace(dto.EstadoMapa)
                ? "Borrador"
                : dto.EstadoMapa.Trim();
        mapa.Activo = dto.Activo;
        mapa.MatrizIPERCId = dto.MatrizIPERCId;
        mapa.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(long id)
    {
        var mapa = await _context.Set<MapaRiesgo>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (mapa is null)
        {
            return false;
        }

        mapa.Activo = false;
        mapa.EstadoMapa = "Cerrado";
        mapa.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
