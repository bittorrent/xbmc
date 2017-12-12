// environment var S3_ARTIFACT_BUCKET must be set
// environment var SECRET_BUCKET must be set

pipeline {
  agent any
  stages {
    stage ('Fetch pre-built artifacts') {
      steps {
        sh 'echo fetch pre-built artifacts'
      }
    }

    stage ('Pre-sign') {
      steps {
      sh 'echo pre-signing'
      }
    }

    stage ('Artifact') {
      steps {
        sh 'echo artifacting'
      }
    }
  }
}
