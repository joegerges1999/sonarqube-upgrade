properties = null

pipeline {
   agent {
       label 'jgerges'
   }
   
   parameters {
       choice(choices:['sonarqube', 'nexus', 'fitnesse'], description: 'App to upgrade', name: 'app')          
       string (defaultValue:"", description: "Version to upgrade to", name: "upgrade_version")
       string (defaultValue: "", description: "Your team name", name: "team")
   }

   stages {
      stage('copying files & pulling from github') {
         steps {
            sh 'mkdir /data/${team} /data/${team}/${app}'
            sh 'git clone https://github.com/joegerges1999/properties.git /data/${team}/${app}/properties'
            script {
               properties = readProperties file: "/data/${team}/${app}/properties/rancher.properties"
            }
            sh 'git clone https://github.com/joegerges1999/${app}-upgrade.git /data/${team}/${app}/upgrade'
         }
      }
      stage('running the upgrade operation') {
          steps {
              sh 'chmod +x /data/${team}/${app}/upgrade/upgrade.sh'
              sh "/data/${team}/${app}/upgrade/upgrade.sh ${team} ${upgrade_version} ${app} $properties.cluster_id $properties.project_id $properties.token"
          }
      }
      stage('cleaning up machine') {
         steps {
             sh 'rm -rf /data/${team}'
         }
      }
    }
}
