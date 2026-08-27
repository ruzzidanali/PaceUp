using PaceUp.Domain.Constants;

namespace PaceUp.Domain.Entities;

public class Challenge
{
    public Guid Id { get; private set; }

    public Guid CreatedByUserId { get; private set; }

    public string Name { get; private set; } = null!;

    public string? Description { get; private set; }

    public string Type { get; private set; } = null!;

    public double TargetValue { get; private set; }

    public DateTime StartDate { get; private set; }

    public DateTime EndDate { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public User CreatedByUser { get; private set; } = null!;

    public ICollection<ChallengeParticipant> Participants { get; private set; }
        = new List<ChallengeParticipant>();

    private Challenge()
    {
    }

    public Challenge(
        Guid createdByUserId,
        string name,
        string? description,
        string type,
        double targetValue,
        DateTime startDate,
        DateTime endDate)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException(
                "Challenge name is required.",
                nameof(name));
        }

        if (!ChallengeTypes.IsValid(type))
        {
            throw new ArgumentException(
                $"Unsupported challenge type: {type}",
                nameof(type));
        }

        if (!double.IsFinite(targetValue))
        {
            throw new ArgumentException(
                "Challenge target must be a finite number.",
                nameof(targetValue));
        }

        if (targetValue <= 0)
        {
            throw new ArgumentException(
                "Challenge target must be greater than zero.",
                nameof(targetValue));
        }

        if (endDate < startDate)
        {
            throw new ArgumentException(
                "Challenge end date must be greater than or equal to the start date.",
                nameof(endDate));
        }

        Id = Guid.NewGuid();

        CreatedByUserId = createdByUserId;
        Name = name.Trim();
        Description = string.IsNullOrWhiteSpace(description)
            ? null
            : description.Trim();

        Type = type;
        TargetValue = targetValue;
        StartDate = startDate;
        EndDate = endDate;

        CreatedAt = DateTime.UtcNow;
    }

    public void Update(
        string name,
        string? description,
        string type,
        double targetValue,
        DateTime startDate,
        DateTime endDate)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException(
                "Challenge name is required.",
                nameof(name));
        }

        if (!ChallengeTypes.IsValid(type))
        {
            throw new ArgumentException(
                $"Unsupported challenge type: {type}",
                nameof(type));
        }

        if (!double.IsFinite(targetValue))
        {
            throw new ArgumentException(
                "Challenge target must be a finite number.",
                nameof(targetValue));
        }

        if (targetValue <= 0)
        {
            throw new ArgumentException(
                "Challenge target must be greater than zero.",
                nameof(targetValue));
        }

        if (endDate < startDate)
        {
            throw new ArgumentException(
                "Challenge end date must be greater than or equal to the start date.",
                nameof(endDate));
        }

        Name = name.Trim();

        Description = string.IsNullOrWhiteSpace(description)
            ? null
            : description.Trim();

        Type = type;
        TargetValue = targetValue;
        StartDate = startDate;
        EndDate = endDate;
    }
}