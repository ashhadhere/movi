# --- Stage 1: Build the Java application ---
# Use a Gradle image that includes Java for building, AND the Android SDK
FROM androidsdk/android-sdk:latest AS builder
# OR: FROM androidsdk/android-sdk:latest (another common option)

# Set the working directory inside the container
WORKDIR /app

# Copy the Gradle wrapper files and build configuration files
COPY gradlew .
COPY gradlew.bat .
COPY gradle ./gradle
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY gradle.properties .

# Copy your application source code.
# Assuming your main Java code is in the 'app' directory
COPY app ./app

# Give execute permission to the gradlew script
RUN chmod +x ./gradlew

# Build the application.
# The ':app:bootJar' task is common for Spring Boot applications to create an executable JAR.
# If your application is not Spring Boot or produces a different artifact,
# you might use './gradlew :app:jar' or just './some-other-build-command'.
# The '-x test' flag skips running tests during the build.
RUN ./gradlew :app:bootJar -x test

# --- Stage 2: Create the final production image ---
# Use a smaller JRE-only image for the runtime environment to keep the final image size down
FROM openjdk:17-jre-slim

# Set the working directory for the application inside the final image
WORKDIR /app

# Copy the built JAR file from the 'builder' stage
# This path '/app/app/build/libs/*.jar' assumes:
# 1. The WORKDIR in the builder stage was /app
# 2. Your 'app' module's build output is in 'app/build/libs/'
# 3. It will copy the first .jar file found (e.g., 'app-0.0.1-SNAPSHOT.jar' or similar)
COPY --from=builder /app/app/build/libs/*.jar app.jar

# Expose the port your Java application will listen on (e.g., for a web server)
# Common ports are 8080, 8000. Adjust if your application uses a different port.
EXPOSE 8080

# Define the command to run your application when the container starts
# This will execute the JAR file we copied.
ENTRYPOINT ["java", "-jar", "app.jar"]
