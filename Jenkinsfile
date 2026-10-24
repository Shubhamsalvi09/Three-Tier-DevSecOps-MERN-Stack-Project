pipeline {
    agent any

    environment {
        AWS_REGION  = 'ap-south-1'
        AWS_ACCOUNT = '371397508701'

        FRONTEND_REPO = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/mern-frontend"
        BACKEND_REPO  = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/mern-backend"

        GITOPS_REPO = 'https://github.com/Shubhamsalvi09/Three-Tier-DevSecOps-MERN-Stack-GitOps.git'
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Detect Changes') {
            steps {
                script {
                    def previous = env.GIT_PREVIOUS_SUCCESSFUL_COMMIT

                    if (!previous?.trim()) {
                        env.BUILD_FRONTEND = 'true'
                        env.BUILD_BACKEND = 'true'
                    } else {
                        def changes = sh(
                            script: "git diff --name-only ${previous} ${env.GIT_COMMIT}",
                            returnStdout: true
                        ).trim()

                        def changedFiles = changes ? changes.split('\n') : []

                        env.BUILD_FRONTEND = changedFiles.any {
                            it.startsWith('frontend/')
                        } ? 'true' : 'false'

                        env.BUILD_BACKEND = changedFiles.any {
                            it.startsWith('backend/')
                        } ? 'true' : 'false'

                        if (changedFiles.contains('Jenkinsfile')) {
                            env.BUILD_FRONTEND = 'true'
                            env.BUILD_BACKEND = 'true'
                        }
                    }

                    echo "Frontend build required: ${env.BUILD_FRONTEND}"
                    echo "Backend build required: ${env.BUILD_BACKEND}"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=mern-stack \
                          -Dsonar.projectName="MERN Stack DevSecOps" \
                          -Dsonar.sources=frontend/src,backend \
                          -Dsonar.exclusions=**/node_modules/**,**/build/**,**/coverage/**,**/*.test.js
                    '''
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
            when {
                expression {
                    env.BUILD_FRONTEND == 'true' || env.BUILD_BACKEND == 'true'
                }
            }
            steps {
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} |
                    docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
                '''
            }
        }

        stage('Build Frontend Image') {
            when {
                expression { env.BUILD_FRONTEND == 'true' }
            }
            steps {
                sh '''
                    docker build \
                      --build-arg REACT_APP_BACKEND_URL=/api/tasks \
                      -t ${FRONTEND_REPO}:v${BUILD_NUMBER} \
                      ./frontend
                '''
            }
        }

        stage('Build Backend Image') {
            when {
                expression { env.BUILD_BACKEND == 'true' }
            }
            steps {
                sh '''
                    docker build \
                      -t ${BACKEND_REPO}:v${BUILD_NUMBER} \
                      ./backend
                '''
            }
        }

        stage('Trivy Scan') {
            when {
                expression {
                    env.BUILD_FRONTEND == 'true' || env.BUILD_BACKEND == 'true'
                }
            }
            steps {
                script {
                    if (env.BUILD_FRONTEND == 'true') {
                        sh '''
                            trivy image --scanners vuln --severity HIGH,CRITICAL \
                              --ignore-unfixed --exit-code 1 \
                              ${FRONTEND_REPO}:v${BUILD_NUMBER}
                        '''
                    }

                    if (env.BUILD_BACKEND == 'true') {
                        sh '''
                            trivy image --scanners vuln --severity HIGH,CRITICAL \
                              --ignore-unfixed --exit-code 1 \
                              ${BACKEND_REPO}:v${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }

        stage('Push Images to ECR') {
            when {
                expression {
                    env.BUILD_FRONTEND == 'true' || env.BUILD_BACKEND == 'true'
                }
            }
            steps {
                script {
                    if (env.BUILD_FRONTEND == 'true') {
                        sh 'docker push ${FRONTEND_REPO}:v${BUILD_NUMBER}'
                    }

                    if (env.BUILD_BACKEND == 'true') {
                        sh 'docker push ${BACKEND_REPO}:v${BUILD_NUMBER}'
                    }
                }
            }
        }

        stage('Clone GitOps Repository') {
            when {
                expression {
                    env.BUILD_FRONTEND == 'true' || env.BUILD_BACKEND == 'true'
                }
            }
            steps {
                dir('gitops') {
                    git branch: 'main',
                        credentialsId: 'GitHub-Token',
                        url: "${GITOPS_REPO}"
                }
            }
        }

        stage('Update GitOps Manifests') {
            when {
                expression {
                    env.BUILD_FRONTEND == 'true' || env.BUILD_BACKEND == 'true'
                }
            }
            steps {
                dir('gitops') {
                    script {
                        if (env.BUILD_FRONTEND == 'true') {
                            sh '''
                                sed -i "s|image: .*mern-frontend.*|image: ${FRONTEND_REPO}:v${BUILD_NUMBER}|g" frontend-deployment.yaml
                            '''
                        }

                        if (env.BUILD_BACKEND == 'true') {
                            sh '''
                                sed -i "s|image: .*mern-backend.*|image: ${BACKEND_REPO}:v${BUILD_NUMBER}|g" backend-deployment.yaml
                            '''
                        }
                    }
                }
            }
        }

        stage('Commit and Push GitOps Changes') {
            when {
                expression {
                    env.BUILD_FRONTEND == 'true' || env.BUILD_BACKEND == 'true'
                }
            }
            steps {
                dir('gitops') {
                    withCredentials([string(credentialsId: 'GitHub-Token', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                            git config user.email "jenkins@example.com"
                            git config user.name "Jenkins"

                            if [ "${BUILD_FRONTEND}" = "true" ]; then
                                git add frontend-deployment.yaml
                            fi

                            if [ "${BUILD_BACKEND}" = "true" ]; then
                                git add backend-deployment.yaml
                            fi

                            if ! git diff --cached --quiet; then
                                git commit -m "Update application image to build ${BUILD_NUMBER}"
                                git push https://${GITHUB_TOKEN}@github.com/Shubhamsalvi09/Three-Tier-DevSecOps-MERN-Stack-GitOps.git HEAD:main
                            else
                                echo "No GitOps manifest changes to commit."
                            fi
                        '''
                    }
                }
            }
        }
    }
}

