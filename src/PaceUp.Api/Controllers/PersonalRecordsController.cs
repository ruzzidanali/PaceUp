using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Abstractions.PersonalRecords;
using PaceUp.Application.DTOs.PersonalRecords;

namespace PaceUp.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/personal-records")]
public class PersonalRecordsController : ControllerBase
{
    private readonly IPersonalRecordService _personalRecordService;

    public PersonalRecordsController(
        IPersonalRecordService personalRecordService)
    {
        _personalRecordService = personalRecordService;
    }

    [HttpGet]
    [ProducesResponseType(
        typeof(PersonalRecordResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<PersonalRecordResponse>> Get(
        CancellationToken cancellationToken)
    {
        var userIdClaim =
            User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        var result =
            await _personalRecordService.GetAsync(
                userId,
                cancellationToken);

        return Ok(result);
    }
}