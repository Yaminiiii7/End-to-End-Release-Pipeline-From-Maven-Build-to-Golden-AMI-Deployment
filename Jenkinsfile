pipeline {
    agent any

    environment {
        APP_NAME = "geo-service"
        VERSION  = "1.0.0"
        DOCKER_IMAGE = "${APP_NAME}:${VERSION}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build (Maven)') {
            steps {
                sh 'mvn -v'
                sh 'mvn clean package'
            }
        }

        stage('Test') {
            steps {
                // if you have tests, this will run them as part of mvn test
                sh 'mvn test'
            }
        }

        stage('Package (Ant Installer Bundle)') {
            steps {
                sh 'ant -version'
                sh 'ant package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker --version'
                sh "docker build -t ${DOCKER_IMAGE} -f docker/Dockerfile ."
            }
        }

        stage('Smoke Test Docker') {
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

        // OPTIONAL: Enable after you finish Step 6 (Packer)
        // stage('Build Golden AMI (Packer)') {
        //     steps {
        //         sh 'packer --version'
        //         sh 'packer init packer/'
        //         sh 'packer build packer/geo-service.pkr.hcl'
        //     }
        // }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dist/**/*.zip, target/*.jar', fingerprint: true
        }
    }
}
