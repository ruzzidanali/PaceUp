using PaceUp.Domain.Constants;

namespace PaceUp.Domain.Entities;

public class XpTransaction
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public int Amount { get; private set; }

    public string SourceType { get; private set; } = null!;

    public Guid? SourceId { get; private set; }

    public DateTime CreatedAt { get; private set; }

    public User User { get; private set; } = null!;

    private XpTransaction()
    {
    }

    public XpTransaction(
        Guid userId,
        int amount,
        string sourceType,
        Guid? sourceId)
    {
        if (amount <= 0)
        {
            throw new ArgumentException(
                "XP amount must be greater than zero.",
                nameof(amount));
        }

        if (!XpSourceTypes.IsValid(sourceType))
        {
            throw new ArgumentException(
                $"Unsupported XP source type: {sourceType}",
                nameof(sourceType));
        }

        Id = Guid.NewGuid();

        UserId = userId;
        Amount = amount;
        SourceType = sourceType;
        SourceId = sourceId;

        CreatedAt = DateTime.UtcNow;
    }
}