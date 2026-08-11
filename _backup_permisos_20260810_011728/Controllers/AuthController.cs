using Microsoft.AspNetCore.Mvc;
using SST.Application.Security.DTOs;
using SST.Application.Security.Interfaces;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("login")]
    [ProducesResponseType(
        typeof(LoginResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        LoginResponse? resultado =
            await _authService.LoginAsync(
                request,
                cancellationToken);

        if (resultado is null)
        {
            return Unauthorized(new
            {
                mensaje =
                    "Usuario, contraseña o rol incorrecto."
            });
        }

        return Ok(resultado);
    }
}
