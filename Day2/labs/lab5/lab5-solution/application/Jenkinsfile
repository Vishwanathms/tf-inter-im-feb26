// Application Layer Jenkinsfile
// This pipeline manages the application layer (EC2 instance)
// It reads infrastructure outputs via terraform_remote_state

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
                // Application layer reads infrastructure state automatically
                sh 'terraform plan -input=false -out=tfplan'
            }
        }

        stage('Approval') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                input message: "Review application plan. Approve to apply?",
                      ok: "Apply"
            }
        }

        stage('Terraform Apply') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                sh 'terraform apply -input=false -auto-approve tfplan'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
