pipeline {
    agent any
    
    environment{
        REMOTE_USER = "ubuntu"
        REMOTE_HOST = "10.0.3.213"
        REMOTE_DIR = "/chatapp"
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', credentialsId: '57678de1-cf72-48eb-bdcd-894e30f7e016', url: 'https://github.com/ParthG26/ChatApp-Application-Deployment.git'
            }
        }
        stage('Copying files from workspace to remote'){
            steps{
                sh """
                scp -r "$WORKSPACE"/* $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/
                """
            }
        }
        stage('Installing Requirements'){
            steps{
                sh """
                ssh $REMOTE_USER@$REMOTE_HOST '
                    cd $REMOTE_DIR &&
                    source venv/bin/activate &&
                    pip install -r requirements.txt
                '
                """
            }
        }
        stage('Run Migrations'){
            steps{
                sh """
                ssh $REMOTE_USER@$REMOTE_HOST '
                    cd $REMOTE_DIR/fundoo &&
                    source $REMOTE_DIR/venv/bin/activate &&
                    python3 manage.py migrate
                '
                """
            }
        }
        stage('Restart Gunicorn'){
            steps{
                sh """
                ssh $REMOTE_USER@$REMOTE_HOST '
                    sudo systemctl restart gunicorn
                '
                """
            }
        }
    }
}
