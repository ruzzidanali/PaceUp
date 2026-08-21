using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.Features.Activities;

namespace PaceUp.UnitTests.Activities;

public class ActivityRequestValidatorTests
{
    private readonly CreateActivityRequestValidator _createValidator = new();
    private readonly UpdateActivityRequestValidator _updateValidator = new();

    [Fact]
    public async Task Create_WithValidRequest_ShouldPass()
    {
        var request = new CreateActivityRequest(
            "Run",
            5,
            1800,
            300,
            DateTime.UtcNow);

        var result =
            await _createValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task Create_WithInvalidType_ShouldFail()
    {
        var request = new CreateActivityRequest(
            "FlyingToTheMoon",
            5,
            1800,
            300,
            DateTime.UtcNow);

        var result =
            await _createValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error => error.PropertyName == nameof(request.Type));
    }

    [Fact]
    public async Task Create_WithNegativeDistance_ShouldFail()
    {
        var request = new CreateActivityRequest(
            "Run",
            -1,
            1800,
            300,
            DateTime.UtcNow);

        var result =
            await _createValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error => error.PropertyName == nameof(request.Distance));
    }

    [Fact]
    public async Task Create_WithNonFiniteDistance_ShouldFail()
    {
        var requests = new[]
        {
            new CreateActivityRequest(
                "Run",
                double.NaN,
                1800,
                300,
                DateTime.UtcNow),

            new CreateActivityRequest(
                "Run",
                double.PositiveInfinity,
                1800,
                300,
                DateTime.UtcNow),

            new CreateActivityRequest(
                "Run",
                double.NegativeInfinity,
                1800,
                300,
                DateTime.UtcNow)
        };

        foreach (var request in requests)
        {
            var result =
                await _createValidator.ValidateAsync(request);

            Assert.False(result.IsValid);
            Assert.Contains(
                result.Errors,
                error =>
                    error.PropertyName ==
                    nameof(request.Distance));
        }
    }

    [Fact]
    public async Task Create_WithZeroDuration_ShouldFail()
    {
        var request = new CreateActivityRequest(
            "Run",
            5,
            0,
            300,
            DateTime.UtcNow);

        var result =
            await _createValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error =>
                error.PropertyName ==
                nameof(request.DurationSeconds));
    }

    [Fact]
    public async Task Create_WithNegativeCalories_ShouldFail()
    {
        var request = new CreateActivityRequest(
            "Run",
            5,
            1800,
            -100,
            DateTime.UtcNow);

        var result =
            await _createValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error =>
                error.PropertyName ==
                nameof(request.Calories));
    }

    [Fact]
    public async Task Create_WithNullCalories_ShouldPass()
    {
        var request = new CreateActivityRequest(
            "Run",
            5,
            1800,
            null,
            DateTime.UtcNow);

        var result =
            await _createValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task Update_WithInvalidType_ShouldFail()
    {
        var request = new UpdateActivityRequest(
            "FlyingToTheMoon",
            5,
            1800,
            300,
            DateTime.UtcNow);

        var result =
            await _updateValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error =>
                error.PropertyName ==
                nameof(request.Type));
    }

    [Fact]
    public async Task Update_WithNegativeDistance_ShouldFail()
    {
        var request = new UpdateActivityRequest(
            "Run",
            -1,
            1800,
            300,
            DateTime.UtcNow);

        var result =
            await _updateValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error =>
                error.PropertyName ==
                nameof(request.Distance));
    }

    [Fact]
    public async Task Update_WithZeroDuration_ShouldFail()
    {
        var request = new UpdateActivityRequest(
            "Run",
            5,
            0,
            300,
            DateTime.UtcNow);

        var result =
            await _updateValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error =>
                error.PropertyName ==
                nameof(request.DurationSeconds));
    }

    [Fact]
    public async Task Update_WithNegativeCalories_ShouldFail()
    {
        var request = new UpdateActivityRequest(
            "Run",
            5,
            1800,
            -100,
            DateTime.UtcNow);

        var result =
            await _updateValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            error =>
                error.PropertyName ==
                nameof(request.Calories));
    }
}