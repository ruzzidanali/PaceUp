namespace PaceUp.Domain.Entities;

public class Achievement
{
    public Guid Id { get; private set; }

    public string Code { get; private set; } = null!;

    public string Name { get; private set; } = null!;

    public string Description { get; private set; } = null!;

    public string Icon { get; private set; } = null!;

    public string RequirementType { get; private set; } = null!;

    public double RequirementValue { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public ICollection<UserAchievement> UserAchievements { get; private set; }
        = new List<UserAchievement>();

    private Achievement()
    {
    }

    public Achievement(
        string code,
        string name,
        string description,
        string icon,
        string requirementType,
        double requirementValue)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            throw new ArgumentException(
                "Achievement code is required.",
                nameof(code));
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException(
                "Achievement name is required.",
                nameof(name));
        }

        if (string.IsNullOrWhiteSpace(description))
        {
            throw new ArgumentException(
                "Achievement description is required.",
                nameof(description));
        }

        if (string.IsNullOrWhiteSpace(icon))
        {
            throw new ArgumentException(
                "Achievement icon is required.",
                nameof(icon));
        }

        if (string.IsNullOrWhiteSpace(requirementType))
        {
            throw new ArgumentException(
                "Achievement requirement type is required.",
                nameof(requirementType));
        }

        if (!double.IsFinite(requirementValue))
        {
            throw new ArgumentException(
                "Achievement requirement value must be a finite number.",
                nameof(requirementValue));
        }

        if (requirementValue <= 0)
        {
            throw new ArgumentException(
                "Achievement requirement value must be greater than zero.",
                nameof(requirementValue));
        }

        Id = Guid.NewGuid();

        Code = code.Trim();
        Name = name.Trim();
        Description = description.Trim();
        Icon = icon.Trim();
        RequirementType = requirementType.Trim();
        RequirementValue = requirementValue;

        CreatedAt = DateTime.UtcNow;
    }
}