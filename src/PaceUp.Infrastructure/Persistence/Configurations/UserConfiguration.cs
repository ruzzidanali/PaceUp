using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(
        EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Username)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(x => x.Email)
            .IsRequired()
            .HasMaxLength(255);

        builder.Property(x => x.DisplayName)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(x => x.Bio)
            .HasMaxLength(500);

        builder.Property(x => x.ProfileImageUrl)
            .HasMaxLength(500);

        builder.Property(x => x.CreatedAt)
            .IsRequired();

        builder.HasIndex(x => x.Username)
            .IsUnique();

        builder.HasIndex(x => x.Email)
            .IsUnique();
    }
}