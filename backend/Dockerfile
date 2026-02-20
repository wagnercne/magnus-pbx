FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY backend/Magnus.Core/Magnus.Core.csproj backend/Magnus.Core/
COPY backend/Magnus.Infrastructure/Magnus.Infrastructure.csproj backend/Magnus.Infrastructure/
COPY backend/Magnus.Pbx/Magnus.Pbx.csproj backend/Magnus.Pbx/
RUN dotnet restore backend/Magnus.Pbx/Magnus.Pbx.csproj

COPY backend/ backend/
WORKDIR /src/backend/Magnus.Pbx
RUN dotnet publish Magnus.Pbx.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 5000
ENTRYPOINT ["dotnet", "Magnus.Pbx.dll"]
