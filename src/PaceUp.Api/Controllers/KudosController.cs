using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Kudos;
using PaceUp.Application.DTOs.Kudos;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/activities/{activityId:guid}/kudos")]
public class KudosController : ControllerBase
{
    private readonly IKudosService _kudosService;

    public KudosController(
        IKudosService kudosService)
    {
        _kudosService = kudosService;
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(KudosResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<KudosResponse>> Get(
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        try
        {
            var result =
                await _kudosService.GetAsync(
                    userId,
                    activityId,
                    cancellationToken);

            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost]
    [ProducesResponseType(
        typeof(KudosResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<KudosResponse>> Give(
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        try
        {
            var result =
                await _kudosService.GiveAsync(
                    userId,
                    activityId,
                    cancellationToken);

            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpDelete]
    [ProducesResponseType(
        typeof(KudosResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<KudosResponse>> Remove(
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        try
        {
            var result =
                await _kudosService.RemoveAsync(
                    userId,
                    activityId,
                    cancellationToken);

            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}