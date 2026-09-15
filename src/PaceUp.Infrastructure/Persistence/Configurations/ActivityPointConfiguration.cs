using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class ActivityPointConfiguration
    : IEntityTypeConfiguration<ActivityPoint>
{
    public void Configure(
        EntityTypeBuilder<ActivityPoint> builder
    )
    {
        builder.ToTable("activity_points");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Latitude)
            .IsRequired();

        builder.Property(x => x.Longitude)
            .IsRequired();

        builder.Property(x => x.Altitude)
            .IsRequired(false);

        builder.Property(x => x.Accuracy)
            .IsRequired(false);

        builder.Property(x => x.Speed)
            .IsRequired(false);

        builder.Property(x => x.HeartRate)
            .IsRequired(false);

        builder.Property(x => x.RecordedAt)
            .IsRequired();

        builder.HasOne(x => x.Activity)
            .WithMany()
            .HasForeignKey(x => x.ActivityId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new
        {
            x.ActivityId,
            x.RecordedAt
        });
    }
}