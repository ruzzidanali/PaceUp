using PaceUp.Application.Abstractions.Communication;

namespace PaceUp.IntegrationTests.Infrastructure;

public sealed class FakeEmailService : IEmailService
{
    public List<(string Email, string ResetToken)> SentPasswordResetEmails { get; } = [];

    public Task SendPasswordResetEmailAsync(
        string email,
        string resetToken,
        CancellationToken cancellationToken)
    {
        SentPasswordResetEmails.Add((email, resetToken));

        return Task.CompletedTask;
    }
}