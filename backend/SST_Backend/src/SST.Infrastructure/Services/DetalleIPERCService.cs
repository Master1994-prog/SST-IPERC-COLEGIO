using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.IPERC.Entities;
using SST.Domain.IPERC.Enums;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar los detalles
/// de una Matriz IPERC.
///
/// La evaluación del riesgo se genera automáticamente:
///
/// Riesgo = Probabilidad x Severidad
///
/// El NivelRiesgo se obtiene utilizando los rangos
/// configurados en la tabla NivelesRiesgo.
/// </summary>
public class DetalleIPERCService : IDetalleIPERCService
{
    private readonly SSTDbContext _context;

    // ============================================================
    // PROYECCIÓN
    // ============================================================

    /// <summary>
    /// Proyección común para devolver la información
    /// completa de un detalle IPERC.
    /// </summary>
    private static readonly Expression<
        Func<DetalleIPERC, DetalleIPERCDto>>
        ProyectarDetalle =
            x => new DetalleIPERCDto
            {
                Id = x.Id,

                MatrizIPERCId =
                    x.MatrizIPERCId,

                MatrizIPERCCodigo =
                    x.MatrizIPERC.Codigo,

                Item =
                    x.Item,

                Tarea =
                    x.Tarea,

                PeligroId =
                    x.PeligroId,

                PeligroNombre =
                    x.Peligro.Nombre,

                ConsecuenciaId =
                    x.ConsecuenciaId,

                ConsecuenciaNombre =
                    x.Consecuencia.Nombre,

                DescripcionPeligro =
                    x.DescripcionPeligro,

                // =================================================
                // EVALUACIÓN INICIAL
                // =================================================

                EvaluacionInicialId =
                    x.EvaluacionInicialId,

                EvaluacionInicial =
                    new EvaluacionDetalleIPERCDto
                    {
                        Id =
                            x.EvaluacionInicial.Id,

                        ProbabilidadId =
                            x.EvaluacionInicial
                                .ProbabilidadId,

                        ProbabilidadNombre =
                            x.EvaluacionInicial
                                .Probabilidad
                                .Nombre,

                        ValorProbabilidad =
                            x.EvaluacionInicial
                                .Probabilidad
                                .Valor,

                        SeveridadId =
                            x.EvaluacionInicial
                                .SeveridadId,

                        SeveridadNombre =
                            x.EvaluacionInicial
                                .Severidad
                                .Nombre,

                        ValorSeveridad =
                            x.EvaluacionInicial
                                .Severidad
                                .Valor,

                        NivelRiesgoId =
                            x.EvaluacionInicial
                                .NivelRiesgoId,

                        NivelRiesgoNombre =
                            x.EvaluacionInicial
                                .NivelRiesgo
                                .Nombre,

                        Color =
                            x.EvaluacionInicial
                                .NivelRiesgo
                                .Color,

                        ValorRiesgo =
                            x.EvaluacionInicial
                                .Valor,

                        EsAceptable =
                            x.EvaluacionInicial
                                .EsAceptable,

                        RequiereAccion =
                            x.EvaluacionInicial
                                .RequiereAccion,

                        Observaciones =
                            x.EvaluacionInicial
                                .Observaciones
                    },

                // =================================================
                // EVALUACIÓN RESIDUAL
                // =================================================

                EvaluacionResidualId =
                    x.EvaluacionResidualId,

                EvaluacionResidual =
                    x.EvaluacionResidual == null
                        ? null
                        : new EvaluacionDetalleIPERCDto
                        {
                            Id =
                                x.EvaluacionResidual
                                    .Id,

                            ProbabilidadId =
                                x.EvaluacionResidual
                                    .ProbabilidadId,

                            ProbabilidadNombre =
                                x.EvaluacionResidual
                                    .Probabilidad
                                    .Nombre,

                            ValorProbabilidad =
                                x.EvaluacionResidual
                                    .Probabilidad
                                    .Valor,

                            SeveridadId =
                                x.EvaluacionResidual
                                    .SeveridadId,

                            SeveridadNombre =
                                x.EvaluacionResidual
                                    .Severidad
                                    .Nombre,

                            ValorSeveridad =
                                x.EvaluacionResidual
                                    .Severidad
                                    .Valor,

                            NivelRiesgoId =
                                x.EvaluacionResidual
                                    .NivelRiesgoId,

                            NivelRiesgoNombre =
                                x.EvaluacionResidual
                                    .NivelRiesgo
                                    .Nombre,

                            Color =
                                x.EvaluacionResidual
                                    .NivelRiesgo
                                    .Color,

                            ValorRiesgo =
                                x.EvaluacionResidual
                                    .Valor,

                            EsAceptable =
                                x.EvaluacionResidual
                                    .EsAceptable,

                            RequiereAccion =
                                x.EvaluacionResidual
                                    .RequiereAccion,

                            Observaciones =
                                x.EvaluacionResidual
                                    .Observaciones
                        },

                // =================================================
                // CONTROLES
                // =================================================

                ControlIds =
                    x.Controles
                        .Select(
                            c => c.ControlId)
                        .ToList(),

                // =================================================
                // EPP
                // =================================================

                EquipoProteccionIds =
                    x.EquiposProteccion
                        .Select(
                            e =>
                                e.EquipoProteccionId)
                        .ToList(),

                // =================================================
                // IMPLEMENTACIÓN
                // =================================================

                ResponsableImplementacionId =
                    x.ResponsableImplementacionId,

                FechaCompromiso =
                    x.FechaCompromiso,

                FechaImplementacion =
                    x.FechaImplementacion,

                EstadoImplementacionId =
                    (int)x.EstadoImplementacion,

                EstadoImplementacionNombre =
                    x.EstadoImplementacion
                        .ToString()
            };

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    public DetalleIPERCService(
        SSTDbContext context)
    {
        _context = context;
    }

