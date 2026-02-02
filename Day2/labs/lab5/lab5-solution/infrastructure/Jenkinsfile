// Infrastructure Layer Jenkinsfile
// This pipeline manages the infrastructure layer (subnet, security group)
// and triggers the application pipeline after successful apply

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -input=false'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    // -detailed-exitcode: 0=no changes, 1=error, 2=changes present
                    def exitCode = sh(script: 'terraform plan -input=false -out=tfplan -detailed-exitcode', returnStatus: true)
                    if (exitCode == 1) {
                        error("Terraform plan failed")
                    }
                    env.HAS_CHANGES = (exitCode == 2) ? 'true' : 'false'
                    echo "Infrastructure changes detected: ${env.HAS_CHANGES}"
                }
            }
        }

        stage('Approval') {
            when {
                expression { env.HAS_CHANGES == 'true' }
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                input message: "Review infrastructure plan. Approve to apply?",
                      ok: "Apply"
            }
        }

        stage('Terraform Apply') {
            when {
                expression { env.HAS_CHANGES == 'true' }
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                sh 'terraform apply -input=false -auto-approve tfplan'
            }
        }

        stage('Trigger Application Pipeline') {
            when {
                expression { env.HAS_CHANGES == 'true' }
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                echo "Infrastructure changes applied - triggering application pipeline"
                // Replace userX with your user number
                build job: "terraform-application-userX/${env.BRANCH_NAME}",
                      wait: true,
                      propagate: true
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
