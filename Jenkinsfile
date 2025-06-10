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
              terraform init -input=false
              terraform validate
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
            // Get EC2 IP
            def ec2_ip = sh(
              script: "terraform -chdir=${env.WORKSPACE}/terraform output -raw instance_public_ip",
              returnStdout: true
            ).trim()

            if (!ec2_ip) {
              error("ERROR: Could not get ec2_public_ip from Terraform.")
            }
            
            // Set proper permissions for keys
            sh "chmod 600 ${PEM_KEY} ${JEN_KEY}"

            // Create inventory
            writeFile file: 'inventory.yml', text: """
all:
  hosts:
    rails-server:
      ansible_host: ${ec2_ip}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ${PEM_KEY}
      # Consider setting host key checking in a more secure way
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
"""

            // Verify inventory
            sh 'cat inventory.yml'

            // Run playbook with verbose output for debugging
            sh 'ansible-playbook -i inventory.yml -vv ansible/deploy1.yml'
          }
        }
      }
    }
  }

  post {
    always {
      // Cleanup or notifications could go here
      echo 'Pipeline completed - cleanup if needed'
    }
    failure {
      // Send failure notification
      echo 'Pipeline failed!'
    }
    success {
      // Send success notification
      echo 'Pipeline succeeded!'
    }
  }
}
