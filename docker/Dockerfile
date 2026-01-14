# 1) Use a small Java runtime image (good for production)
FROM eclipse-temurin:17-jre

# 2) Create a working directory inside the container
WORKDIR /app

# 3) Copy the built JAR into the container
# (Make sure the jar exists in target/)
COPY target/geo-service-1.0.0.jar app.jar

# 4) Document the port the service listens on
EXPOSE 8080

# 5) Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
