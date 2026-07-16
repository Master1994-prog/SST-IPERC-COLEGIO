using SST.Application.Security.DTOs;

namespace SST.Application.Security.Interfaces;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken = default);
}
