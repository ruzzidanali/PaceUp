using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class KudosConfiguration
    : IEntityTypeConfiguration<Kudos>
{
    public void Configure(
        EntityTypeBuilder<Kudos> builder)
    {
        builder.ToTable("kudos");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.CreatedAt)
            .IsRequired();

        builder.HasOne(x => x.Activity)
            .WithMany()
            .HasForeignKey(x => x.ActivityId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new
        {
            x.ActivityId,
            x.UserId
        })
        .IsUnique();

        builder.HasIndex(x => new
        {
            x.ActivityId,
            x.CreatedAt
        });
    }
}