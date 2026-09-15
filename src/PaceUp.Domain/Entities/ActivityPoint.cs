namespace PaceUp.Domain.Entities;

public class ActivityPoint
{
    public Guid Id { get; private set; }

    public Guid ActivityId { get; private set; }

    public double Latitude { get; private set; }

    public double Longitude { get; private set; }

    public double? Altitude { get; private set; }

    public double? Accuracy { get; private set; }

    public double? Speed { get; private set; }

    public double? HeartRate { get; private set; }

    public DateTime RecordedAt { get; private set; }

    public Activity Activity { get; private set; } = null!;

    private ActivityPoint()
    {
    }

    public ActivityPoint(
        Guid activityId,
        double latitude,
        double longitude,
        double? altitude,
        double? accuracy,
        double? speed,
        double? heartRate,
        DateTime recordedAt)
    {
        if (latitude is < -90 or > 90)
        {
            throw new ArgumentException(
                "Latitude must be between -90 and 90.",
                nameof(latitude));
        }

        if (longitude is < -180 or > 180)
        {
            throw new ArgumentException(
                "Longitude must be between -180 and 180.",
                nameof(longitude));
        }

        if (altitude.HasValue &&
            !double.IsFinite(altitude.Value))
        {
            throw new ArgumentException(
                "Altitude must be a finite number.",
                nameof(altitude));
        }

        if (accuracy.HasValue &&
            (!double.IsFinite(accuracy.Value) ||
             accuracy.Value < 0))
        {
            throw new ArgumentException(
                "Accuracy must be a non-negative finite number.",
                nameof(accuracy));
        }

        if (speed.HasValue &&
            (!double.IsFinite(speed.Value) ||
             speed.Value < 0))
        {
            throw new ArgumentException(
                "Speed must be a non-negative finite number.",
                nameof(speed));
        }

        if (heartRate.HasValue &&
            (heartRate.Value <= 0 ||
             !double.IsFinite(heartRate.Value)))
        {
            throw new ArgumentException(
                "Heart rate must be a positive finite number.",
                nameof(heartRate));
        }

        Id = Guid.NewGuid();

        ActivityId = activityId;
        Latitude = latitude;
        Longitude = longitude;
        Altitude = altitude;
        Accuracy = accuracy;
        Speed = speed;
        HeartRate = heartRate;
        RecordedAt = recordedAt;
    }
}