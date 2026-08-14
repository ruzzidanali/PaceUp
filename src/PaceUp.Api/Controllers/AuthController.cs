using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.DTOs.Authentication;

namespace PaceUp.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthenticationService _authenticationService;

    public AuthController(
        IAuthenticationService authenticationService)
    {
        _authenticationService = authenticationService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        var result =
            await _authenticationService.RegisterAsync(
                request,
                cancellationToken);

        return Ok(result);
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        var result =
            await _authenticationService.LoginAsync(
                request,
                cancellationToken);

        return Ok(result);
    }
}