pipeline {
    agent any

    environment {
        NEXUS_REGISTRY = "vnexus.vyturr.one:8081"
        IMAGE_NAME = "simple-flask-ci"
        IMAGE_TAG = "latest"
        CREDENTIALS_ID = "nexus-credentials"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/VAISHNAVIP0419/task5-devops.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "./simple-flask-ci/app")
                }
            }
        }

        stage('Push to Nexus') {
            steps {
                script {
                    docker.withRegistry("http://${env.NEXUS_REGISTRY}", "${env.CREDENTIALS_ID}") {
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
            }
        }
    }
}