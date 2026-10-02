using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.Users;
using PaceUp.Application.DTOs.Users;
using Microsoft.AspNetCore.Authorization;
using PaceUp.Api.Extensions;
using Microsoft.AspNetCore.Http;
using System.IO;
using PaceUp.Infrastructure.Storage;

namespace PaceUp.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/users")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IProfileImageStorage _profileImageStorage;

    public UsersController(IUserService userService, IProfileImageStorage profileImageStorage)
    {
        _userService = userService;
        _profileImageStorage = profileImageStorage;
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

    private static bool HasValidImageSignature(
        IFormFile file,
        string extension
    )
    {
        using var stream = file.OpenReadStream();

        Span<byte> header = stackalloc byte[12];

        var bytesRead = stream.Read(header);

        return extension switch
        {
            ".jpg" =>
                bytesRead >= 3 &&
                header[0] == 0xFF &&
                header[1] == 0xD8 &&
                header[2] == 0xFF,

            ".png" =>
                bytesRead >= 8 &&
                header[0] == 0x89 &&
                header[1] == 0x50 &&
                header[2] == 0x4E &&
                header[3] == 0x47 &&
                header[4] == 0x0D &&
                header[5] == 0x0A &&
                header[6] == 0x1A &&
                header[7] == 0x0A,

            ".webp" =>
                bytesRead >= 12 &&
                header[0] == (byte)'R' &&
                header[1] == (byte)'I' &&
                header[2] == (byte)'F' &&
                header[3] == (byte)'F' &&
                header[8] == (byte)'W' &&
                header[9] == (byte)'E' &&
                header[10] == (byte)'B' &&
                header[11] == (byte)'P',

            _ => false
        };
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

    [HttpPut("me/profile-image")]
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
            _ => null,
        };

        if (extension is null)
        {
            return BadRequest(
                $"Unsupported image type: {file.ContentType}");
        }

        if (!HasValidImageSignature(file, extension))
        {
            return BadRequest(
                "The uploaded file does not match its declared image type.");
        }

        var currentUser =
            await _userService.GetByIdAsync(
                userId,
                cancellationToken);

        if (currentUser is null)
        {
            return NotFound();
        }

        var previousImageUrl =
            currentUser.ProfileImageUrl;

        var fileName =
            $"{Guid.NewGuid():N}{extension}";

        string imageUrl;

        await using (var stream = file.OpenReadStream())
        {
            imageUrl = await _profileImageStorage.UploadAsync(
                stream,
                fileName,
                contentType,
                cancellationToken
            );
        }

        UserResponse? user;

        try
        {
            user =
                await _userService.UpdateProfileImageAsync(
                    userId,
                    new UpdateProfileImageRequest(imageUrl),
                    cancellationToken
                );
        }
        catch
        {
            await _profileImageStorage.DeleteAsync(
                fileName,
                cancellationToken
            );

            throw;
        }

        if (user is null)
        {
            await _profileImageStorage.DeleteAsync(
                fileName,
                cancellationToken
            );

            return NotFound();
        }

        if (!string.IsNullOrWhiteSpace(previousImageUrl))
        {
            try
            {
                var previousFileName =
                    Path.GetFileName(
                        new Uri(previousImageUrl).AbsolutePath);

                if (!string.Equals(
                    previousFileName,
                    fileName,
                    StringComparison.OrdinalIgnoreCase))
                {
                    await _profileImageStorage.DeleteAsync(
                        previousFileName,
                        cancellationToken);
                }
            }
            catch
            {
                // The profile update has already succeeded.
                // Failure to remove the old image should not fail the request.
            }
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

    [HttpGet("{id:guid}/follow-status")]
    [ProducesResponseType(
    typeof(FollowStatusResponse),
    StatusCodes.Status200OK)]
    [ProducesResponseType(
    StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FollowStatusResponse>> GetFollowStatus(
    Guid id,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var user = await _userService.GetByIdAsync(
            id,
            cancellationToken);

        if (user is null)
        {
            return NotFound();
        }

        var isFollowing =
            await _userService.IsFollowingAsync(
                userId,
                id,
                cancellationToken);

        return Ok(
            new FollowStatusResponse(isFollowing));
    }

    [HttpGet("search")]
    [ProducesResponseType(
    typeof(IReadOnlyList<UserSearchResponse>),
    StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<UserSearchResponse>>> Search(
    [FromQuery] string query,
    CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();

        var users =
            await _userService.SearchAsync(
                userId,
                query,
                cancellationToken);

        return Ok(users);
    }
}