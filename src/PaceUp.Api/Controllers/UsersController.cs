using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.Users;
using PaceUp.Application.DTOs.Users;

namespace PaceUp.Api.Controllers;

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
}