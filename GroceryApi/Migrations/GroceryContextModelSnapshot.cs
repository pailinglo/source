﻿// <auto-generated />
using GroceryApi.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

#nullable disable

namespace GroceryApi.Migrations
{
    [DbContext(typeof(GroceryContext))]
    partial class GroceryContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "9.0.4")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("GroceryApi.Models.Ingredient", b =>
                {
                    b.Property<string>("IngredientId")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("IngredientId");

                    b.ToTable("Ingredients");
                });

            modelBuilder.Entity("GroceryApi.Models.Recipe", b =>
                {
                    b.Property<string>("RecipeId")
                        .HasColumnType("nvarchar(450)");

                    b.Property<int>("IngredientCount")
                        .HasColumnType("int");

                    b.Property<string>("Instructions")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("MajorIngredientCount")
                        .HasColumnType("int");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("RecipeId");

                    b.ToTable("Recipes");
                });

            modelBuilder.Entity("GroceryApi.Models.RecipeIngredient", b =>
                {
                    b.Property<string>("RecipeId")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("IngredientId")
                        .HasColumnType("nvarchar(450)");

                    b.Property<bool>("IsMajor")
                        .HasColumnType("bit");

                    b.HasKey("RecipeId", "IngredientId");

                    b.HasIndex("IngredientId");

                    b.ToTable("RecipeIngredients");
                });

            modelBuilder.Entity("GroceryApi.Models.RecipeRecommendation", b =>
                {
                    b.Property<int>("IngredientCount")
                        .HasColumnType("int");

                    b.Property<int>("MajorIngredientCount")
                        .HasColumnType("int");

                    b.Property<int>("MatchCount")
                        .HasColumnType("int");

                    b.Property<double>("MatchPercent")
                        .HasColumnType("float");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("RecipeId")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.ToTable((string)null);

                    b.ToView(null, (string)null);
                });

            modelBuilder.Entity("GroceryApi.Models.User", b =>
                {
                    b.Property<string>("UserId")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("UserId");

                    b.ToTable("Users");
                });

            modelBuilder.Entity("GroceryApi.Models.UserIngredient", b =>
                {
                    b.Property<string>("UserId")
                        .HasColumnType("nvarchar(450)");

                    b.Property<string>("IngredientId")
                        .HasColumnType("nvarchar(450)");

                    b.HasKey("UserId", "IngredientId");

                    b.HasIndex("IngredientId");

                    b.ToTable("UserIngredients");
                });

            modelBuilder.Entity("GroceryApi.Models.RecipeIngredient", b =>
                {
                    b.HasOne("GroceryApi.Models.Ingredient", "Ingredient")
                        .WithMany("RecipeIngredients")
                        .HasForeignKey("IngredientId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("GroceryApi.Models.Recipe", "Recipe")
                        .WithMany("RecipeIngredients")
                        .HasForeignKey("RecipeId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Ingredient");

                    b.Navigation("Recipe");
                });

            modelBuilder.Entity("GroceryApi.Models.UserIngredient", b =>
                {
                    b.HasOne("GroceryApi.Models.Ingredient", "Ingredient")
                        .WithMany("UserIngredients")
                        .HasForeignKey("IngredientId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("GroceryApi.Models.User", "User")
                        .WithMany("UserIngredients")
                        .HasForeignKey("UserId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Ingredient");

                    b.Navigation("User");
                });

            modelBuilder.Entity("GroceryApi.Models.Ingredient", b =>
                {
                    b.Navigation("RecipeIngredients");

                    b.Navigation("UserIngredients");
                });

            modelBuilder.Entity("GroceryApi.Models.Recipe", b =>
                {
                    b.Navigation("RecipeIngredients");
                });

            modelBuilder.Entity("GroceryApi.Models.User", b =>
                {
                    b.Navigation("UserIngredients");
                });
#pragma warning restore 612, 618
        }
    }
}
