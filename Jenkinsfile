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
    EC2_IP=$(terraform -chdir=../terraform output -raw instance_public_ip)

    # Validate
        if [[ -z "$EC2_IP" ]]; then
         echo "ERROR: Could not get ec2_public_ip from Terraform."
        exit 1
        fi

    # These env vars are passed from Jenkins
        SSH_USER="${SSH_USER:-ubuntu}"
        PEM_PATH="${PEM_KEY}"

    # Write inventory.yml directly
        cat <<EOF > inventory.yml
        all:
        children:
            target:
            hosts:
                rails-server:
                ansible_host: $EC2_IP
                ansible_user: $SSH_USER
                ansible_ssh_private_key_file: $PEM_KEY
                ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

                rails-server-2:
                ansible_host: $EC2_IP
                ansible_user: rpx
                ansible_ssh_private_key_file: $jenkins_key
                ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
        EOF
        sh 'cat inventory.yml'
              # Run the Ansible playbook
              ansible-playbook -i inventory.yml playbook.yml
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
