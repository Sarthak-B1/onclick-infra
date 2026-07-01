pipeline {
    agent any

    triggers {
        githubPush()
    }

    /*
     * ─────────────────────────────────────────────
     *  Terraform + Ansible – Monitoring Stack CI/CD
     *  Owner  : Sarthak Bhatnagar
     *  Project: Monitoring Infrastructure (AWS)
     * ─────────────────────────────────────────────
     */

    // ── Environment Variables ──────────────────────────────────────────────
    environment {
        // PATH fix: Jenkins shell doesn't load ~/.zshrc so Homebrew tools not found
        PATH               = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${env.PATH}"

        // AWS credentials stored as Jenkins secret text credentials
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'ap-south-1'

        // S3 backend (must match backend.tf)
        TF_STATE_BUCKET    = 'sarthak-prometheus-tfstate-2026-ap-south-1'
        TF_STATE_KEY       = 'terraform/terraform.tfstate'
        TF_DYNAMO_TABLE    = 'terraform-lock-table'

        // SSH key for Ansible (stored as Jenkins secret file credential)
        SSH_KEY_FILE       = credentials('monitoring-ssh-private-key')

        // Terraform workspace / environment label
        TF_ENV             = "${params.ENVIRONMENT ?: 'production'}"

        // Paths
        TF_DIR             = '.'
        ANSIBLE_DIR        = 'ansible-monitoring-stack'
    }

    // ── Parameters ─────────────────────────────────────────────────────────
    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'plan'],
            description: 'Terraform action to perform'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['production', 'staging'],
            description: 'Target environment'
        )
        string(
            name: 'INSTANCE_TYPE',
            defaultValue: 't3.micro',
            description: 'EC2 instance type (e.g. t3.micro, t3.small)'
        )
        booleanParam(
            name: 'RUN_ANSIBLE',
            defaultValue: true,
            description: 'Run Ansible provisioning after Terraform apply?'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: true,
            description: 'Auto-approve Terraform apply/destroy without manual confirmation?'
        )
    }

    // ── Options ────────────────────────────────────────────────────────────
    options {
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
    }

    // ══════════════════════════════════════════════════════════════════════
    //  S T A G E S
    // ══════════════════════════════════════════════════════════════════════
    stages {

        // ── 1. Checkout ───────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "📥 Checking out source code..."
                checkout scm
            }
        }

        // ── 2. Validate Tools ─────────────────────────────────────────────
        stage('Validate Tools') {
            steps {
                sh '''
                    echo "🔧 Verifying required tools..."
                    terraform version
                    ansible --version
                    aws --version
                '''
            }
        }

        // ── 3. Terraform Init ─────────────────────────────────────────────
        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        echo "🚀 Initialising Terraform with S3 backend..."
                        terraform init \
                            -backend-config="bucket=${TF_STATE_BUCKET}" \
                            -backend-config="key=${TF_STATE_KEY}" \
                            -backend-config="region=${AWS_DEFAULT_REGION}" \
                            -backend-config="encrypt=true" \
                            -backend-config="dynamodb_table=${TF_DYNAMO_TABLE}" \
                            -reconfigure \
                            -input=false
                    '''
                }
            }
        }

        // ── 4. Terraform Validate ─────────────────────────────────────────
        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        echo "✅ Validating Terraform configuration..."
                        terraform validate
                    '''
                }
            }
        }

        // ── 5. Terraform Format Check ─────────────────────────────────────
        stage('Terraform Format Check') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        echo "🎨 Checking Terraform formatting..."
                        terraform fmt -check -recursive || \
                            (echo "⚠️  Some files are not formatted. Run: terraform fmt -recursive" && exit 1)
                    '''
                }
            }
        }

        // ── 6. Terraform Plan ─────────────────────────────────────────────
        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        echo "📋 Generating Terraform plan..."
                        terraform plan \
                            -var="aws_region=${AWS_DEFAULT_REGION}" \
                            -var="instance_type=${INSTANCE_TYPE}" \
                            -var="key_name=sarthak" \
                            -out=tfplan.out \
                            -input=false -no-color > tfplan.txt
                        cat tfplan.txt
                    '''
                }
                archiveArtifacts artifacts: 'tfplan.out,tfplan.txt', allowEmptyArchive: false
            }
        }

        // ── 7. Approval Gate (Apply / Destroy only) ───────────────────────
        stage('Approval Gate') {
            when {
                allOf {
                    expression { params.ACTION in ['apply', 'destroy'] }
                    expression { !params.AUTO_APPROVE }
                }
            }
            steps {
                script {
                    def planOutput = "Plan output not found."
                    if (fileExists("${TF_DIR}/tfplan.txt")) {
                        planOutput = readFile("${TF_DIR}/tfplan.txt")
                    }
                    def actionColor = params.ACTION == 'destroy' ? '⚠️  DESTROY' : '✅ APPLY'
                    input(
                        message: "${actionColor} – Are you sure you want to ${params.ACTION.toUpperCase()} the ${params.ENVIRONMENT} monitoring stack?",
                        ok: 'Proceed',
                        submitter: 'admin,ops-team',
                        parameters: [
                            text(name: 'Terraform Plan', description: 'Review the plan before proceeding:', defaultValue: planOutput)
                        ]
                    )
                }
            }
        }

        // ── 8. Terraform Apply ────────────────────────────────────────────
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        echo "🏗️  Applying Terraform plan..."
                        terraform apply \
                            -input=false \
                            -auto-approve \
                            tfplan.out
                    '''
                }
            }
        }

        // ── 9. Capture Terraform Outputs ──────────────────────────────────
        stage('Capture Outputs') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh '''
                            echo "📤 Capturing Terraform outputs..."
                            terraform output -json > tf-outputs.json
                            cat tf-outputs.json
                        '''
                        archiveArtifacts artifacts: 'tf-outputs.json', allowEmptyArchive: false
                    }
                }
            }
        }

        // ── 10. Ansible Provisioning ──────────────────────────────────────
        stage('Ansible Provision') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    expression { params.RUN_ANSIBLE }
                }
            }
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh '''
                        echo "🤖 Starting Ansible provisioning..."
                        chmod 600 "${SSH_KEY_FILE}"

                        # Force SSH to use ONLY the Jenkins credential key
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        export ANSIBLE_PRIVATE_KEY_FILE="${SSH_KEY_FILE}"

                        ansible-playbook play.yml \
                            --private-key="${SSH_KEY_FILE}" \
                            --inventory=inventory/ \
                            --ssh-extra-args="-o IdentitiesOnly=yes -o IdentityFile=${SSH_KEY_FILE}" \
                            --diff \
                            -v
                    '''
                }
            }
        }

    } // end of stages

    // ══════════════════════════════════════════════════════════════════════
    //  P O S T   A C T I O N S
    // ══════════════════════════════════════════════════════════════════════
    post {
        always {
            // node block required for sh and cleanWs to have FilePath context
            node('built-in') {
                echo "🧹 Cleaning up workspace..."
                sh 'rm -f tfplan.out tf-outputs.json || true'
                cleanWs()
            }
        }

        success {
            echo "✅ Pipeline completed successfully!"
            // Uncomment and configure to send Slack/email notifications:
            // slackSend(
            //     channel: '#devops-alerts',
            //     color: 'good',
            //     message: "✅ *${env.JOB_NAME}* #${env.BUILD_NUMBER} succeeded!\nAction: ${params.ACTION} | Env: ${params.ENVIRONMENT}\n${env.BUILD_URL}"
            // )
        }

        failure {
            echo "❌ Pipeline FAILED!"
            // slackSend(
            //     channel: '#devops-alerts',
            //     color: 'danger',
            //     message: "❌ *${env.JOB_NAME}* #${env.BUILD_NUMBER} FAILED!\nAction: ${params.ACTION} | Env: ${params.ENVIRONMENT}\n${env.BUILD_URL}"
            // )
        }

        aborted {
            echo "⚠️  Pipeline was aborted."
        }
    }
}
