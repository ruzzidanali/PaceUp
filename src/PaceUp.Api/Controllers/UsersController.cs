using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.Users;
using PaceUp.Application.DTOs.Users;
using Microsoft.AspNetCore.Authorization;
using PaceUp.Api.Extensions;
using Microsoft.AspNetCore.Http;
using System.IO;

namespace PaceUp.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/users")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpPost]
    [ProducesResponseType(
        typeof(UserResponse),
        StatusCodes.Status201Created)]
    public async Task<ActionResult<UserResponse>> Create(
        [FromBody] CreateUserRequest request,
        CancellationToken cancellationToken)
    {
        var user = await _userService.CreateAsync(
            request,
            cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new { id = user.Id },
            user);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(
        typeof(UserResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserResponse>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var user = await _userService.GetByIdAsync(
            id,
            cancellationToken);

        if (user is null)
        {
            return NotFound();
        }

        return Ok(user);
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserResponse>> GetMe(
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var user =
            await _userService.GetByIdAsync(
                userId,
                cancellationToken);

        if (user is null)
        {
            return NotFound();
        }

        return Ok(user);
    }

    [HttpPut("me")]
    [ProducesResponseType(
    typeof(UserResponse),
    StatusCodes.Status200OK)]
    [ProducesResponseType(
    StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserResponse>> UpdateMe(
    [FromBody] UpdateProfileRequest request,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var user =
            await _userService.UpdateProfileAsync(
                userId,
                request,
                cancellationToken);

        if (user is null)
        {
            return NotFound();
        }

        return Ok(user);
    }

    [HttpPost("me/profile-image")]
    [ProducesResponseType(
    typeof(UserResponse),
    StatusCodes.Status200OK)]
    [ProducesResponseType(
    StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
    StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserResponse>> UpdateProfileImage(
    IFormFile file,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        if (file is null || file.Length == 0)
        {
            return BadRequest("Profile image is required.");
        }

        const long maxFileSize = 5 * 1024 * 1024;

        if (file.Length > maxFileSize)
        {
            return BadRequest(
                "Profile image must be 5 MB or smaller.");
        }

        var contentType = file.ContentType
            .Trim()
            .ToLowerInvariant();

        var extension = contentType switch
        {
            "image/jpeg" => ".jpg",
            "image/jpg" => ".jpg",
            "image/png" => ".png",
            "image/webp" => ".webp",
            "image/heic" => ".heic",
            "image/heif" => ".heif",
            _ => null,
        };

        if (extension is null)
        {
            return BadRequest(
                $"Unsupported image type: {file.ContentType}");
        }

        var uploadsPath = Path.Combine(
            Directory.GetCurrentDirectory(),
            "wwwroot",
            "uploads",
            "profile-images");

        Directory.CreateDirectory(uploadsPath);

        var fileName = $"{Guid.NewGuid():N}{extension}";

        var filePath = Path.Combine(
            uploadsPath,
            fileName);

        await using (var stream = System.IO.File.Create(filePath))
        {
            await file.CopyToAsync(
                stream,
                cancellationToken);
        }

        var imageUrl =
            $"{Request.Scheme}://{Request.Host}/uploads/profile-images/{fileName}";

        var user =
            await _userService.UpdateProfileImageAsync(
                userId,
                new UpdateProfileImageRequest(imageUrl),
                cancellationToken);

        if (user is null)
        {
            System.IO.File.Delete(filePath);

            return NotFound();
        }

        return Ok(user);
    }

    [HttpDelete("me")]
    [ProducesResponseType(
    StatusCodes.Status204NoContent)]
    [ProducesResponseType(
    StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteMe(
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var deleted =
            await _userService.DeleteAsync(
                userId,
                cancellationToken);

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpPost("{id:guid}/follow")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Follow(
    Guid id,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var followed =
            await _userService.FollowAsync(
                userId,
                id,
                cancellationToken);

        if (!followed)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpDelete("{id:guid}/follow")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Unfollow(
        Guid id,
        CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var unfollowed =
            await _userService.UnfollowAsync(
                userId,
                id,
                cancellationToken);

        if (!unfollowed)
        {
            return NotFound();
        }

        return NoContent();
    }

    [AllowAnonymous]
    [HttpGet("{id:guid}/followers")]
    [ProducesResponseType(
        typeof(FollowListResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FollowListResponse>> GetFollowers(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result =
            await _userService.GetFollowersAsync(
                id,
                cancellationToken);

        if (result is null)
        {
            return NotFound();
        }

        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet("{id:guid}/following")]
    [ProducesResponseType(
        typeof(FollowListResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FollowListResponse>> GetFollowing(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result =
            await _userService.GetFollowingAsync(
                id,
                cancellationToken);

        if (result is null)
        {
            return NotFound();
        }

        return Ok(result);
    }
}