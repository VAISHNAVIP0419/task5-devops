pipeline {
    agent any

    environment {
        REGISTRY_URL = "vnexus.vyturr.one:8081"
        IMAGE_NAME   = "todo-docker-repo/todo-app"
        IMAGE_TAG    = "latest"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/VAISHNAVIP0419/task5-devops.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to Nexus') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'nexus-credentials', 
                                                      passwordVariable: 'NEXUS_PASSWORD', 
                                                      usernameVariable: 'NEXUS_USERNAME')]) {
                        sh "echo $NEXUS_PASSWORD | docker login ${REGISTRY_URL} -u $NEXUS_USERNAME --password-stdin"
                    }
                }
            }
        }

        stage('Push Image to Nexus') {
            steps {
                script {
                    sh "docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Docker image pushed to Nexus successfully!"
        }
        failure {
            echo "❌ Build or push failed!"
        }
    }
}