using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.Streaks;
using PaceUp.Application.DTOs.Streaks;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/streaks")]
public class StreaksController : ControllerBase
{
    private readonly IStreakService _streakService;

    public StreaksController(IStreakService streakService)
    {
        _streakService = streakService;
    }

    [HttpGet]
    public async Task<ActionResult<StreakResponse>> Get(
        CancellationToken cancellationToken)
    {
        var userIdClaim =
            User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        var response = await _streakService.GetAsync(
            userId,
            cancellationToken);

        return Ok(response);
    }
}