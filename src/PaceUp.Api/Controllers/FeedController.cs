using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Feed;
using PaceUp.Application.DTOs.Feed;

namespace PaceUp.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/feed")]
public class FeedController : ControllerBase
{
    private readonly IFeedService _feedService;

    public FeedController(
        IFeedService feedService
    )
    {
        _feedService = feedService;
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(PagedFeedResponse),
        StatusCodes.Status200OK
    )]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized
    )]
    public async Task<ActionResult<PagedFeedResponse>> Get(
        [FromQuery] FeedRequest request,
        CancellationToken cancellationToken
    )
    {
        var userId = User.GetUserId();

        var result =
            await _feedService.GetAsync(
                userId,
                request,
                cancellationToken
            );

        return Ok(result);
    }
}