using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class FollowConfiguration
    : IEntityTypeConfiguration<Follow>
{
    public void Configure(
        EntityTypeBuilder<Follow> builder)
    {
        builder.ToTable("follows");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.CreatedAt)
            .IsRequired();

        builder.HasOne(x => x.Follower)
            .WithMany()
            .HasForeignKey(x => x.FollowerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Following)
            .WithMany()
            .HasForeignKey(x => x.FollowingId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(
            x => new
            {
                x.FollowerId,
                x.FollowingId
            })
            .IsUnique()
            .HasDatabaseName(
                "IX_follows_FollowerId_FollowingId");

        builder.HasIndex(
            x => x.FollowingId)
            .HasDatabaseName(
                "IX_follows_FollowingId");

        builder.HasIndex(
            x => x.FollowerId)
            .HasDatabaseName(
                "IX_follows_FollowerId");
    }
}