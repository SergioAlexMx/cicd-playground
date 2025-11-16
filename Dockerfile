# ===== ETAPA 1: Build con Gradle y JDK 21 =====
FROM gradle:8.10-jdk21-alpine AS build
WORKDIR /app

# Copiar archivos de configuración primero (para caché)
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle
COPY gradlew ./

# Descargar dependencias (caché)
RUN ./gradlew dependencies --no-daemon

# Copiar código fuente
COPY src ./src

# Construir JAR (sin tests)
RUN ./gradlew bootJar -x test --no-daemon

# ===== ETAPA 2: Runtime ligero =====
FROM openjdk:21-jre-slim
WORKDIR /app

# Copiar JAR desde etapa anterior
COPY --from=build /app/build/libs/cicd-playground-0.0.1-SNAPSHOT.jar app.jar

# Puerto de Spring Boot
ENV SERVER_PORT=9000
EXPOSE 9000

# Health check (opcional)
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:${SERVER_PORT}/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "/app.jar"]