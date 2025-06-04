pipeline {
  agent any

  parameters {
    string(name: 'BRANCH', defaultValue: 'main', description: 'Git branch to deploy')
  }

  stages {
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

    stage('Generate Inventory') {
      steps {
        dir('ansible') {
          sh 'chmod +x inventory_create.sh'
          sh './inventory_create.sh'
        }
      }
    }

    stage('Deploy with Ansible') {
      steps {
        withCredentials([file(credentialsId: 'aws_ec2_key', variable: 'PEM_KEY')]) {
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
