pipeline {
  agent any

  parameters {
    string(name: 'BRANCH', defaultValue: 'main', description: 'Git branch to deploy')
  }

  environment {
    TF_DIR = 'terraform'
    ANSIBLE_DIR = 'ansible'
  }

  stages {
    stage('Terraform Apply') {
      steps {
        script {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws_credentials'
          ]]) {
            dir(TF_DIR) {
              sh '''
                echo "Initializing Terraform..."
                terraform init -input=false
                terraform validate
                echo "Applying Terraform configuration..."
                terraform apply -auto-approve
              '''
            }
          }
        }
      }
    }

    stage('Wait for SSH') {
      steps {
        script {
          // Get EC2 IP from Terraform output
          def ec2_ip = sh(
            script: "terraform -chdir=${env.WORKSPACE}/${TF_DIR} output -raw instance_public_ip",
            returnStdout: true
          ).trim()

          if (!ec2_ip) {
            error("ERROR: Could not get EC2 public IP from Terraform output")
          }

          // Store IP for later stages
          env.EC2_IP = ec2_ip

          def maxRetries = 30
          def retryCount = 0
          def sshSuccess = false
          
          echo "Waiting for SSH to be available on ${ec2_ip}..."
          
          while (retryCount < maxRetries && !sshSuccess) {
            try {
              sh """
                echo "Attempt ${retryCount + 1}/${maxRetries}..."
                nc -zv -w 5 ${ec2_ip} 22
              """
              sshSuccess = true
              echo "SSH connection successful!"
            } catch (Exception e) {
              retryCount++
              if (retryCount >= maxRetries) {
                error("SSH never became available on ${ec2_ip} after ${maxRetries} attempts")
              }
              sleep(time: 10, unit: 'SECONDS')
            }
          }
        }
      }
    }

    stage('Deploy with Ansible') {
      steps {
        script {
          withCredentials([
            file(credentialsId: 'aws_ec2_key', variable: 'PEM_KEY'),
            sshUserPrivateKey(
              credentialsId: 'jenkins_key',
              keyFileVariable: 'JEN_KEY',
              usernameVariable: 'JEN_USER'
            )
          ]) {
            // Set proper permissions for keys
            sh """
              chmod 600 ${JEN_KEY} ${PEM_KEY}
              ssh-keygen -y -f ${JEN_KEY} >/dev/null || echo 'Warning: Key verification failed'
            """

            // Create dynamic inventory
            writeFile file: 'inventory.yml', text: """
all:
  hosts:
    rails-server-1:
      ansible_host: ${env.EC2_IP}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ${PEM_KEY}
      ansible_ssh_common_args: '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new'
    rails-server-2:
      ansible_host: ${env.EC2_IP}
      ansible_user: rpx
      ansible_ssh_private_key_file: ${JEN_KEY}
      ansible_ssh_common_args: '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new'
"""

            // Verify inventory
            sh 'cat inventory.yml'

            // Run playbook with verbose output for debugging
            sh "ansible-playbook -i inventory.yml -vv ${ANSIBLE_DIR}/deploy.yml"
          }
        }
      }
    }
  }

  post {
    failure {
      echo 'Pipeline failed!'
    }
    success {
      echo 'Pipeline succeeded!'
    }
  }
}
