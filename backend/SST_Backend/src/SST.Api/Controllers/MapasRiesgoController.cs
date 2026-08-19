using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para gestionar mapas de riesgo.
/// </summary>
[ApiController]
[Route("api/mapas-riesgo")]
[Authorize]
public class MapasRiesgoController : ControllerBase
{
    private const long MaximoBytes = 10 * 1024 * 1024;

    private static readonly HashSet<string> ExtensionesPermitidas =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        };

    private readonly IMapaRiesgoService _mapaRiesgoService;
    private readonly IWebHostEnvironment _environment;

    public MapasRiesgoController(
        IMapaRiesgoService mapaRiesgoService,
        IWebHostEnvironment environment)
    {
        _mapaRiesgoService = mapaRiesgoService;
        _environment = environment;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var mapas = await _mapaRiesgoService.GetAllAsync();

        return Ok(mapas);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        var mapa = await _mapaRiesgoService.GetByIdAsync(id);

        if (mapa is null)
        {
            return NotFound(
                new { mensaje = "Mapa de riesgo no encontrado." });
        }

        return Ok(mapa);
    }

    [HttpGet("matriz/{matrizIPERCId:long}")]
    public async Task<IActionResult> GetByMatrizId(
        long matrizIPERCId)
    {
        var mapas = await _mapaRiesgoService
            .GetByMatrizIdAsync(matrizIPERCId);

        return Ok(mapas);
    }

    /// <summary>
    /// Sube el plano del mapa de riesgo al servidor.
    ///
    /// Formato esperado:
    /// multipart/form-data
    /// campo: archivo
    ///
    /// Devuelve:
    /// {
    ///   "archivoUrl": "/uploads/mapas-riesgo/....png",
    ///   "tipoArchivo": "image/png"
    /// }
    /// </summary>
    [HttpPost("upload-plano")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaximoBytes)]
    [Authorize(
        Roles =
            "SUPER_ADMIN,ADMIN,COORDINADOR,SUP_TITULAR,SUP_SUPLENTE")]
    public async Task<IActionResult> UploadPlano(
        IFormFile archivo)
    {
        if (archivo is null || archivo.Length == 0)
        {
            return BadRequest(
                new { mensaje = "Debe seleccionar una imagen." });
        }

        if (archivo.Length > MaximoBytes)
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "La imagen no puede superar los 10 MB."
                });
        }

        var extension = Path
            .GetExtension(archivo.FileName)
            .ToLowerInvariant();

        if (!ExtensionesPermitidas.Contains(extension))
        {
            return BadRequest(
                new
                {
                    mensaje =
                        "Formato no permitido. Use JPG, JPEG, PNG o WEBP."
                });
        }

        var webRoot = _environment.WebRootPath;

        if (string.IsNullOrWhiteSpace(webRoot))
        {
            webRoot = Path.Combine(
                _environment.ContentRootPath,
                "wwwroot");
        }

        var carpeta = Path.Combine(
            webRoot,
            "uploads",
            "mapas-riesgo");

        Directory.CreateDirectory(carpeta);

        var nombreSeguro =
            $"{Guid.NewGuid():N}{extension}";

        var rutaFisica = Path.Combine(
            carpeta,
            nombreSeguro);

        await using (var stream =
            new FileStream(
                rutaFisica,
                FileMode.Create,
                FileAccess.Write,
                FileShare.None))
        {
            await archivo.CopyToAsync(stream);
        }

        var archivoUrl =
            $"/uploads/mapas-riesgo/{nombreSeguro}";

        var tipoArchivo =
            string.IsNullOrWhiteSpace(archivo.ContentType)
                ? ObtenerTipoMime(extension)
                : archivo.ContentType;

        return Ok(
            new
            {
                archivoUrl,
                tipoArchivo
            });
    }

    [HttpPost]
    [Authorize(
        Roles =
            "SUPER_ADMIN,ADMIN,COORDINADOR,SUP_TITULAR,SUP_SUPLENTE")]
    public async Task<IActionResult> Create(
        [FromBody] CreateMapaRiesgoDto dto)
    {
        try
        {
            var mapa =
                await _mapaRiesgoService.CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new { id = mapa.Id },
                mapa);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(
                new { mensaje = ex.Message });
        }
    }

    [HttpPut("{id:long}")]
    [Authorize(
        Roles =
            "SUPER_ADMIN,ADMIN,COORDINADOR,SUP_TITULAR,SUP_SUPLENTE")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateMapaRiesgoDto dto)
    {
        try
        {
            var actualizado =
                await _mapaRiesgoService.UpdateAsync(
                    id,
                    dto);

            if (!actualizado)
            {
                return NotFound(
                    new
                    {
                        mensaje =
                            "Mapa de riesgo no encontrado."
                    });
            }

            return Ok(
                new
                {
                    mensaje =
                        "Mapa de riesgo actualizado correctamente."
                });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(
                new { mensaje = ex.Message });
        }
    }

    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public async Task<IActionResult> Delete(long id)
    {
        var eliminado =
            await _mapaRiesgoService.DeleteAsync(id);

        if (!eliminado)
        {
            return NotFound(
                new
                {
                    mensaje =
                        "Mapa de riesgo no encontrado."
                });
        }

        return Ok(
            new
            {
                mensaje =
                    "Mapa de riesgo cerrado correctamente."
            });
    }

    private static string ObtenerTipoMime(
        string extension)
    {
        return extension.ToLowerInvariant() switch
        {
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".jpg" or ".jpeg" => "image/jpeg",
            _ => "application/octet-stream"
        };
    }
}
