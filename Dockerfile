# Use Maven image for building
FROM maven:3.9.11-amazoncorretto-17 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml first for better caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Use OpenJDK 17 runtime image
FROM openjdk:17-jdk-slim

# Install curl for health check
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/target/coffee-shop-api-1.0.0.jar app.jar

# Create non-root user for security
RUN addgroup --system spring && adduser --system spring --ingroup spring

# Change ownership of the app directory
RUN chown -R spring:spring /app
USER spring:spring

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# Run the application
CMD ["java", "-jar", "app.jar"]
