using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Challenges;
using PaceUp.Application.DTOs.Challenges;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/challenges")]
public class ChallengesController : ControllerBase
{
    private readonly IChallengeService _challengeService;

    public ChallengesController(
        IChallengeService challengeService)
    {
        _challengeService = challengeService;
    }

    [HttpPost]
    [ProducesResponseType(
        typeof(ChallengeResponse),
        StatusCodes.Status201Created)]
    public async Task<ActionResult<ChallengeResponse>> Create(
        [FromBody] CreateChallengeRequest request,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var challenge =
            await _challengeService.CreateAsync(
                userId,
                request,
                cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new { id = challenge.Id },
            challenge);
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(IReadOnlyList<ChallengeResponse>),
        StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ChallengeResponse>>> Get(
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var challenges =
            await _challengeService.GetAsync(
                userId,
                cancellationToken);

        return Ok(challenges);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(
        typeof(ChallengeResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ChallengeResponse>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var challenge =
            await _challengeService.GetByIdAsync(
                userId,
                id,
                cancellationToken);

        if (challenge is null)
        {
            return NotFound();
        }

        return Ok(challenge);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(
        typeof(ChallengeResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ChallengeResponse>> Update(
        Guid id,
        [FromBody] UpdateChallengeRequest request,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var challenge =
            await _challengeService.UpdateAsync(
                userId,
                id,
                request,
                cancellationToken);

        if (challenge is null)
        {
            return NotFound();
        }

        return Ok(challenge);
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var deleted =
            await _challengeService.DeleteAsync(
                userId,
                id,
                cancellationToken);

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpPost("{id:guid}/join")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Join(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var joined =
            await _challengeService.JoinAsync(
                userId,
                id,
                cancellationToken);

        if (!joined)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpDelete("{id:guid}/join")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Leave(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var left =
            await _challengeService.LeaveAsync(
                userId,
                id,
                cancellationToken);

        if (!left)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpGet("{id:guid}/progress")]
    [ProducesResponseType(
        typeof(ChallengeProgressResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ChallengeProgressResponse>> GetProgress(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var progress =
            await _challengeService.GetProgressAsync(
                userId,
                id,
                cancellationToken);

        if (progress is null)
        {
            return NotFound();
        }

        return Ok(progress);
    }

    [HttpGet("{id:guid}/leaderboard")]
    [ProducesResponseType(
        typeof(ChallengeLeaderboardResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ChallengeLeaderboardResponse>> GetLeaderboard(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var leaderboard =
            await _challengeService.GetLeaderboardAsync(
                userId,
                id,
                cancellationToken);

        if (leaderboard is null)
        {
            return NotFound();
        }

        return Ok(leaderboard);
    }
}