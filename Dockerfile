# ===== ETAPA 1: Build con Gradle y JDK 21 (usa Temurin para consistencia) =====
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Instalar Gradle (o usa wrapper)
RUN apk add --no-cache gradle

# Copiar archivos de configuración primero (para caché de capas)
COPY build.gradle.kts settings.gradle.kts gradle.properties ./
COPY gradle ./gradle
COPY gradlew ./

# Descargar dependencias (caché)
RUN ./gradlew dependencies --no-daemon

# Copiar código fuente
COPY src ./src

# Construir JAR (sin tests)
RUN ./gradlew bootJar -x test --no-daemon

# ===== ETAPA 2: Runtime ligero con JRE 21 (Temurin Alpine) =====
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copiar JAR desde etapa anterior
COPY --from=build /app/build/libs/*.jar app.jar

# Puerto de Spring Boot
ENV SERVER_PORT=9000
EXPOSE 9000

# Health check (opcional, para Spring Actuator)
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${SERVER_PORT}/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "/app.jar"]