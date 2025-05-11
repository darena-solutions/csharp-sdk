# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

# Install necessary native dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    clang \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Copy csproj files and restore as distinct layers
COPY ./samples/AspNetCoreSseServer/AspNetCoreSseServer.csproj ./samples/AspNetCoreSseServer/
COPY ./src/ModelContextProtocol/ModelContextProtocol.csproj ./src/ModelContextProtocol/
COPY ./src/ModelContextProtocol.AspNetCore/ModelContextProtocol.AspNetCore.csproj ./src/ModelContextProtocol.AspNetCore/
COPY ./Directory.Packages.props ./
COPY ./Directory.Build.props ./

# Restore dependencies
RUN dotnet restore ./samples/AspNetCoreSseServer/AspNetCoreSseServer.csproj

# Copy the remaining source code
COPY . .

# Publish the application as a self-contained AOT binary
RUN dotnet publish ./samples/AspNetCoreSseServer/AspNetCoreSseServer.csproj \
    -c Release \
    -r linux-x64 \
    --self-contained true \
    /p:PublishAot=true \
    /p:PublishTrimmed=true \
    /p:EnableCompressionInSingleFile=true \
    -o /app/publish

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0

WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["./AspNetCoreSseServer"]
