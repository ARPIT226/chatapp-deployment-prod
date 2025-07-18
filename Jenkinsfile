pipeline {
  agent any

  environment {
    AWS_REGION = 'eu-west-2'
    ECR_REPO = '262194309205.dkr.ecr.eu-west-2.amazonaws.com/chatapp-django'
    IMAGE_TAG = "build-${BUILD_NUMBER}"
    SRC_REPO = 'https://github.com/ARPIT226/chatapp-source-code.git'
    SRC_BRANCH = 'main'
    DEPLOY_REPO = 'https://github.com/ARPIT226/chatapp-deployment-prod.git'
    DEPLOY_BRANCH = 'main'
    GIT_CREDENTIALS_ID = 'github-access-token' // GitHub PAT stored in Jenkins
  }

  stages {

    stage('Checkout Source Code') {
      steps {
        git credentialsId: "${GIT_CREDENTIALS_ID}", url: "${SRC_REPO}", branch: "${SRC_BRANCH}"
      }
    }

    stage('Build Docker Image') {
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

    stage('Checkout Deployment Repo') {
      steps {
        dir('deployment') {
          git credentialsId: "${GIT_CREDENTIALS_ID}", url: "${DEPLOY_REPO}", branch: "${DEPLOY_BRANCH}"
        }
      }
    }

    stage('Install yq') {
      steps {
        dir('deployment') {
          sh '''
            if ! [ -f yq ]; then
              echo "Installing yq..."
              curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o yq
              chmod +x yq
            fi
          '''
        }
      }
    }

    stage('Update Helm values.yaml') {
      steps {
        dir('deployment') {
          sh '''
            ./yq eval ".image.tag = \\"${IMAGE_TAG}\\"" -i helm/values.yaml
            echo "Updated values.yaml:"
            cat helm/values.yaml
          '''
        }
      }
    }

    stage('Push changes to GitHub') {
      steps {
        dir('deployment') {
          withCredentials([usernamePassword(credentialsId: "${GIT_CREDENTIALS_ID}", usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
            sh '''
              git config --global user.name "$GIT_USER"
              git config --global user.email "${GIT_USER}@users.noreply.github.com"
              git add helm/values.yaml
              git commit -m "CI: Update image tag to ${IMAGE_TAG}" || echo "No changes to commit"
              git push https://${GIT_USER}:${GIT_PASS}@github.com/ARPIT226/chatapp-deployment-prod.git HEAD:${DEPLOY_BRANCH}
            '''
          }
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
