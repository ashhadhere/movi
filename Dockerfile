# --- Stage 1: Build the Java application (with Android SDK) ---
# Use a robust OpenJDK image as base
FROM openjdk:17-jdk AS builder

# Install necessary packages for Android SDK and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    # Add other build-time dependencies if needed, e.g., git
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK Command Line Tools
ENV ANDROID_SDK_ROOT="/usr/local/android-sdk"
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-8583971_latest.zip -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Accept Android SDK licenses (crucial for unattended builds)
RUN yes | sdkmanager --licenses

# Install specific Android SDK platforms and build tools (adjust versions as needed for your project)
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Install Gradle (if not relying solely on gradlew download or if you need a system-wide Gradle)
# If your gradlew script will handle downloads, this might be optional.
# For simplicity, relying on gradlew is usually fine.

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
COPY app ./app

# Give execute permission to the gradlew script
RUN chmod +x ./gradlew

# Build the application.
RUN ./gradlew :app:bootJar -x test # Or whatever build task your project uses

# --- Stage 2: Create the final production image ---
# Use a smaller JRE-only image for the runtime environment to keep the final image size down
FROM openjdk:17-jre-slim

# Set the working directory for the application inside the final image
WORKDIR /app

# Copy the built JAR file from the 'builder' stage
COPY --from=builder /app/app/build/libs/*.jar app.jar

# Expose the port your Java application will listen on
EXPOSE 8080

# Define the command to run your application when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]
