using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Activities;
using PaceUp.Application.DTOs.Activities;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/activities")]
public class ActivitiesController : ControllerBase
{
    private readonly IActivityService _activityService;

    public ActivitiesController(
        IActivityService activityService)
    {
        _activityService = activityService;
    }

    [HttpPost]
    [ProducesResponseType(
        typeof(ActivityResponse),
        StatusCodes.Status201Created)]
    public async Task<ActionResult<ActivityResponse>> Create(
        [FromBody] CreateActivityRequest request,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var activity =
            await _activityService.CreateAsync(
                userId,
                request,
                cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new { id = activity.Id },
            activity);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(
        typeof(ActivityResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ActivityResponse>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var activity =
            await _activityService.GetByIdAsync(
                userId,
                id,
                cancellationToken);

        if (activity is null)
        {
            return NotFound();
        }

        return Ok(activity);
    }

    [HttpGet]
[ProducesResponseType(
    typeof(PagedActivityResponse),
    StatusCodes.Status200OK)]
public async Task<ActionResult<PagedActivityResponse>>
    GetMine(
        [FromQuery] ActivityListRequest request,
        CancellationToken cancellationToken)
{
    var userId = User.GetUserId();

    var activities =
        await _activityService.GetUserActivitiesAsync(
            userId,
            request,
            cancellationToken);

    return Ok(activities);
}

    [HttpGet("stats")]
    [ProducesResponseType(
    typeof(ActivityStatsResponse),
    StatusCodes.Status200OK)]
    public async Task<ActionResult<ActivityStatsResponse>> GetStats(
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var stats =
            await _activityService.GetStatsAsync(
                userId,
                cancellationToken);

        return Ok(stats);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(
    typeof(ActivityResponse),
    StatusCodes.Status200OK)]
    [ProducesResponseType(
    StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ActivityResponse>> Update(
    Guid id,
    [FromBody] UpdateActivityRequest request,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var activity =
            await _activityService.UpdateAsync(
                userId,
                id,
                request,
                cancellationToken);

        if (activity is null)
        {
            return NotFound();
        }

        return Ok(activity);
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(
        StatusCodes.Status204NoContent)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var deleted =
            await _activityService.DeleteAsync(
                userId,
                id,
                cancellationToken);

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }
}