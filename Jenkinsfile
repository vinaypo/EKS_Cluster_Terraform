properties([
    parameters([
        choice(
            choices: ['dev', 'stage', 'prod'],
            name: 'Environment'
        ),
        choice(
            choices: ['plan', 'apply', 'destroy'], 
            name: 'Terraform_Action'
        )
    ])
])

pipeline {
    agent any

    stages {

        stage('Preparing') {
            steps {
                echo "Preparing Pipeline..."
            }
        }

        stage('Git Pull') {
            steps {
                git branch: 'main', url: 'https://github.com/vinaypo/EKS_Cluster_Terraform.git'
            }
        }

        stage('Terraform Init') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    sh 'terraform -chdir=eks/ init'
                }
            }
        }

        stage('Select/Create Workspace') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    script {
                        sh """
                            cd eks/
                            terraform workspace list | grep ${params.Environment} || terraform workspace new ${params.Environment}
                            terraform workspace select ${params.Environment}
                        """
                    }
                }
            }
        }

        stage('Validate') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    sh 'terraform -chdir=eks/ validate'
                }
            }
        }

        stage('Terraform Action') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    script {

                        def tfVarsFile = "${params.Environment}/${params.Environment}.tfvars"

                        if (params.Terraform_Action == 'plan') {

                            sh "terraform -chdir=eks/ plan -var-file=../${tfVarsFile}"

                        } else if (params.Terraform_Action == 'apply') {

                            sh "terraform -chdir=eks/ apply -var-file=../${tfVarsFile} -auto-approve"

                        } else if (params.Terraform_Action == 'destroy') {

                            sh "terraform -chdir=eks/ destroy -var-file=../${tfVarsFile} -auto-approve"
                        }
                    }
                }
            }
        }
    }
}
