def repoUrl = System.getenv("REPO_URL") ?: "https://github.com/your-user/devops-complete-setup.git"

pipelineJob('java-crud-ci-cd') {
  description('End-to-end CI/CD pipeline for sample Java CRUD app.')
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url(repoUrl)
          }
          branches('*/main')
          extensions {
            wipeOutWorkspace()
          }
        }
      }
      scriptPath('jenkins/Jenkinsfile')
    }
  }
  triggers {
    scm('H/30 * * * *')
  }
}
