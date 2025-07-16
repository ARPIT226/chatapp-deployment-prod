pipeline {
  agent any

  environment {
    AWS_REGION = 'eu-west-2'
    ECR_REPO = '262194309205.dkr.ecr.eu-west-2.amazonaws.com/chatapp-django'
    IMAGE_TAG = "build-${BUILD_NUMBER}"
    GIT_REPO = 'https://github.com/ARPIT226/chat_app.git'
    GIT_BRANCH = 'main'
    GIT_CREDENTIALS_ID = 'github-access-token' // GitHub PAT stored as Jenkins "Username with password"
  }

  stages {

    stage('Checkout Code') {
      steps {
        git credentialsId: "${GIT_CREDENTIALS_ID}", url: "${GIT_REPO}", branch: "${GIT_BRANCH}"
      }
    }

    stage('Docker Build') {
      steps {
        sh "docker build -t chatapp-django:${IMAGE_TAG} ."
      }
    }

    stage('Push to ECR') {
      steps {
        withAWS(credentials: 'aws-ecr-creds', region: "${AWS_REGION}") {
          sh """
            echo "Logging in to ECR..."
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

            echo "Tagging image..."
            docker tag chatapp-django:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG

            echo "Pushing to ECR..."
            docker push $ECR_REPO:$IMAGE_TAG
          """
        }
      }
    }

    stage('Update Helm values.yaml') {
      steps {
        script {
          def valuesFile = 'helm/values.yaml'
          def imageLine = "image: \\\"${ECR_REPO}:${IMAGE_TAG}\\\""

          // Safely update image field while preserving indentation
          sh """
            sed -i '/backend:/,/^[^[:space:]]/s/^\\( *\\)image:.*$/\\1${imageLine}/' ${valuesFile}
          """

          // Show result
          sh "grep -A 2 'backend:' ${valuesFile}"
        }
      }
    }

    stage('Push changes to GitHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${GIT_CREDENTIALS_ID}", usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
          sh """
            git config user.name "$GIT_USER"
            git config user.email "${GIT_USER}@users.noreply.github.com"

            git add helm/values.yaml
            git commit -m "Update image tag to ${IMAGE_TAG}" || true
            git push https://${GIT_USER}:${GIT_PASS}@github.com/ARPIT226/chat_app.git HEAD:${GIT_BRANCH}
          """
        }
      }
    }

    stage('Cleanup Docker') {
      steps {
        sh """
          docker rmi $ECR_REPO:$IMAGE_TAG || true
          docker rmi chatapp-django:$IMAGE_TAG || true
          docker image prune -f
        """
      }
    }

  }

  post {
    always {
      echo "Pipeline execution completed."
    }
  }
}
