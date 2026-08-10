using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SST.Application.Security.DTOs;
using SST.Application.Security.Interfaces;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Security;

public sealed class AuthService : IAuthService
{
    private readonly SSTDbContext _dbContext;
    private readonly IPasswordHasher<Usuario> _passwordHasher;
    private readonly IJwtService _jwtService;

    public AuthService(
        SSTDbContext dbContext,
        IPasswordHasher<Usuario> passwordHasher,
        IJwtService jwtService)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _jwtService = jwtService;
    }

    public async Task<LoginResponse?> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken = default)
    {
        string identificador = request.Usuario.Trim();

        Usuario? usuario = await _dbContext.Usuarios
            .Include(x => x.UsuariosRoles)
                .ThenInclude(x => x.Rol)
            .FirstOrDefaultAsync(
                x =>
                    x.NombreUsuario == identificador ||
                    x.Correo == identificador,
                cancellationToken);

        if (usuario is null || !usuario.Activo)
        {
            return null;
        }

        PasswordVerificationResult resultado =
            _passwordHasher.VerifyHashedPassword(
                usuario,
                usuario.PasswordHash,
                request.Password);

        if (resultado == PasswordVerificationResult.Failed)
        {
            return null;
        }

        List<string> roles = usuario.UsuariosRoles
            .Where(x =>
                x.Activo &&
                x.Rol.Activo)
            .Select(x => x.Rol.Nombre)
            .Distinct()
            .ToList();

        if (roles.Count == 0)
        {
            return null;
        }

        if (resultado ==
            PasswordVerificationResult.SuccessRehashNeeded)
        {
            usuario.PasswordHash =
                _passwordHasher.HashPassword(
                    usuario,
                    request.Password);
        }

        usuario.RegistrarAcceso();

        await _dbContext.SaveChangesAsync(cancellationToken);

        string token = _jwtService.GenerarToken(
            usuario,
            roles,
            out DateTime expiraEn);

        return new LoginResponse
        {
            Token = token,
            ExpiraEn = expiraEn,

            Usuario = new UsuarioLoginResponse
            {
                Id = usuario.Id,
                NombreUsuario = usuario.NombreUsuario,
                Nombres = usuario.Nombres,
                Apellidos = usuario.Apellidos,
                Correo = usuario.Correo,
                InstitucionId = usuario.InstitucionId,
                SedeId = usuario.SedeId,
                AreaId = usuario.AreaId,
                DebeCambiarPassword =
                    usuario.DebeCambiarPassword,
                Roles = roles
            }
        };
    }
}
