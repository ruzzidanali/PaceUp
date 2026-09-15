namespace PaceUp.Application.DTOs.Routes;

public record CreateActivityPointRequest(
    double Latitude,
    double Longitude,
    double? Altitude,
    double? Accuracy,
    double? Speed,
    double? HeartRate,
    DateTime RecordedAt);