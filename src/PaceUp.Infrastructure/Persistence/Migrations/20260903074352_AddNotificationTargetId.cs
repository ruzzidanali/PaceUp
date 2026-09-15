using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PaceUp.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationTargetId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "TargetId",
                table: "notifications",
                type: "uuid",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TargetId",
                table: "notifications");
        }
    }
}
