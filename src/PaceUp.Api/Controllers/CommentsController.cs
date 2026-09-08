using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Api.Extensions;
using PaceUp.Application.Abstractions.Comments;
using PaceUp.Application.DTOs.Comments;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/activities/{activityId:guid}/comments")]
public class CommentsController : ControllerBase
{
    private readonly ICommentService _commentService;

    public CommentsController(ICommentService commentService) => _commentService = commentService;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CommentResponse>>> Get(
        Guid activityId,
        CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _commentService.GetAsync(
                User.GetUserId(), activityId, cancellationToken));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost]
    public async Task<ActionResult<CommentResponse>> Create(
        Guid activityId,
        CreateCommentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _commentService.CreateAsync(
                User.GetUserId(), activityId, request, cancellationToken);

            return CreatedAtAction(nameof(Get), new { activityId }, result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{commentId:guid}")]
    public async Task<IActionResult> Delete(
        Guid activityId,
        Guid commentId,
        CancellationToken cancellationToken)
    {
        var deleted = await _commentService.DeleteAsync(
            User.GetUserId(), commentId, cancellationToken);

        return deleted ? NoContent() : NotFound();
    }
}