using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class UserIdentityConfiguration
    : IEntityTypeConfiguration<UserIdentity>
{
    public void Configure(
        EntityTypeBuilder<UserIdentity> builder)
    {
        builder.ToTable("user_identities");

        builder.HasKey(x => x.UserId);

        builder.Property(x => x.PasswordHash)
            .IsRequired();

        builder.Property(x => x.SecurityStamp)
            .IsRequired()
            .HasMaxLength(32);

        builder.Property(x => x.EmailVerified)
            .IsRequired();

        builder.Property(x => x.FailedLoginAttempts)
    .IsRequired();

        builder.Property(x => x.LockedUntil);

        builder.Property(x => x.CreatedAt)
            .IsRequired();

        builder.HasOne(x => x.User)
            .WithOne(x => x.Identity)
            .HasForeignKey<UserIdentity>(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}