using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Routes;
using PaceUp.Application.DTOs.Routes;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/activities")]
public class RoutesController : ControllerBase
{
    private readonly IRouteService _routeService;

    public RoutesController(
        IRouteService routeService)
    {
        _routeService = routeService;
    }

    [HttpGet("{activityId:guid}/route")]
    [ProducesResponseType(
        typeof(RouteResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RouteResponse>> GetRoute(
        Guid activityId,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var route =
            await _routeService.GetByActivityIdAsync(
                userId,
                activityId,
                cancellationToken);

        if (route is null)
        {
            return NotFound();
        }

        return Ok(route);
    }

    [HttpPost("{activityId:guid}/route")]
    [ProducesResponseType(typeof(RouteResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RouteResponse>> CreateRoute(
    Guid activityId,
    [FromBody] CreateActivityRouteRequest request,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var result =
            await _routeService.CreateAsync(
                userId,
                activityId,
                request,
                cancellationToken);

        return Ok(result);
    }
}