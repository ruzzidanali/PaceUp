using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Notifications;
using PaceUp.Application.DTOs.Notifications;

namespace PaceUp.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(
        INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(IReadOnlyList<NotificationResponse>),
        StatusCodes.Status200OK)]
    public async Task<
        ActionResult<IReadOnlyList<NotificationResponse>>> Get(
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var notifications =
            await _notificationService.GetAsync(
                userId,
                cancellationToken);

        return Ok(notifications);
    }

    [HttpPatch("{id:guid}/read")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkAsRead(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var marked =
            await _notificationService.MarkAsReadAsync(
                userId,
                id,
                cancellationToken);

        if (!marked)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpPost("read-all")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> MarkAllAsRead(
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        await _notificationService.MarkAllAsReadAsync(
            userId,
            cancellationToken);

        return NoContent();
    }
}