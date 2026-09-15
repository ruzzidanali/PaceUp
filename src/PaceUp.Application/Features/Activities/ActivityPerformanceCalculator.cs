namespace PaceUp.Application.Features.Activities;

public static class ActivityPerformanceCalculator
{
    private const double MetersPerSecondToKilometersPerHour = 3.6;

    public static double? CalculateAverageSpeedKmh(
        double distanceKm,
        int durationSeconds)
    {
        if (!double.IsFinite(distanceKm) ||
            distanceKm <= 0 ||
            durationSeconds <= 0)
        {
            return null;
        }

        return distanceKm * 3600d / durationSeconds;
    }

    public static double? CalculateAveragePaceSecondsPerKm(
        double distanceKm,
        int durationSeconds)
    {
        if (!double.IsFinite(distanceKm) ||
            distanceKm <= 0 ||
            durationSeconds <= 0)
        {
            return null;
        }

        return durationSeconds / distanceKm;
    }

    public static double? CalculateBestSpeedKmh(
        double? speedMetersPerSecond)
    {
        if (!speedMetersPerSecond.HasValue ||
            !double.IsFinite(speedMetersPerSecond.Value) ||
            speedMetersPerSecond.Value <= 0)
        {
            return null;
        }

        return speedMetersPerSecond.Value *
               MetersPerSecondToKilometersPerHour;
    }

    public static double? CalculateBestPaceSecondsPerKm(
        double? bestSpeedKmh)
    {
        if (!bestSpeedKmh.HasValue ||
            !double.IsFinite(bestSpeedKmh.Value) ||
            bestSpeedKmh.Value <= 0)
        {
            return null;
        }

        return 3600d / bestSpeedKmh.Value;
    }
}