FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY build/libs/app.jar app.jar
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD wget -q -O - http://localhost:8080/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
