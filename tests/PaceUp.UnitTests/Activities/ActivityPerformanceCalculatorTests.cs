using PaceUp.Application.Features.Activities;

namespace PaceUp.UnitTests.Activities;

public class ActivityPerformanceCalculatorTests
{
    [Fact]
    public void CalculateAverageSpeedKmh_ShouldCalculateCorrectly()
    {
        var result =
            ActivityPerformanceCalculator.CalculateAverageSpeedKmh(
                10,
                3600);

        Assert.Equal(10, result);
    }

    [Fact]
    public void CalculateAveragePaceSecondsPerKm_ShouldCalculateCorrectly()
    {
        var result =
            ActivityPerformanceCalculator.CalculateAveragePaceSecondsPerKm(
                10,
                3600);

        Assert.Equal(360, result);
    }

    [Fact]
    public void CalculateBestSpeedKmh_ShouldConvertMetersPerSecond()
    {
        var result =
            ActivityPerformanceCalculator.CalculateBestSpeedKmh(5);

        Assert.Equal(18, result);
    }

    [Fact]
    public void CalculateBestPaceSecondsPerKm_ShouldCalculateCorrectly()
    {
        var result =
            ActivityPerformanceCalculator.CalculateBestPaceSecondsPerKm(12);

        Assert.Equal(300, result);
    }

    [Fact]
    public void CalculateAverageSpeedKmh_ShouldReturnNullForZeroDistance()
    {
        var result =
            ActivityPerformanceCalculator.CalculateAverageSpeedKmh(
                0,
                3600);

        Assert.Null(result);
    }

    [Fact]
    public void CalculateAveragePaceSecondsPerKm_ShouldReturnNullForZeroDistance()
    {
        var result =
            ActivityPerformanceCalculator.CalculateAveragePaceSecondsPerKm(
                0,
                3600);

        Assert.Null(result);
    }

    [Fact]
    public void CalculateAverageSpeedKmh_ShouldReturnNullForZeroDuration()
    {
        var result =
            ActivityPerformanceCalculator.CalculateAverageSpeedKmh(
                10,
                0);

        Assert.Null(result);
    }

    [Fact]
    public void CalculateAveragePaceSecondsPerKm_ShouldReturnNullForZeroDuration()
    {
        var result =
            ActivityPerformanceCalculator.CalculateAveragePaceSecondsPerKm(
                10,
                0);

        Assert.Null(result);
    }

    [Fact]
    public void CalculateBestSpeedKmh_ShouldReturnNullForNullSpeed()
    {
        var result =
            ActivityPerformanceCalculator.CalculateBestSpeedKmh(null);

        Assert.Null(result);
    }

    [Fact]
    public void CalculateBestSpeedKmh_ShouldReturnNullForZeroSpeed()
    {
        var result =
            ActivityPerformanceCalculator.CalculateBestSpeedKmh(0);

        Assert.Null(result);
    }

    [Fact]
    public void CalculateBestPaceSecondsPerKm_ShouldReturnNullForNullSpeed()
    {
        var result =
            ActivityPerformanceCalculator.CalculateBestPaceSecondsPerKm(null);

        Assert.Null(result);
    }

    [Fact]
    public void CalculateBestPaceSecondsPerKm_ShouldReturnNullForZeroSpeed()
    {
        var result =
            ActivityPerformanceCalculator.CalculateBestPaceSecondsPerKm(0);

        Assert.Null(result);
    }
}