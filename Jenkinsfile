pipeline {
  agent any

  environment {
    AWS_REGION = 'eu-west-2'
    ECR_REPO = '262194309205.dkr.ecr.eu-west-2.amazonaws.com/chatapp-django'
    IMAGE_TAG = "build-${BUILD_NUMBER}"
    CLUSTER_NODE_IP = '35.179.113.190' // Public IP of EC2 node with kubectl/helm access
  }

  stages {

    stage('Git Checkout') {
      steps {
        git url: 'https://github.com/ARPIT226/chat_app.git', branch: 'main'
      }
    } 

    stage('Docker Build') {
      steps {
        script {
          sh """
            docker build -t chatapp-django:${IMAGE_TAG} .
          """
        }
      }
    }

    stage('Push to ECR') {
      steps {
        withAWS(credentials: 'aws-ecr-creds', region: "${AWS_REGION}") {
          sh '''
            echo "Logging in to AWS ECR..."
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

            echo "Tagging image..."
            docker tag chatapp-django:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG

            echo "Pushing image to ECR..."
            docker push $ECR_REPO:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Deploy to EKS with Helm') {
      steps {
        script {
          sh """
            echo "Connecting to EC2 node and deploying with Helm..."
            ssh -o StrictHostKeyChecking=no ubuntu@$CLUSTER_NODE_IP '
              export AWS_REGION=${AWS_REGION}
              export IMAGE_TAG=${IMAGE_TAG}
              aws eks --region ${AWS_REGION} update-kubeconfig --name gedemoo

              helm upgrade chatapp /home/ubuntu/chatapp \\
                -f /home/ubuntu/chatapp/values.yaml \\
                --set backend.image=${ECR_REPO}:$IMAGE_TAG \\
                -n default
            '
          """
        }
      }
    }

    stage('Cleanup Docker') {
      steps {
        script {
          sh '''
            echo "Cleaning up local Docker images and cache..."
            docker rmi $ECR_REPO:$IMAGE_TAG || true
            docker rmi chatapp-django:$IMAGE_TAG || true
            docker image prune -f
          '''
        }
      }
    }

  }

  post {
    always {
      echo "Pipeline execution completed."
    }
  }
}
