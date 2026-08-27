using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class ChallengeParticipantConfiguration
    : IEntityTypeConfiguration<ChallengeParticipant>
{
    public void Configure(
        EntityTypeBuilder<ChallengeParticipant> builder)
    {
        builder.ToTable("challenge_participants");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.JoinedAt)
            .IsRequired();

        builder.HasOne(x => x.Challenge)
            .WithMany(x => x.Participants)
            .HasForeignKey(x => x.ChallengeId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(
            x => new
            {
                x.ChallengeId,
                x.UserId
            })
            .IsUnique()
            .HasDatabaseName(
                "IX_challenge_participants_ChallengeId_UserId");

        builder.HasIndex(x => x.UserId)
            .HasDatabaseName(
                "IX_challenge_participants_UserId");

        builder.HasIndex(x => x.ChallengeId)
            .HasDatabaseName(
                "IX_challenge_participants_ChallengeId");
    }
}