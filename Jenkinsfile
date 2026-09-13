pipeline {
    agent any

    environment {
        AWS_REGION    = 'ap-south-1'
        FRONTEND_REPO = '371397508701.dkr.ecr.ap-south-1.amazonaws.com/mern-frontend'
        BACKEND_REPO  = '371397508701.dkr.ecr.ap-south-1.amazonaws.com/mern-backend'
    }

    stages {
        
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: 'GitHub-Token',
                    url: 'https://github.com/Shubhamsalvi09/Three-Tier-DevSecOps-MERN-Stack-Project.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQube'

                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                              -Dsonar.projectKey=mern-stack \
                              -Dsonar.projectName="MERN Stack DevSecOps" \
                              -Dsonar.sources=frontend/src,backend \
                              -Dsonar.exclusions="**/node_modules/**,**/build/**,**/coverage/**,**/*.test.js"
                        """
                    }
                }
            }
        }

	stage('Quality Gate') {
 	   steps {
        		timeout(time: 5, unit: 'MINUTES') {
        	    waitForQualityGate abortPipeline: true
       			 }
    		}
	}

        stage('Login to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password \
                      --region ${AWS_REGION} | \
                    docker login \
                      --username AWS \
                      --password-stdin 371397508701.dkr.ecr.ap-south-1.amazonaws.com
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                    docker build \
                      --build-arg REACT_APP_BACKEND_URL=http://ae78b95a69db44fdf9a6a20e13bdcdff-1752412347.ap-south-1.elb.amazonaws.com:3500/api/tasks \
                      -t ${FRONTEND_REPO}:v${BUILD_NUMBER} \
                      ./frontend
                '''
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                    docker build \
                      -t ${BACKEND_REPO}:v${BUILD_NUMBER} \
                      ./backend
                '''
            }
        }


	stage('Trivy Scan') {
 	   steps {
        	sh '''
            		echo "Scanning frontend image..."

            		trivy image \
              			--scanners vuln \
              			--severity HIGH,CRITICAL \
              			--ignore-unfixed \
              			--exit-code 1 \
              			${FRONTEND_REPO}:v${BUILD_NUMBER}

            		echo "Scanning backend image..."

            		trivy image \
              			--scanners vuln \
              			--severity HIGH,CRITICAL \
              			--ignore-unfixed \
              			--exit-code 1 \
              			${BACKEND_REPO}:v${BUILD_NUMBER}

            		echo "Trivy scan completed successfully!"
        	'''
    		}
	}

        stage('Push Images to ECR') {
            steps {
                sh '''
                    docker push ${FRONTEND_REPO}:v${BUILD_NUMBER}
                    docker push ${BACKEND_REPO}:v${BUILD_NUMBER}
                '''
            }
        }

        stage('Clone GitOps Repository') {
            steps {
                dir('gitops') {
                    git branch: 'main',
                        credentialsId: 'GitHub-Token',
                        url: 'https://github.com/Shubhamsalvi09/Three-Tier-DevSecOps-MERN-Stack-GitOps.git'
                }
            }
        }

        stage('Update GitOps Manifests') {
            steps {
                dir('gitops') {
                    sh '''
                        sed -i "s|image: .*mern-frontend.*|image: ${FRONTEND_REPO}:v${BUILD_NUMBER}|g" \
                          frontend-deployment.yaml

                        sed -i "s|image: .*mern-backend.*|image: ${BACKEND_REPO}:v${BUILD_NUMBER}|g" \
                          backend-deployment.yaml

                        echo "Updated frontend image:"
                        grep "image:" frontend-deployment.yaml

                        echo "Updated backend image:"
                        grep "image:" backend-deployment.yaml
                    '''
                }
            }
        }

        stage('Commit and Push GitOps Changes') {
            steps {
                dir('gitops') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'GitHub-Token',
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_PASSWORD'
                        )
                    ]) {
                        sh '''
                            git config user.name "Jenkins"
                            git config user.email "jenkins@localhost"

                            git add frontend-deployment.yaml
                            git add backend-deployment.yaml

                            git commit \
                              -m "Update Kubernetes images to v${BUILD_NUMBER}" \
                              || echo "No changes to commit"

                            git push \
                              https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Shubhamsalvi09/Three-Tier-DevSecOps-MERN-Stack-GitOps.git \
                              HEAD:main
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'CI Pipeline completed successfully!'
        }

        failure {
            echo 'CI Pipeline failed!'
        }
    }
}
