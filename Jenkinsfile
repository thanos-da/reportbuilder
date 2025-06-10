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
          sh '''
            echo "Using SSH Key at: $PEM_KEY"
            chmod 600 $PEM_KEY

            # Create minimal inventory file
            cat > inventory.yml <<EOF
all:
  children:
    target:
      hosts:
        rails-server:
          ansible_host: 44.201.206.78
          ansible_user: ubuntu
          ansible_ssh_private_key_file: $PEM_KEY
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

        rails-server-2:
          ansible_host: 44.201.206.78
          ansible_user: rpx
          ansible_ssh_private_key_file: $PEM_KEY
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF

            # Run the playbook directly on the target server
            ansible-playbook -i inventory.yml deploy1.yml
          '''
        }
      }
    }

    /*
     * Optional Stage: Generate Inventory Script
     * - Disabled by default, but can be used to generate dynamic inventory
     */
    /*
    stage('Generate Inventory') {
      steps {
        withCredentials([file(credentialsId: 'aws_ec2_key', variable: 'PEM_KEY')]) {
          withEnv(["SSH_USER=ubuntu"]) {
            dir('ansible') {
              sh '''
                chmod +x inventory_create.sh
                ./inventory_create.sh
                echo "--- Generated inventory:"
                cat inventory.yml
              '''
            }
          }
        }
      }
    }
    */

    /*
     * Optional Stage: Alternative Deploy with Ansible
     * - Commented out as it's an alternative to the earlier Ansible deploy stage
     */
    /*
    stage('Deploy with Ansible') {
      steps {
        withCredentials([file(credentialsId: 'aws_ec2_key', variable: 'PEM_KEY')]) {
          dir('ansible') {
            sh '''
              eval `ssh-agent -s`
              chmod 600 $PEM_KEY
              ssh-add $PEM_KEY
              ansible-playbook -i inventory.yml deploy1.yml --extra-vars "branch=${BRANCH}"
            '''
          }
        }
      }
    }
    */
  }
}
