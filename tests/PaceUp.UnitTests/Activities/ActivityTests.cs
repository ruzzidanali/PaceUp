using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Activities;

public class ActivityTests
{
    private static readonly Guid UserId =
        Guid.NewGuid();

    [Fact]
    public void Constructor_WithInvalidType_ShouldThrow()
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            new Activity(
                UserId,
                "InvalidActivityType",
                5,
                1800,
                300,
                DateTime.UtcNow));

        Assert.Contains(
            "Unsupported activity type",
            exception.Message);
    }

    [Fact]
    public void Update_WithInvalidType_ShouldThrow()
    {
        var activity =
            new Activity(
                UserId,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow);

        var exception = Assert.Throws<ArgumentException>(() =>
            activity.Update(
                "InvalidActivityType",
                10,
                3600,
                500,
                DateTime.UtcNow));

        Assert.Contains(
            "Unsupported activity type",
            exception.Message);
    }

    [Fact]
    public void Constructor_WithNegativeDistance_ShouldThrow()
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            new Activity(
                UserId,
                "Run",
                -5,
                1800,
                300,
                DateTime.UtcNow));

        Assert.Contains(
            "Distance",
            exception.Message);
    }

    [Fact]
    public void Update_WithNegativeDistance_ShouldThrow()
    {
        var activity =
            new Activity(
                UserId,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow);

        var exception = Assert.Throws<ArgumentException>(() =>
            activity.Update(
                "Run",
                -10,
                3600,
                500,
                DateTime.UtcNow));

        Assert.Contains(
            "Distance",
            exception.Message);
    }

    [Fact]
    public void Constructor_WithZeroDuration_ShouldThrow()
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            new Activity(
                UserId,
                "Run",
                5,
                0,
                300,
                DateTime.UtcNow));

        Assert.Contains(
            "Duration must be greater than zero",
            exception.Message);
    }

    [Fact]
    public void Update_WithNegativeCalories_ShouldThrow()
    {
        var activity =
            new Activity(
                UserId,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow);

        var exception = Assert.Throws<ArgumentException>(() =>
            activity.Update(
                "Run",
                5,
                1800,
                -100,
                DateTime.UtcNow));

        Assert.Contains(
            "Calories cannot be negative",
            exception.Message);
    }

    [Fact]
    public void Constructor_WithNonFiniteDistance_ShouldThrow()
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            new Activity(
                UserId,
                "Run",
                double.NaN,
                1800,
                300,
                DateTime.UtcNow));

        Assert.Contains(
            "Distance must be a finite number",
            exception.Message);
    }

    [Fact]
    public void Update_WithNonFiniteDistance_ShouldThrow()
    {
        var activity =
            new Activity(
                UserId,
                "Run",
                5,
                1800,
                300,
                DateTime.UtcNow);

        var exception = Assert.Throws<ArgumentException>(() =>
            activity.Update(
                "Run",
                double.PositiveInfinity,
                1800,
                300,
                DateTime.UtcNow));

        Assert.Contains(
            "Distance must be a finite number",
            exception.Message);
    }
}