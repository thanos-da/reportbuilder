pipeline {
  agent any

  parameters {
    string(name: 'BRANCH', defaultValue: 'main', description: 'Git branch to deploy')
  }

  stages {

    /* 
     * Stage: Terraform Apply
     * - Initializes and applies Terraform configuration
     * - Uses AWS credentials stored in Jenkins
     */
    stage('Terraform Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                          credentialsId: 'aws_credentials']]) {
          dir('terraform') {
            sh '''
              echo "Using AWS credentials from Jenkins"
              terraform init
              terraform apply -auto-approve
            '''
          }
        }
      }
    }

    /* 
     * Stage: Deploy with Ansible
     * - Uses PEM key to SSH into EC2 instance(s)
     * - Creates a minimal inventory file on-the-fly
     * - Executes Ansible playbook for deployment
     */
stage('Deploy with Ansible') {
  steps {
    withCredentials([file(credentialsId: 'aws_ec2_key', variable: 'PEM_KEY')]) {
      script {
        def ec2_ip = sh(script: "terraform -chdir=${env.WORKSPACE}/terraform output -raw instance_public_ip", returnStdout: true).trim()

        if (!ec2_ip) {
          error("ERROR: Could not get ec2_public_ip from Terraform.")
        }

        // Create inventory.yml
        writeFile file: 'inventory.yml', text: """
all:
  children:
    target:
      hosts:
        rails-server-1:
          ansible_host: ${ec2_ip}
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ${PEM_KEY}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

        rails-server-2:
          ansible_host: ${ec2_ip}
          ansible_user: rpx
          ansible_ssh_private_key_file: ${PEM_KEY}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
"""

        sh 'cat inventory.yml'

        // Run Ansible
        sh """
          chmod 600 ${PEM_KEY}
          ansible-playbook -i inventory.yml ansible/deploy1.yml
        """
      }
    }
  }
}
  }
}
