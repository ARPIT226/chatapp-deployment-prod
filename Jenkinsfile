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

    stage('Install yq (YAML Processor)') {
      steps {
        sh '''
          if ! [ -f ./yq ]; then
            echo "Downloading yq..."
            curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o ./yq
            chmod +x ./yq
          fi
        '''
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
          def imageTagFull = "${ECR_REPO}:${IMAGE_TAG}"
          sh """
            ./yq eval '.backend.image = "${imageTagFull}"' -i helm/values.yaml

            echo "Updated values.yaml:"
            ./yq eval '.backend' helm/values.yaml
          """
        }
      }
    }

    stage('Push changes to GitHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${GIT_CREDENTIALS_ID}", usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
          sh """
            git config --global user.name "$GIT_USER"
            git config --global user.email "${GIT_USER}@users.noreply.github.com"

            # Add all changes in the repo
            git add .

            # Commit all changes
            git commit -m "CI: Update image tag to ${IMAGE_TAG} and push full repo" || echo "No changes to commit"

            # Push changes back to the repo
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
