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
        def maxRetries = 30
        def retryCount = 0
        def sshSuccess = false
        
        while (retryCount < maxRetries && !sshSuccess) {
          try {
            // Test SSH connection using netcat or ssh directly
            sh """
              echo "Waiting for SSH (Attempt ${retryCount + 1}/${maxRetries})..."
              nc -zv -w 5 ${ec2_ip} 22 && echo "SSH port open" || exit 1
              # Alternative: ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@${ec2_ip} exit
            """
            sshSuccess = true
          } catch (Exception e) {
            retryCount++
            if (retryCount >= maxRetries) {
              error("SSH never became available on ${ec2_ip}")
            }
            sleep(time: 10, unit: 'SECONDS') // Wait 10 seconds between tries
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
        sh """
          chmod 600 ${JEN_KEY} ${PEM_KEY}
          ssh-keygen -y -f ${JEN_KEY} || echo 'Key verification failed'
        """
            // Create inventory
            writeFile file: 'inventory.yml', text: """
all:
  hosts:
    rails-server-1:
      ansible_host: ${ec2_ip}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ${PEM_KEY}
      # Consider setting host key checking in a more secure way
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    rails-server-2:
      ansible_host: ${ec2_ip}
      ansible_user: rpx
      ansible_ssh_private_key_file: ${JEN_KEY}
      # Consider setting host key checking in a more secure way
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
"""

            // Verify inventory
            sh 'cat inventory.yml'

            // Run playbook with verbose output for debugging
            sh 'ansible-playbook -i inventory.yml -vv ansible/deploy.yml'
          }
        }
      }
    }
  }

  post {
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
