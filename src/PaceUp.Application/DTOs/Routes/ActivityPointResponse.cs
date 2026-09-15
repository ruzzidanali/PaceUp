namespace PaceUp.Application.DTOs.Routes;

public record ActivityPointResponse(
    Guid Id,
    Guid ActivityId,
    double Latitude,
    double Longitude,
    double? Altitude,
    double? Accuracy,
    double? Speed,
    double? HeartRate,
    DateTime RecordedAt);