    // ============================================================
    // GET ALL
    // ============================================================

    public async Task<IEnumerable<DetalleIPERCDto>>
        GetAllAsync()
    {
        return await _context
            .Set<DetalleIPERC>()
            .AsNoTracking()
            .OrderBy(
                x => x.MatrizIPERCId)
            .ThenBy(
                x => x.Item)
            .Select(
                ProyectarDetalle)
            .ToListAsync();
    }

    // ============================================================
    // GET BY ID
    // ============================================================

    public async Task<DetalleIPERCDto?>
        GetByIdAsync(
            long id)
    {
        return await _context
            .Set<DetalleIPERC>()
            .AsNoTracking()
            .Where(
                x =>
                    x.Id == id)
            .Select(
                ProyectarDetalle)
            .FirstOrDefaultAsync();
    }

    // ============================================================
    // GET BY MATRIZ
    // ============================================================

    public async Task<IEnumerable<DetalleIPERCDto>>
        GetByMatrizIdAsync(
            long matrizIPERCId)
    {
        return await _context
            .Set<DetalleIPERC>()
            .AsNoTracking()
            .Where(
                x =>
                    x.MatrizIPERCId ==
                    matrizIPERCId)
            .OrderBy(
                x => x.Item)
            .Select(
                ProyectarDetalle)
            .ToListAsync();
    }

    // ============================================================
    // CREATE
    // ============================================================

    /// <summary>
    /// Registra un nuevo detalle IPERC.
    ///
    /// También crea automáticamente:
    ///
    /// - Evaluación inicial.
    /// - Evaluación residual, cuando corresponde.
    /// - Relaciones con controles.
    /// - Relaciones con EPP.
    /// </summary>
    public async Task<DetalleIPERCDto>
        CreateAsync(
            CreateDetalleIPERCDto dto)
    {
        // --------------------------------------------------------
        // VALIDAR MATRIZ
        // --------------------------------------------------------

        MatrizIPERC? matriz =
            await _context
                .Set<MatrizIPERC>()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id ==
                        dto.MatrizIPERCId &&
                        x.Estado);

        if (matriz is null)
        {
            throw new InvalidOperationException(
                "La Matriz IPERC seleccionada no existe o está inactiva.");
        }

        // --------------------------------------------------------
        // VALIDAR TAREA
        // --------------------------------------------------------

        string tarea =
            dto.Tarea.Trim();

