using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
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

    [Authorize]
    [HttpPost("change-password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ChangePassword(
    [FromBody] ChangePasswordRequest request,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        await _authenticationService.ChangePasswordAsync(
            userId,
            request,
            cancellationToken);

        return NoContent();
    }

    [HttpPost("verify-email")]
    [ProducesResponseType(
    typeof(EmailVerificationResponse),
    StatusCodes.Status200OK)]
    public async Task<ActionResult<EmailVerificationResponse>> VerifyEmail(
    [FromBody] VerifyEmailRequest request,
    CancellationToken cancellationToken)
    {
        var result =
            await _authenticationService.VerifyEmailAsync(
                request.Token,
                cancellationToken);

        return Ok(result);
    }

    [HttpPost("forgot-password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ForgotPassword(
    [FromBody] ForgotPasswordRequest request,
    CancellationToken cancellationToken)
    {
        await _authenticationService.ForgotPasswordAsync(
            request.Email,
            cancellationToken);

        return NoContent();
    }

    [HttpPost("reset-password")]
    [ProducesResponseType(
        typeof(PasswordResetResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<PasswordResetResponse>> ResetPassword(
        [FromBody] ResetPasswordRequest request,
        CancellationToken cancellationToken)
    {
        var result =
            await _authenticationService.ResetPasswordAsync(
                request,
                cancellationToken);

        return Ok(result);
    }

    [Authorize]
    [HttpPost("resend-verification")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> ResendVerification(
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        await _authenticationService.ResendVerificationAsync(
            userId,
            cancellationToken);

        return NoContent();
    }

    [HttpPost("refresh")]
    [ProducesResponseType(
    typeof(RefreshTokenResponse),
    StatusCodes.Status200OK)]
    [ProducesResponseType(
    StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<RefreshTokenResponse>> Refresh(
    [FromBody] RefreshTokenRequest request,
    CancellationToken cancellationToken)
    {
        var result =
            await _authenticationService.RefreshAsync(
                request.RefreshToken,
                cancellationToken);

        return Ok(result);
    }

    [HttpPost("revoke")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Revoke(
        [FromBody] RefreshTokenRequest request,
        CancellationToken cancellationToken)
    {
        await _authenticationService.RevokeRefreshTokenAsync(
            request.RefreshToken,
            cancellationToken);

        return NoContent();
    }
}