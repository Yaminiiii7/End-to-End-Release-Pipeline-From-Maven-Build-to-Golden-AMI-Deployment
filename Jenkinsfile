pipeline {
    agent any

    environment {
        APP_NAME = "geo-service"
        VERSION  = "1.0.0"
        DOCKER_IMAGE = "${APP_NAME}:${VERSION}"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build (Maven)') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Package (Ant)') {
            steps {
                sh 'ant package'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE} -f docker/Dockerfile ."
            }
        }

        stage('Smoke Test') {
            steps {
                sh """
                  docker rm -f ${APP_NAME} || true
                  docker run -d --name ${APP_NAME} -p 8081:8080 ${DOCKER_IMAGE}
                  sleep 5
                  curl -s http://localhost:8081/health | grep -i OK
                  docker rm -f ${APP_NAME}
                """
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dist/**/*.zip, target/*.jar', fingerprint: true
        }
    }
}
