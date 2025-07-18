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
    GIT_CREDENTIALS_ID = 'github-access-token'
  }

  stages {

    stage('Checkout Source Code') {
      steps {
        script {
          try {
            echo "Cloning source code..."
            git credentialsId: "${GIT_CREDENTIALS_ID}", url: "${SRC_REPO}", branch: "${SRC_BRANCH}"
          } catch (err) {
            error "Failed to checkout source code: ${err}"
          }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          try {
            echo "Building Docker image..."
            sh "docker build -t chatapp-django:${IMAGE_TAG} ."
          } catch (err) {
            error "Docker build failed: ${err}"
          }
        }
      }
    }

    stage('Push to ECR') {
      steps {
        script {
          try {
            echo "Pushing Docker image to ECR..."
            withAWS(credentials: 'aws-ecr-creds', region: "${AWS_REGION}") {
              sh """
                aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                docker tag chatapp-django:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG
                docker push $ECR_REPO:$IMAGE_TAG
              """
            }
          } catch (err) {
            error "Failed to push image to ECR: ${err}"
          }
        }
      }
    }

    stage('Checkout Deployment Repo') {
      steps {
        script {
          try {
            echo "Cloning deployment repo..."
            dir('deployment') {
              git credentialsId: "${GIT_CREDENTIALS_ID}", url: "${DEPLOY_REPO}", branch: "${DEPLOY_BRANCH}"
            }
          } catch (err) {
            error "Failed to checkout deployment repo: ${err}"
          }
        }
      }
    }

    stage('Install yq') {
      steps {
        script {
          echo "Installing yq if not present..."
          dir('deployment') {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh '''
                if ! [ -f yq ]; then
                  curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o yq
                  chmod +x yq
                fi
              '''
            }
          }
        }
      }
    }

    stage('Update Helm values.yaml') {
      steps {
        script {
          try {
            echo "Updating image in values.yaml..."
            dir('deployment') {
              sh """
                ./yq eval '.backend.image = "${ECR_REPO}:${IMAGE_TAG}"' -i helm/values.yaml
                echo "New backend.image:"
                grep 'backend:' -A 6 helm/values.yaml
              """
            }
          } catch (err) {
            error "Failed to update values.yaml: ${err}"
          }
        }
      }
    }

    stage('Push changes to GitHub') {
      steps {
        script {
          try {
            echo "Committing and pushing updated values.yaml..."
            dir('deployment') {
              withCredentials([usernamePassword(credentialsId: "${GIT_CREDENTIALS_ID}", usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                sh """
                  git config --global user.name "$GIT_USER"
                  git config --global user.email "${GIT_USER}@users.noreply.github.com"
                  git add helm/values.yaml
                  git commit -m "CI: Update backend image tag to ${IMAGE_TAG}" || echo "No changes to commit"
                  git push https://${GIT_USER}:${GIT_PASS}@github.com/ARPIT226/chatapp-deployment-prod.git HEAD:${DEPLOY_BRANCH}
                """
              }
            }
          } catch (err) {
            error "Failed to push to deployment repo: ${err}"
          }
        }
      }
    }

    stage('Cleanup Docker') {
      steps {
        script {
          echo "Cleaning up local Docker images..."
          catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
            sh """
              docker rmi $ECR_REPO:$IMAGE_TAG || true
              docker rmi chatapp-django:$IMAGE_TAG || true
              docker image prune -f
            """
          }
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline execution completed."
    }
    failure {
      echo "Pipeline failed! Check the logs above for errors."
    }
    success {
      echo "Pipeline completed successfully."
    }
  }
}
