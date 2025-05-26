pipeline {
  agent any

  environment {
    SONARQUBE = 'SonarQube' // Match the name in Jenkins Configure System
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/barick4u/sast.git'
      }
    }

    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv("${SONARQUBE}") {
          sh 'sonar-scanner'
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 1, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
  }
}
