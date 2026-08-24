using PaceUp.Application.DTOs.Activities;
using PaceUp.Application.Features.Activities;

namespace PaceUp.UnitTests.Activities;

public class ActivityTrendRequestValidatorTests
{
    private readonly ActivityTrendRequestValidator _validator = new();

    [Theory]
    [InlineData("day")]
    [InlineData("week")]
    [InlineData("month")]
    [InlineData("DAY")]
    [InlineData("Week")]
    public void ValidGroupBy_ShouldPass(
        string groupBy)
    {
        var request =
            new ActivityTrendRequest(
                GroupBy: groupBy);

        var result =
            _validator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("year")]
    [InlineData("hour")]
    [InlineData("")]
    [InlineData("invalid")]
    public void InvalidGroupBy_ShouldFail(
        string groupBy)
    {
        var request =
            new ActivityTrendRequest(
                GroupBy: groupBy);

        var result =
            _validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void ValidDateRange_ShouldPass()
    {
        var request =
            new ActivityTrendRequest(
                From: DateTime.UtcNow.AddDays(-7),
                To: DateTime.UtcNow);

        var result =
            _validator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public void InvalidDateRange_ShouldFail()
    {
        var request =
            new ActivityTrendRequest(
                From: DateTime.UtcNow,
                To: DateTime.UtcNow.AddDays(-7));

        var result =
            _validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void ValidActivityType_ShouldPass()
    {
        var request =
            new ActivityTrendRequest(
                Type: "Run");

        var result =
            _validator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public void InvalidActivityType_ShouldFail()
    {
        var request =
            new ActivityTrendRequest(
                Type: "Football");

        var result =
            _validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void NullActivityType_ShouldPass()
    {
        var request =
            new ActivityTrendRequest(
                Type: null);

        var result =
            _validator.Validate(request);

        Assert.True(result.IsValid);
    }
}