        if (string.IsNullOrWhiteSpace(
                tarea))
        {
            throw new InvalidOperationException(
                "La tarea es obligatoria.");
        }

        // --------------------------------------------------------
        // VALIDAR PELIGRO
        // --------------------------------------------------------

        bool peligroExiste =
            await _context.Peligros
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        dto.PeligroId &&
                        x.Activo);

        if (!peligroExiste)
        {
            throw new InvalidOperationException(
                "El peligro seleccionado no existe o está inactivo.");
        }

        // --------------------------------------------------------
        // VALIDAR CONSECUENCIA
        // --------------------------------------------------------

        bool consecuenciaExiste =
            await _context.Consecuencias
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        dto.ConsecuenciaId &&
                        x.Activo);

        if (!consecuenciaExiste)
        {
            throw new InvalidOperationException(
                "La consecuencia seleccionada no existe o está inactiva.");
        }

        // --------------------------------------------------------
        // RESPONSABLE
        // --------------------------------------------------------

        await ValidarResponsableAsync(
            dto.ResponsableImplementacionId);

        // --------------------------------------------------------
        // ESTADO IMPLEMENTACIÓN
        // --------------------------------------------------------

        ValidarEstadoImplementacion(
            dto.EstadoImplementacion);

        // --------------------------------------------------------
        // CONTROLES
        // --------------------------------------------------------

        List<long> controlIds =
            NormalizarIds(
                dto.ControlIds);

        await ValidarControlesAsync(
            controlIds);

        // --------------------------------------------------------
        // EPP
        // --------------------------------------------------------

        List<long> equipoProteccionIds =
            NormalizarIds(
                dto.EquipoProteccionIds);

        await ValidarEquiposProteccionAsync(
            equipoProteccionIds);

        // --------------------------------------------------------
        // EVALUACIÓN RESIDUAL
        // --------------------------------------------------------

        ValidarDatosEvaluacionResidual(
            dto.ProbabilidadResidualId,
            dto.SeveridadResidualId);

        // --------------------------------------------------------
        // ITEM
        // --------------------------------------------------------

        int item =
            dto.Item;

        if (item <= 0)
        {
            int ultimoItem =
                await _context
                    .Set<DetalleIPERC>()
                    .Where(
                        x =>
                            x.MatrizIPERCId ==
                            dto.MatrizIPERCId)
                    .OrderByDescending(
                        x => x.Item)
                    .Select(
                        x => x.Item)
                    .FirstOrDefaultAsync();

            item =
                ultimoItem + 1;
        }

        bool existeItem =
            await _context
                .Set<DetalleIPERC>()
                .AnyAsync(
                    x =>
                        x.MatrizIPERCId ==
                            dto.MatrizIPERCId &&
                        x.Item ==
                            item);

        if (existeItem)
        {
            throw new InvalidOperationException(
                "Ya existe un detalle con ese número de item en la matriz seleccionada.");
        }

        // --------------------------------------------------------
        // TRANSACCIÓN
        // --------------------------------------------------------

        await using var transaccion =
            await _context.Database
                .BeginTransactionAsync();

        try
        {
            // ====================================================
            // CREAR EVALUACIÓN INICIAL
            // ====================================================

            EvaluacionRiesgo evaluacionInicial =
                await CrearEvaluacionAsync(
                    dto.ProbabilidadInicialId,
                    dto.SeveridadInicialId,
                    dto.ObservacionesEvaluacionInicial);

            _context
                .Set<EvaluacionRiesgo>()
                .Add(
                    evaluacionInicial);

            await _context
                .SaveChangesAsync();

            // ====================================================
            // CREAR EVALUACIÓN RESIDUAL
            // ====================================================

            EvaluacionRiesgo? evaluacionResidual =
                null;

            if (dto.ProbabilidadResidualId
                    .HasValue &&
                dto.SeveridadResidualId
                    .HasValue)
            {
                evaluacionResidual =
                    await CrearEvaluacionAsync(
                        dto.ProbabilidadResidualId
                            .Value,
                        dto.SeveridadResidualId
                            .Value,
                        dto.ObservacionesEvaluacionResidual);

                _context
                    .Set<EvaluacionRiesgo>()
                    .Add(
                        evaluacionResidual);

                await _context
                    .SaveChangesAsync();
            }

            // ====================================================
            // CREAR DETALLE
            // ====================================================

            DetalleIPERC detalle =
                new()
                {
                    MatrizIPERCId =
                        dto.MatrizIPERCId,

                    Item =
                        item,

                    Tarea =
                        tarea,

                    PeligroId =
                        dto.PeligroId,

                    ConsecuenciaId =
                        dto.ConsecuenciaId,

                    DescripcionPeligro =
                        LimpiarTexto(
                            dto.DescripcionPeligro),

                    EvaluacionInicialId =
                        evaluacionInicial.Id,

                    EvaluacionResidualId =
                        evaluacionResidual?.Id,

                    ResponsableImplementacionId =
                        dto.ResponsableImplementacionId,

                    FechaCompromiso =
                        dto.FechaCompromiso,

                    FechaImplementacion =
                        dto.FechaImplementacion,

                    EstadoImplementacion =
                        (EstadoImplementacion)
                        dto.EstadoImplementacion,

                    Controles =
                        controlIds
                            .Select(
                                controlId =>
                                    new DetalleIPERCControl
                                    {
                                        ControlId =
                                            controlId
                                    })
                            .ToList(),

                    EquiposProteccion =
                        equipoProteccionIds
                            .Select(
                                equipoId =>
                                    new DetalleIPERCEPP
                                    {
                                        EquipoProteccionId =
                                            equipoId
                                    })
                            .ToList()
                };

            _context
                .Set<DetalleIPERC>()
                .Add(
                    detalle);

            await _context
                .SaveChangesAsync();

            await transaccion
                .CommitAsync();

            return await GetByIdAsync(
                       detalle.Id)
                   ?? throw new InvalidOperationException(
                       "No se pudo recuperar el detalle IPERC registrado.");
        }
        catch
        {
            await transaccion
                .RollbackAsync();

            throw;
        }
    }

    // ============================================================
    // UPDATE
    // ============================================================

    public async Task<bool> UpdateAsync(
        long id,
        UpdateDetalleIPERCDto dto)
    {
        DetalleIPERC? detalle =
            await _context
                .Set<DetalleIPERC>()
                .Include(
                    x => x.Controles)
                .Include(
                    x => x.EquiposProteccion)
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == id);

        if (detalle is null)
        {
            return false;
        }

        // --------------------------------------------------------
        // MATRIZ
        // --------------------------------------------------------

        bool matrizExiste =
            await _context
                .Set<MatrizIPERC>()
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                            dto.MatrizIPERCId &&
                        x.Estado);

        if (!matrizExiste)
        {
            throw new InvalidOperationException(
                "La Matriz IPERC seleccionada no existe o está inactiva.");
        }

        // --------------------------------------------------------
        // TAREA
        // --------------------------------------------------------

        string tarea =
            dto.Tarea.Trim();

        if (string.IsNullOrWhiteSpace(
                tarea))
        {
            throw new InvalidOperationException(
                "La tarea es obligatoria.");
        }

        // --------------------------------------------------------
        // PELIGRO
        // --------------------------------------------------------

        bool peligroExiste =
            await _context.Peligros
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                            dto.PeligroId &&
                        x.Activo);

        if (!peligroExiste)
        {
            throw new InvalidOperationException(
                "El peligro seleccionado no existe o está inactivo.");
        }

        // --------------------------------------------------------
        // CONSECUENCIA
        // --------------------------------------------------------

        bool consecuenciaExiste =
            await _context.Consecuencias
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                            dto.ConsecuenciaId &&
                        x.Activo);

        if (!consecuenciaExiste)
        {
            throw new InvalidOperationException(
                "La consecuencia seleccionada no existe o está inactiva.");
        }

        // --------------------------------------------------------
        // RESPONSABLE
        // --------------------------------------------------------

        await ValidarResponsableAsync(
            dto.ResponsableImplementacionId);

        // --------------------------------------------------------
        // ESTADO
        // --------------------------------------------------------

        ValidarEstadoImplementacion(
            dto.EstadoImplementacion);

        // --------------------------------------------------------
        // RESIDUAL
        // --------------------------------------------------------

        ValidarDatosEvaluacionResidual(
            dto.ProbabilidadResidualId,
            dto.SeveridadResidualId);

        // --------------------------------------------------------
        // CONTROLES
        // --------------------------------------------------------

        List<long> controlIds =
            NormalizarIds(
                dto.ControlIds);

        await ValidarControlesAsync(
            controlIds);

        // --------------------------------------------------------
        // EPP
        // --------------------------------------------------------

        List<long> equipoProteccionIds =
            NormalizarIds(
                dto.EquipoProteccionIds);

        await ValidarEquiposProteccionAsync(
            equipoProteccionIds);

        // --------------------------------------------------------
        // ITEM
        // --------------------------------------------------------

        int item =
            dto.Item <= 0
                ? detalle.Item
                : dto.Item;

        bool existeItem =
            await _context
                .Set<DetalleIPERC>()
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id != id &&
                        x.MatrizIPERCId ==
                            dto.MatrizIPERCId &&
                        x.Item ==
                            item);

        if (existeItem)
        {
            throw new InvalidOperationException(
                "Ya existe otro detalle con ese número de item en la matriz seleccionada.");
        }

        await using var transaccion =
            await _context.Database
                .BeginTransactionAsync();

        try
        {
            // ====================================================
            // ACTUALIZAR EVALUACIÓN INICIAL
            // ====================================================

            EvaluacionRiesgo? evaluacionInicial =
                await _context
                    .Set<EvaluacionRiesgo>()
                    .FirstOrDefaultAsync(
                        x =>
                            x.Id ==
                            detalle
                                .EvaluacionInicialId);

            if (evaluacionInicial is null)
            {
                throw new InvalidOperationException(
                    "No se encontró la evaluación inicial asociada al detalle.");
            }

            await ActualizarEvaluacionAsync(
                evaluacionInicial,
                dto.ProbabilidadInicialId,
                dto.SeveridadInicialId,
                dto.ObservacionesEvaluacionInicial);

            // ====================================================
            // EVALUACIÓN RESIDUAL
            // ====================================================

            if (dto.ProbabilidadResidualId
                    .HasValue &&
                dto.SeveridadResidualId
                    .HasValue)
            {
                if (detalle.EvaluacionResidualId
                    .HasValue)
                {
                    EvaluacionRiesgo?
                        evaluacionResidual =
                            await _context
                                .Set<EvaluacionRiesgo>()
                                .FirstOrDefaultAsync(
                                    x =>
                                        x.Id ==
                                        detalle
                                            .EvaluacionResidualId
                                            .Value);

                    if (evaluacionResidual is null)
                    {
                        throw new InvalidOperationException(
                            "No se encontró la evaluación residual asociada.");
                    }

                    await ActualizarEvaluacionAsync(
                        evaluacionResidual,
                        dto.ProbabilidadResidualId
                            .Value,
                        dto.SeveridadResidualId
                            .Value,
                        dto.ObservacionesEvaluacionResidual);
                }
                else
                {
                    EvaluacionRiesgo nuevaResidual =
                        await CrearEvaluacionAsync(
                            dto.ProbabilidadResidualId
                                .Value,
                            dto.SeveridadResidualId
                                .Value,
                            dto.ObservacionesEvaluacionResidual);

                    _context
                        .Set<EvaluacionRiesgo>()
                        .Add(
                            nuevaResidual);

                    await _context
                        .SaveChangesAsync();

                    detalle.EvaluacionResidualId =
                        nuevaResidual.Id;
                }
            }
            else
            {
                // Si el usuario elimina los valores residuales
                // del formulario, se desvincula la evaluación.
                //
                // No se elimina físicamente aquí para evitar
                // problemas de integridad o auditoría.
                detalle.EvaluacionResidualId =
                    null;
            }

            // ====================================================
            // ACTUALIZAR DETALLE
            // ====================================================

            detalle.MatrizIPERCId =
                dto.MatrizIPERCId;

            detalle.Item =
                item;

            detalle.Tarea =
                tarea;

            detalle.PeligroId =
                dto.PeligroId;

            detalle.ConsecuenciaId =
                dto.ConsecuenciaId;

            detalle.DescripcionPeligro =
                LimpiarTexto(
                    dto.DescripcionPeligro);

            detalle.ResponsableImplementacionId =
                dto.ResponsableImplementacionId;

            detalle.FechaCompromiso =
                dto.FechaCompromiso;

            detalle.FechaImplementacion =
                dto.FechaImplementacion;

            detalle.EstadoImplementacion =
                (EstadoImplementacion)
                dto.EstadoImplementacion;

            detalle.FechaActualizacion =
                DateTime.UtcNow;

            // ====================================================
            // CONTROLES
            // ====================================================

            SincronizarControles(
                detalle,
                controlIds);

            // ====================================================
            // EPP
            // ====================================================

            SincronizarEquiposProteccion(
                detalle,
                equipoProteccionIds);

            await _context
                .SaveChangesAsync();

            await transaccion
                .CommitAsync();

            return true;
        }
        catch
        {
            await transaccion
                .RollbackAsync();

            throw;
        }
    }

    // ============================================================
    // DELETE / CERRAR
    // ============================================================

    /// <summary>
    /// Cierra el detalle IPERC.
    ///
    /// No elimina físicamente la información.
    /// </summary>
    public async Task<bool> DeleteAsync(
        long id)
    {
        DetalleIPERC? detalle =
            await _context
                .Set<DetalleIPERC>()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id == id);

        if (detalle is null)
        {
            return false;
        }

        detalle.EstadoImplementacion =
            EstadoImplementacion.Cerrado;

        detalle.FechaActualizacion =
            DateTime.UtcNow;

        await _context
            .SaveChangesAsync();

        return true;
    }

    // ============================================================
    // CREAR EVALUACIÓN
    // ============================================================

    /// <summary>
    /// Crea una evaluación utilizando Probabilidad y Severidad.
    ///
    /// El nivel de riesgo se obtiene de la tabla NivelesRiesgo.
    /// </summary>
    private async Task<EvaluacionRiesgo>
        CrearEvaluacionAsync(
            long probabilidadId,
            long severidadId,
            string? observaciones)
    {
        Probabilidad? probabilidad =
            await _context
                .Set<Probabilidad>()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id ==
                        probabilidadId);

        if (probabilidad is null)
        {
            throw new InvalidOperationException(
                "La probabilidad seleccionada no existe.");
        }

        Severidad? severidad =
            await _context
                .Set<Severidad>()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id ==
                        severidadId);

        if (severidad is null)
        {
            throw new InvalidOperationException(
                "La severidad seleccionada no existe.");
        }

        // --------------------------------------------------------
        // VALIDAR MATRIZ 5 X 5
        // --------------------------------------------------------

        if (probabilidad.Valor < 1 ||
            probabilidad.Valor > 5)
        {
            throw new InvalidOperationException(
                "El valor de la probabilidad debe estar entre 1 y 5.");
        }

        if (severidad.Valor < 1 ||
            severidad.Valor > 5)
        {
            throw new InvalidOperationException(
                "El valor de la severidad debe estar entre 1 y 5.");
        }

        int valorRiesgo =
            probabilidad.Valor *
            severidad.Valor;

        // --------------------------------------------------------
        // BUSCAR NIVEL DE RIESGO
        // --------------------------------------------------------

        NivelRiesgo? nivelRiesgo =
            await _context
                .Set<NivelRiesgo>()
                .FirstOrDefaultAsync(
                    x =>
                        valorRiesgo >=
                            x.Desde &&
                        valorRiesgo <=
                            x.Hasta);

        if (nivelRiesgo is null)
        {
            throw new InvalidOperationException(
                $"No existe un Nivel de Riesgo configurado para el valor {valorRiesgo}.");
        }

        // --------------------------------------------------------
        // CREAR
        // --------------------------------------------------------

        EvaluacionRiesgo evaluacion =
            new()
            {
                ProbabilidadId =
                    probabilidad.Id,

                SeveridadId =
                    severidad.Id,

                NivelRiesgoId =
                    nivelRiesgo.Id,

                Observaciones =
                    LimpiarTexto(
                        observaciones),

                Probabilidad =
                    probabilidad,

                Severidad =
                    severidad,

                NivelRiesgo =
                    nivelRiesgo
            };

        // Utilizamos el método del dominio porque además
        // de calcular Valor, toma la propiedad Aceptable
        // del NivelRiesgo.
        evaluacion.Calcular();

        return evaluacion;
    }

    // ============================================================
    // ACTUALIZAR EVALUACIÓN
    // ============================================================

    private async Task ActualizarEvaluacionAsync(
        EvaluacionRiesgo evaluacion,
        long probabilidadId,
        long severidadId,
        string? observaciones)
    {
        Probabilidad? probabilidad =
            await _context
                .Set<Probabilidad>()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id ==
                        probabilidadId);

        if (probabilidad is null)
        {
            throw new InvalidOperationException(
                "La probabilidad seleccionada no existe.");
        }

        Severidad? severidad =
            await _context
                .Set<Severidad>()
                .FirstOrDefaultAsync(
                    x =>
                        x.Id ==
                        severidadId);

        if (severidad is null)
        {
            throw new InvalidOperationException(
                "La severidad seleccionada no existe.");
        }

        if (probabilidad.Valor < 1 ||
            probabilidad.Valor > 5)
        {
            throw new InvalidOperationException(
                "El valor de la probabilidad debe estar entre 1 y 5.");
        }

        if (severidad.Valor < 1 ||
            severidad.Valor > 5)
        {
            throw new InvalidOperationException(
                "El valor de la severidad debe estar entre 1 y 5.");
        }

        int valorRiesgo =
            probabilidad.Valor *
            severidad.Valor;

        NivelRiesgo? nivelRiesgo =
            await _context
                .Set<NivelRiesgo>()
                .FirstOrDefaultAsync(
                    x =>
                        valorRiesgo >=
                            x.Desde &&
                        valorRiesgo <=
                            x.Hasta);

        if (nivelRiesgo is null)
        {
            throw new InvalidOperationException(
                $"No existe un Nivel de Riesgo configurado para el valor {valorRiesgo}.");
        }

        evaluacion.ProbabilidadId =
            probabilidad.Id;

        evaluacion.SeveridadId =
            severidad.Id;

        evaluacion.NivelRiesgoId =
            nivelRiesgo.Id;

        evaluacion.Observaciones =
            LimpiarTexto(
                observaciones);

        evaluacion.Probabilidad =
            probabilidad;

        evaluacion.Severidad =
            severidad;

        evaluacion.NivelRiesgo =
            nivelRiesgo;

        evaluacion.Calcular();

        evaluacion.FechaActualizacion =
            DateTime.UtcNow;
    }

    // ============================================================
    // VALIDAR RESPONSABLE
    // ============================================================

    private async Task ValidarResponsableAsync(
        long? responsableId)
    {
        if (!responsableId.HasValue ||
            responsableId.Value <= 0)
        {
            return;
        }

        bool responsableExiste =
            await _context
                .Set<Usuario>()
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                            responsableId.Value &&
                        x.Estado &&
                        x.Activo);

        if (!responsableExiste)
        {
            throw new InvalidOperationException(
                "El responsable de implementación no existe o está inactivo.");
        }
    }

    // ============================================================
    // VALIDAR ESTADO IMPLEMENTACIÓN
    // ============================================================

    private static void
        ValidarEstadoImplementacion(
            int estado)
    {
        if (!Enum.IsDefined(
                typeof(EstadoImplementacion),
                estado))
        {
            throw new InvalidOperationException(
                "El estado de implementación seleccionado no es válido.");
        }
    }

    // ============================================================
    // VALIDAR DATOS RESIDUALES
    // ============================================================

    private static void
        ValidarDatosEvaluacionResidual(
            long? probabilidadId,
            long? severidadId)
    {
        bool tieneProbabilidad =
            probabilidadId.HasValue &&
            probabilidadId.Value > 0;

        bool tieneSeveridad =
            severidadId.HasValue &&
            severidadId.Value > 0;

        if (tieneProbabilidad !=
            tieneSeveridad)
        {
            throw new InvalidOperationException(
                "Para realizar la evaluación residual debe seleccionar tanto la probabilidad como la severidad.");
        }
    }

    // ============================================================
    // NORMALIZAR IDS
    // ============================================================

    private static List<long> NormalizarIds(
        IEnumerable<long>? ids)
    {
        return ids?
            .Where(
                id => id > 0)
            .Distinct()
            .ToList()
            ?? new List<long>();
    }

    // ============================================================
    // VALIDAR CONTROLES
    // ============================================================

    private async Task ValidarControlesAsync(
        List<long> controlIds)
    {
        if (controlIds.Count == 0)
        {
            return;
        }

        int controlesExistentes =
            await _context.Controles
                .AsNoTracking()
                .CountAsync(
                    x =>
                        controlIds.Contains(
                            x.Id) &&
                        x.Activo);

        if (controlesExistentes !=
            controlIds.Count)
        {
            throw new InvalidOperationException(
                "Uno o más controles seleccionados no existen o están inactivos.");
        }
    }

    // ============================================================
    // VALIDAR EPP
    // ============================================================

    private async Task
        ValidarEquiposProteccionAsync(
            List<long> equipoProteccionIds)
    {
        if (equipoProteccionIds.Count == 0)
        {
            return;
        }

        int equiposExistentes =
            await _context
                .EquiposProteccion
                .AsNoTracking()
                .CountAsync(
                    x =>
                        equipoProteccionIds
                            .Contains(
                                x.Id) &&
                        x.Activo);

        if (equiposExistentes !=
            equipoProteccionIds.Count)
        {
            throw new InvalidOperationException(
                "Uno o más equipos de protección seleccionados no existen o están inactivos.");
        }
    }

    // ============================================================
    // SINCRONIZAR CONTROLES
    // ============================================================

    private void SincronizarControles(
        DetalleIPERC detalle,
        List<long> controlIds)
    {
        List<DetalleIPERCControl> actuales =
            detalle.Controles
                .ToList();

        List<DetalleIPERCControl> eliminar =
            actuales
                .Where(
                    x =>
                        !controlIds.Contains(
                            x.ControlId))
                .ToList();

        if (eliminar.Count > 0)
        {
            _context
                .Set<DetalleIPERCControl>()
                .RemoveRange(
                    eliminar);
        }

        HashSet<long> actualesIds =
            actuales
                .Select(
                    x =>
                        x.ControlId)
                .ToHashSet();

        foreach (
            long controlId
            in controlIds.Where(
                id =>
                    !actualesIds.Contains(
                        id)))
        {
            detalle.Controles.Add(
                new DetalleIPERCControl
                {
                    DetalleIPERCId =
                        detalle.Id,

                    ControlId =
                        controlId
                });
        }
    }

    // ============================================================
    // SINCRONIZAR EPP
    // ============================================================

    private void SincronizarEquiposProteccion(
        DetalleIPERC detalle,
        List<long> equipoProteccionIds)
    {
        List<DetalleIPERCEPP> actuales =
            detalle.EquiposProteccion
                .ToList();

        List<DetalleIPERCEPP> eliminar =
            actuales
                .Where(
                    x =>
                        !equipoProteccionIds
                            .Contains(
                                x.EquipoProteccionId))
                .ToList();

        if (eliminar.Count > 0)
        {
            _context
                .Set<DetalleIPERCEPP>()
                .RemoveRange(
                    eliminar);
        }

        HashSet<long> actualesIds =
            actuales
                .Select(
                    x =>
                        x.EquipoProteccionId)
                .ToHashSet();

        foreach (
            long equipoProteccionId
            in equipoProteccionIds.Where(
                id =>
                    !actualesIds.Contains(
                        id)))
        {
            detalle.EquiposProteccion.Add(
                new DetalleIPERCEPP
                {
                    DetalleIPERCId =
                        detalle.Id,

                    EquipoProteccionId =
                        equipoProteccionId
                });
        }
    }

    // ============================================================
    // LIMPIAR TEXTO
    // ============================================================

    private static string? LimpiarTexto(
        string? texto)
    {
        return string.IsNullOrWhiteSpace(
            texto)
            ? null
            : texto.Trim();
    }
}