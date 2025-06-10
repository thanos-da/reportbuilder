pipeline {
  agent any

  parameters {
    string(name: 'BRANCH', defaultValue: 'main', description: 'Git branch to deploy')
  }

  stages {
    stage('Terraform Apply') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws_credentials'
        ]]) {
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

    stage('Deploy with Ansible') {
      steps {
        withCredentials([
          file(credentialsId: 'aws_ec2_key', variable: 'PEM_KEY'),
          sshUserPrivateKey(credentialsId: 'jenkins_key', keyFileVariable: 'JEN_KEY', usernameVariable: 'JEN_USER')
        ]) {
          script {
            def ec2_ip = sh(
              script: "terraform -chdir=${env.WORKSPACE}/terraform output -raw instance_public_ip",
              returnStdout: true
            ).trim()

            if (!ec2_ip) {
              error("ERROR: Could not get ec2_public_ip from Terraform.")
            }
            
            sh 'chmod 600 ${PEM_KEY} ${JEN_KEY}'

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
          ansible_user: ${JEN_USER}
          ansible_ssh_private_key_file: ${JEN_KEY}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
"""

            sh 'cat inventory.yml'

            sh 'ansible-playbook -i inventory.yml ansible/deploy1.yml'
            
          }
        }
      }
    }
  }
}
