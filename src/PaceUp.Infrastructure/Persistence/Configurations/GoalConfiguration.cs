using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Configurations;

public class GoalConfiguration : IEntityTypeConfiguration<Goal>
{
    public void Configure(
        EntityTypeBuilder<Goal> builder
    )
    {
        builder.ToTable("goals");
        
        builder.HasKey(x => x.Id);
        
        builder.Property(x => x.Type)
            .HasMaxLength(50)
            .IsRequired();
        
        builder.Property(x => x.Target)
            .IsRequired();

        builder.Property(x => x.StartDate)
            .IsRequired();

        builder.Property(x => x.EndDate)
            .IsRequired();

        builder.Property(x => x.CreatedAt)
            .IsRequired();

        builder.Property(x => x.UpdatedAt)
            .IsRequired();

        builder.HasOne(x => x.User)
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(
            x => new
            {
                x.UserId,
                x.StartDate,
                x.EndDate
            }
        ).HasDatabaseName("IX_goals_UserId_StartDate_EndDate");
    }
}