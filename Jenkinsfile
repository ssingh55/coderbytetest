pipeline {
    agent any

    environment {
        AWS_REGIONS = "us-east-1"
        ECR_REPOSITORY = "coderbytetest"
        AWS_CREDENTIALS_ID = 'aws-credential'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        EKS_CLUSTER_NAME = "k8s-cluster"
    }

    triggers {
        pollSCM('H/5 * * * *')
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/ssingh55/coderbytetest.git'
            }
        }

        stage('Initialize Go module') {
            steps {
                sh 'go mod tidy'
            }
        }

        stage('Configure AWS & LOgin to ECR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: AWS_CREDENTIALS_ID,
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                        env.AWS_ACCOUNT_ID = accountId
                        sh "aws ecr get-login-password --region ${AWS_REGIONS} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}")
                }
            }
        }

        stage('Push the image to ECR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: AWS_CREDENTIALS_ID,
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    script {
                        sh """
                            docker push ${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
                            docker tag ${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG} ${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com/${ECR_REPOSITORY}:latest
                            docker push ${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com/${ECR_REPOSITORY}:latest
                        """
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
