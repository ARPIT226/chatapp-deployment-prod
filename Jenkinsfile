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
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
            docker tag chatapp-django:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG
            docker push $ECR_REPO:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Deploy to EKS with Helm') {
      steps {
        script {
          sh """
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
  }
}
