using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.Achievements;
using PaceUp.Application.DTOs.Achievements;
using System.Security.Claims;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/achievements")]
public class AchievementsController : ControllerBase
{
    private readonly IAchievementService _achievementService;

    public AchievementsController(
        IAchievementService achievementService)
    {
        _achievementService = achievementService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<AchievementResponse>>> Get(
        CancellationToken cancellationToken)
    {
        var userIdClaim =
            User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        var achievements =
            await _achievementService.GetAsync(
                userId,
                cancellationToken);

        return Ok(achievements);
    }
}