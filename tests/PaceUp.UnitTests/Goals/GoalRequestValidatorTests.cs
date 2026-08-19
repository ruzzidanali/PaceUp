using PaceUp.Application.DTOs.Goals;
using PaceUp.Application.Features.Goals;

namespace PaceUp.UnitTests.Goals;

public class GoalRequestValidatorTests
{
    private readonly CreateGoalRequestValidator _validator = new();

    [Fact]
    public async Task Create_WithValidRequest_ShouldPass()
    {
        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Distance",
            50,
            startDate,
            startDate.AddDays(6));

        var result = await _validator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task Create_WithInvalidType_ShouldFail()
    {
        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Invalid",
            50,
            startDate,
            startDate.AddDays(6));

        var result = await _validator.ValidateAsync(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task Create_WithZeroTarget_ShouldFail()
    {
        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Distance",
            0,
            startDate,
            startDate.AddDays(6));

        var result = await _validator.ValidateAsync(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task Create_WithEndDateBeforeStartDate_ShouldFail()
    {
        var startDate = DateTime.UtcNow.Date;

        var request = new CreateGoalRequest(
            "Distance",
            50,
            startDate,
            startDate.AddDays(-1));

        var result = await _validator.ValidateAsync(request);

        Assert.False(result.IsValid);
    }
}