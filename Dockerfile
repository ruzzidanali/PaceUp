# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files first for better Docker layer caching
COPY ["NuGet.Docker.Config", "NuGet.Docker.Config"]

COPY ["src/PaceUp.Api/PaceUp.Api.csproj", "src/PaceUp.Api/"]
COPY ["src/PaceUp.Application/PaceUp.Application.csproj", "src/PaceUp.Application/"]
COPY ["src/PaceUp.Domain/PaceUp.Domain.csproj", "src/PaceUp.Domain/"]
COPY ["src/PaceUp.Infrastructure/PaceUp.Infrastructure.csproj", "src/PaceUp.Infrastructure/"]

RUN dotnet restore "src/PaceUp.Api/PaceUp.Api.csproj" \
    --configfile /src/NuGet.Docker.Config

# Copy the remaining source
COPY . .

# Build
RUN dotnet build "src/PaceUp.Api/PaceUp.Api.csproj" \
    -c Release \
    --no-restore \
    -o /app/build

# Publish stage
FROM build AS publish

RUN dotnet publish "src/PaceUp.Api/PaceUp.Api.csproj" \
    -c Release \
    --no-restore \
    -o /app/publish \
    /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

COPY --from=publish /app/publish .

ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

EXPOSE 8080

ENTRYPOINT ["dotnet", "PaceUp.Api.dll"]