pipeline {
  agent any

  parameters {
    string(name: 'BRANCH', defaultValue: 'main', description: 'Git branch to deploy')
  }

  environment {
    ANSIBLE_FORCE_COLOR = "true"
  }

  stages {
    stage('Terraform Apply') {
      steps {
        dir('terraform') {
          sh 'terraform init && terraform apply -auto-approve'
        }
      }
    }

    stage('Generate Inventory') {
      steps {
        dir('ansible') {
          sh './gen_inventory.sh'
        }
      }
    }

    stage('Deploy with Ansible') {
      steps {
        withCredentials([file(credentialsId: 'ec2_ssh_key', variable: 'PEM_KEY')]) {
          dir('ansible') {
            sh '''
              eval `ssh-agent -s`
              chmod 600 $PEM_KEY
              ssh-add $PEM_KEY
              ansible-playbook -i inventory.yml deploy.yml --extra-vars "branch=${BRANCH}"
            '''
          }
        }
      }
    }
  }
}
