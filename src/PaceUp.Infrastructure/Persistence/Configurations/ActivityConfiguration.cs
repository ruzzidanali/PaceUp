using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class ActivityConfiguration
    : IEntityTypeConfiguration<Activity>
{
    public void Configure(
        EntityTypeBuilder<Activity> builder)
    {
        builder.ToTable("activities");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Type)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(x => x.Distance)
            .IsRequired();

        builder.Property(x => x.DurationSeconds)
            .IsRequired();

        builder.Property(x => x.Calories)
            .IsRequired(false);

        builder.Property(x => x.StartedAt)
            .IsRequired();

        builder.Property(x => x.CreatedAt)
            .IsRequired();

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new
        {
            x.UserId,
            x.StartedAt
        });
    }
}