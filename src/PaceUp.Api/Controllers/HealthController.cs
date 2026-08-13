using Microsoft.AspNetCore.Mvc;

namespace PaceUp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            status = "healthy",
            service = "PaceUp API",
            timestamp = DateTime.UtcNow
        });
    }
}