pipeline {
    agent any

    environment {
        AWS_REGION          = 'ap-south-1'
        TF_WORKSPACE        = 'terraform-monitoring-stack'
        
        // REVERTED to the correct original credential ID that actually exists in Jenkins
        SSH_KEY_FILE        = credentials('monitoring-ssh-private-key')        
        AWS_ACCESS_KEY_ID   = credentials('aws-access-key-id')      
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key') 
        
        PATH               = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${env.PATH}"
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'Select Terraform action to perform'
        )
        booleanParam(
            name: 'RUN_ANSIBLE',
            defaultValue: true,
            description: 'Run Ansible playbook after Terraform apply?'
        )
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        ansiColor('xterm')
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "✅ Code checked out from: ${env.GIT_URL} | Branch: ${env.GIT_BRANCH}"
            }
        }

        stage('Terraform Init & Validate') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== Terraform Version ==="
                        terraform version

                        echo "=== Initializing Terraform ==="
                        terraform init \
                            -backend-config="bucket=sarthak-prometheus-tfstate-2026-ap-south-1" \
                            -backend-config="key=terraform/terraform.tfstate" \
                            -backend-config="region=ap-south-1" \
                            -backend-config="encrypt=true" \
                            -backend-config="dynamodb_table=terraform-lock-table" \
                            -reconfigure \
                            -input=false

                        echo "=== Validating Terraform Config ==="
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== Generating Terraform Plan ==="
                        terraform plan \
                            -var="aws_region=${AWS_REGION}" \
                            -var="instance_type=t3.micro" \
                            -var="key_name=sarthak" \
                            -out=tfplan.out \
                            -input=false
                    '''
                }
            }
        }

        stage('Approval') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input message: "⚠️  Approve Terraform ${params.ACTION}?",
                          ok: "Yes, ${params.ACTION}!"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('terraform') {
                    sh '''
                        echo "=== Applying Terraform Plan ==="
                        terraform apply -input=false -auto-approve tfplan.out
                    '''
                }
            }
        }



        stage('Wait for EC2 Readiness') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.RUN_ANSIBLE == true }
                }
            }
            steps {
                echo "⏳ Waiting 60 seconds for EC2 instances to fully boot and install Python..."
                sleep(time: 60, unit: 'SECONDS')
            }
        }

        stage('Ansible Syntax Check') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.RUN_ANSIBLE == true }
                }
            }
            steps {
                dir('ansible-monitoring-stack') {
                    sh '''
                        echo "=== Ansible Syntax Check ==="
                        ansible-playbook play.yml --syntax-check
                    '''
                }
            }
        }

        stage('Run Ansible Playbook') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.RUN_ANSIBLE == true }
                }
            }
            steps {
                dir('ansible-monitoring-stack') {
                    sh '''
                        echo "=== Running Ansible Playbook ==="
                        chmod 400 "${SSH_KEY_FILE}"
                        
                        export ANSIBLE_HOST_KEY_CHECKING=False

                        ansible-playbook play.yml \
                            -e "ansible_ssh_private_key_file=${SSH_KEY_FILE}" \
                            -e "aws_region=${AWS_REGION}" \
                            --inventory=inventory/ \
                            --diff
                    '''
                }
            }
        }
    }

    post {
        success {
            echo """
            ✅ Pipeline Completed Successfully!
            ─────────────────────────────────────
            Action  : ${params.ACTION}
            Branch  : ${env.GIT_BRANCH}
            Build   : #${env.BUILD_NUMBER}
            ─────────────────────────────────────
            """
        }
        failure {
            echo """
            ❌ Pipeline Failed!
            ─────────────────────────────────────
            Action  : ${params.ACTION}
            Branch  : ${env.GIT_BRANCH}
            Build   : #${env.BUILD_NUMBER}
            Check console output for details.
            ─────────────────────────────────────
            """
        }
        always {
            node('built-in') {
                cleanWs()
            }
        }
    }
}
