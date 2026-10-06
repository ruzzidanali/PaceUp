using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.DTOs.Authentication;
using Microsoft.AspNetCore.RateLimiting;
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
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<RegistrationResponse>> Register(
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
    [EnableRateLimiting("auth")]
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
    [EnableRateLimiting("auth")]
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

    [AllowAnonymous]
    [HttpGet("verify-email")]
    public IActionResult VerifyEmailLink(
    [FromQuery] string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return BadRequest("Verification token is missing.");
        }

        var deepLink =
            $"paceup://verify-email?token={Uri.EscapeDataString(token)}";

        return Redirect(deepLink);
    }

    [HttpPost("forgot-password")]
    [EnableRateLimiting("auth")]
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
    [EnableRateLimiting("auth")]
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

    [EnableRateLimiting("auth")]
    [HttpPost("resend-verification")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> ResendVerification(
    [FromBody] ResendVerificationRequest request,
    CancellationToken cancellationToken)
    {
        await _authenticationService.ResendVerificationAsync(
            request.Email,
            cancellationToken);

        return NoContent();
    }

    [HttpPost("refresh")]
    [EnableRateLimiting("auth")]
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
    [EnableRateLimiting("auth")]
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

    [AllowAnonymous]
    [HttpGet("reset-password-link")]
    public IActionResult ResetPasswordLink(
    [FromQuery] string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return BadRequest("Reset token is required.");
        }

        var appUrl =
            $"paceup://reset-password?token={Uri.EscapeDataString(token)}";

        return Redirect(appUrl);
    }
}
