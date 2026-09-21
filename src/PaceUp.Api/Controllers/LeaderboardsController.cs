using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.Leaderboards;
using PaceUp.Application.DTOs.Leaderboards;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/leaderboards")]
public class LeaderboardsController : ControllerBase
{
    private readonly ILeaderboardService _leaderboardService;

    public LeaderboardsController(
        ILeaderboardService leaderboardService)
    {
        _leaderboardService = leaderboardService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<LeaderboardEntryResponse>>> Get(
        [FromQuery] string period = "weekly",
        [FromQuery] int limit = 10,
        CancellationToken cancellationToken = default)
    {
        var userIdClaim =
            User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        try
        {
            var response = await _leaderboardService.GetAsync(
                userId,
                period,
                limit,
                cancellationToken);

            return Ok(response);
        }
        catch (ArgumentException)
        {
            return BadRequest("Invalid leaderboard parameters.");
        }
    }
}