pipeline {
    agent any

    environment {
        AWS_REGIONS = "us-east-1"
        ECR_REPOSITORY = "coderbytetest"
        // AWS_ACCOUNT_ID = credentials('081006037460')
        // AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        // AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key') 
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
                // sh 'go mod init main'
                sh 'go mod tidy'
            }
        }

        stage('Configure AWS & LOgin to ECR') {
            steps {
                // withAWS(region: "${AWS_REGIONS}", credentials: "${AWS_CREDENTIALS_ID}") {
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
                // withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGIONS}") {
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

        stage ('Deploy to EKS') {
            steps {
                // withAWS(credentials: AWS_CREDENTIALS_ID, region: AWS_REGIONS) {
                withCredentials([usernamePassword(
                    credentialsId: AWS_CREDENTIALS_ID,
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh """
                        aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGIONS}
                        kubectl set image deployment/app app=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
                        kubectl rollout status deployment/app
                    """
                }
                // withAWS([[
                //     $class: 'AmazonWebServicesCredentialsBinding',
                //     credentialsId: "${AWS_CREDENTIALS_ID}",
                //     accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                //     secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                // ]]) {
                //     sh """
                //         aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGIONS}
                //         kubectl set image deployment/app
                //         app=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGIONS}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
                //         kubectl rollout status deployment/app
                //     """
                // }
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