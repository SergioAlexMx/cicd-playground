pipeline {
    agent any

    // === HERRAMIENTAS GLOBALES (configura en Jenkins > Global Tool Configuration) ===
    tools {
        jdk 'JDK21'        // Nombre exacto que definas en Jenkins
        gradle 'Gradle8'   // Usa Gradle 8.x (compatible con JDK 21)
    }

    // === VARIABLES DE ENTORNO ===
    environment {
        IMAGE_NAME      = "cicd-playground-java"
        IMAGE_TAG       = "latest"
        CONTAINER_NAME  = "cicd-playground-container"
        APP_PORT        = "9000"   // Puerto donde corre Spring Boot
        HOST_PORT       = "8081"   // Puerto expuesto en la VPS
        DOCKERFILE      = "Dockerfile"
    }

    stages {
        // 1. Clonar el repositorio
        stage('Checkout') {
            steps {
                echo "Clonando repositorio..."
                git branch: 'main',
                    url: 'https://github.com/SergioAlexMx/cicd-playground.git'
            }
        }

        // 2. Construir con Gradle
        stage('Build with Gradle') {
            steps {
                echo "Construyendo con Gradle y JDK 21..."
                sh '''
                ./gradlew clean build -x test
                '''
            }
        }

        // 3. Construir imagen Docker (multi-stage)
        stage('Build Docker Image') {
            steps {
                echo "Construyendo imagen Docker: ${IMAGE_NAME}:${IMAGE_TAG}"
                sh '''
                docker build -f ${DOCKERFILE} -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        // 4. Detener y eliminar contenedor anterior
        stage('Stop Previous Container') {
            steps {
                echo "Deteniendo contenedor anterior (si existe)..."
                sh '''
                docker stop ${CONTAINER_NAME} || true
                docker rm ${CONTAINER_NAME} || true
                '''
            }
        }

        // 5. Ejecutar nuevo contenedor
        stage('Run Container') {
            steps {
                echo "Iniciando contenedor en puerto ${HOST_PORT} → ${APP_PORT}"
                sh '''
                docker run -d \
                  --name ${CONTAINER_NAME} \
                  -p ${HOST_PORT}:${APP_PORT} \
                  -e SERVER_PORT=${APP_PORT} \
                  ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        // 6. Verificación rápida
        stage('Health Check') {
            steps {
                echo "Esperando a que la API esté lista (máx 120 segundos)..."
                script {
                    def maxAttempts = 24  // 24 * 5s = 120 segundos
                    def attempt = 1
                    def success = false

                    while (attempt <= maxAttempts && !success) {
                        echo "Intento ${attempt}/${maxAttempts} - Probando http://localhost:${HOST_PORT}/actuator/health"
                        def result = sh(
                            script: """
                            curl -f -s http://localhost:${HOST_PORT}/actuator/health || exit 1
                            """,
                            returnStatus: true
                        )

                        if (result == 0) {
                            echo "API LISTA y saludable!"
                            success = true
                        } else {
                            echo "Aún no está lista... esperando 5 segundos"
                            sleep 5
                        }
                        attempt++
                    }

                    if (!success) {
                        error "La aplicación no arrancó después de 120 segundos. Revisa los logs del contenedor."
                    }
                }
            }
        }
    }

    // === POST-ACCIÓN ===
    post {
        always {
            echo "Limpiando imágenes huérfanas..."
            sh 'docker system prune -f --volumes || true'
        }
        success {
            echo '''
            API DESPLEGADA CORRECTAMENTE
            URL: http://$(hostname -I | awk '{print $1}'):${HOST_PORT}
            Prueba: curl http://TU_IP_PUBLICA:${HOST_PORT}/api/saludo
            '''
        }
        failure {
            echo "FALLO en el pipeline. Revisa los logs."
        }
    }
}