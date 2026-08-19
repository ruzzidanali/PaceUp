using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Goals;
using PaceUp.Application.DTOs.Goals;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/goals")]
public class GoalsController : ControllerBase
{
    private readonly IGoalService _goalService;

    public GoalsController(
        IGoalService goalService)
    {
        _goalService = goalService;
    }

    [HttpPost]
    [ProducesResponseType(
        typeof(GoalResponse),
        StatusCodes.Status201Created)]
    public async Task<ActionResult<GoalResponse>> Create(
        [FromBody] CreateGoalRequest request,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var goal =
            await _goalService.CreateAsync(
                userId,
                request,
                cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new { id = goal.Id },
            goal);
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(IReadOnlyList<GoalResponse>),
        StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<GoalResponse>>> GetMine(
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var goals =
            await _goalService.GetUserGoalsAsync(
                userId,
                cancellationToken);

        return Ok(goals);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(
        typeof(GoalResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<GoalResponse>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var goal =
            await _goalService.GetByIdAsync(
                userId,
                id,
                cancellationToken);

        if (goal is null)
        {
            return NotFound();
        }

        return Ok(goal);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(
        typeof(GoalResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<GoalResponse>> Update(
        Guid id,
        [FromBody] UpdateGoalRequest request,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var goal =
            await _goalService.UpdateAsync(
                userId,
                id,
                request,
                cancellationToken);

        if (goal is null)
        {
            return NotFound();
        }

        return Ok(goal);
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
            await _goalService.DeleteAsync(
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