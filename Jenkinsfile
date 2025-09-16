pipeline {
    agent any

    environment {
        REGISTRY        = "vnexus.vyturr.one"                 // Nexus hostname
        REPO_NAME       = "simple-flask-ci"                   // Nexus Docker hosted repo
        IMAGE_NAME      = "simple-flask-ci"                   // Your app name
        IMAGE_TAG       = "latest"
        CREDENTIALS_ID  = "nexus-credentials"                 // Jenkins creds for Nexus
    }

    stages {
        stage('Checkout') {
            steps {
                sh '''
                    if [ -d "task5-devops" ]; then
                        rm -rf task5-devops
                    fi
                    git clone https://github.com/VAISHNAVIP0419/task5-devops.git
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "./task5-devops/simple-flask-ci/app")
                }
            }
        }

        stage('Push to Nexus') {
            steps {
                script {
                    docker.withRegistry("https://${REGISTRY}", CREDENTIALS_ID) {
                        sh """
                            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh """
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                    docker rmi ${REGISTRY}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG} || true
                """
            }
        }
    }
}