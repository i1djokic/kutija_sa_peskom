# Jenkins & Groovy Pipeline — DevOps Cheatsheet

## Pipeline Structure

```groovy
// Declarative Pipeline
pipeline {
    agent any
    // agent { label 'linux' }
    // agent { docker { image 'node:20' } }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    environment {
        APP = 'myapp'
        REGISTRY = credentials('docker-registry')
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'])
        booleanParam(name: 'DEPLOY', defaultValue: false)
    }

    triggers {
        cron('0 2 * * *')
        pollSCM('H/5 * * * *')
    }

    tools {
        nodejs 'node-20'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build') {
            when {
                branch 'main'
                expression { return params.DEPLOY }
            }
            steps {
                sh 'npm install'
                sh 'npm run build'
            }
        }
        stage('Test') {
            parallel {
                stage('Unit') {
                    steps { sh 'npm run test:unit' }
                }
                stage('Lint') {
                    steps { sh 'npm run lint' }
                }
            }
        }
        stage('Publish') {
            steps {
                script {
                    docker.build("${REGISTRY}/${APP}:${BUILD_NUMBER}").push()
                }
            }
        }
        stage('Deploy') {
            input {
                message "Deploy to ${params.ENV}?"
                ok 'Deploy'
            }
            steps {
                sh "kubectl set image deployment/${APP} app=${REGISTRY}/${APP}:${BUILD_NUMBER}"
            }
        }
    }

    post {
        always   { cleanWs() }
        success  { emailext(subject: 'OK', to: 'team@co.io') }
        failure  { emailext(subject: 'FAILED', to: 'team@co.io') }
        changed  { script { /* only on status change */ } }
    }
}
```

## Scripted Pipeline

```groovy
node('linux') {
    stage('Checkout') {
        checkout scm
    }
    stage('Build') {
        sh 'make build'
    }
    stage('Test') {
        try {
            sh 'make test'
        } catch (e) {
            currentBuild.result = 'UNSTABLE'
        }
    }
    stage('Deploy') {
        if (env.BRANCH_NAME == 'main') {
            sh 'make deploy'
        }
    }
}
```

## Shared Library

```groovy
// vars/buildApp.groovy
def call(String app, String version) {
    sh "docker build -t ${app}:${version} ."
}

// usage in pipeline
@Library('my-lib@main') _
buildApp('myapp', BUILD_NUMBER)
```

## Groovy Basics (for Jenkins)

```groovy
// Variables
def name = 'hello'
def list = [1, 2, 3]
def map = [key: 'val', num: 42]

// Strings
"Hello ${name}"        // interpolation
'plain string'         // no interpolation
"""multi
line"""

// Loops
for (i in list) { println i }
list.each { println it }
(0..5).each { println it }

// Conditionals
if (x) { ... } else if (y) { ... } else { ... }
switch(x) { case 1: ...; break; default: ... }

// Collections
list << 4              // append
list.add(4)
list.remove(0)
list.size()
list.contains(1)
list.collect { it * 2 }      // map
list.findAll { it > 1 }      // filter
list.any { it > 0 }          // some
list.every { it > 0 }        // every

map.key
map['key']
map.put('k2', 'v2')
map.findAll { k, v -> v > 0 }
map.collect { k, v -> "${k}=${v}" }

// Closures
def fn = { String x -> println x }
fn.call('hello')
list.each { println it }
```

## Environment & Credentials

```groovy
env.BUILD_NUMBER
env.BRANCH_NAME
env.WORKSPACE
env.JOB_NAME
env.BUILD_URL
env.GIT_COMMIT
env.STAGE_NAME

withCredentials([string(credentialsId: 'secret', variable: 'TOKEN')]) {
    sh "curl -H 'Authorization: Bearer $TOKEN' url"
}

withDockerRegistry([credentialsId: 'docker-creds', url: 'https://registry.io']) {
    sh 'docker push ...'
}
```

## Common Steps

```groovy
sh 'ls -la'
sh(script: 'make build', returnStdout: true)

checkout([$class: 'GitSCM',
    branches: [[name: '*/main']],
    userRemoteConfigs: [[url: 'https://github.com/org/repo.git']]])

git branch: 'main', url: 'https://github.com/org/repo.git'

dir('subdir') { sh 'pwd' }

echo "Hello"
error "Something went wrong"   // fail pipeline
warn("deprecated")             // warning

timeout(10) { ... }
retry(3) { ... }
sleep(5)

fileExists('path')
isUnix()

readFile('file.txt')
writeFile(file: 'out.txt', text: 'data')

load 'script.groovy'           // execute groovy script
tool name: 'maven-3'           // use configured tool

stash name: 'artifacts', includes: 'dist/**'
unstash 'artifacts'

archiveArtifacts artifacts: 'dist/**/*.zip', fingerprint: true

build job: 'downstream', parameters: [string(name: 'VER', value: '1.0')], wait: false
```

## Notifications

```groovy
emailext(
    to: 'team@co.io',
    subject: "Build ${currentBuild.result}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
    body: "${env.BUILD_URL}",
    attachLog: true
)

slackSend(channel: '#ci', message: "Build ${currentBuild.result}: ${env.BUILD_URL}")
```

## Pipeline Utility Steps

```groovy
// read/write JSON
def data = readJSON file: 'config.json'
writeJSON file: 'out.json', json: data

// read/write YAML
def cfg = readYaml file: 'values.yaml'
writeYaml file: 'out.yaml', data: cfg

// find files
def files = findFiles(glob: '**/*.log')

// zip/unzip
zip zipFile: 'archive.zip', dir: 'dist'
unzip zipFile: 'archive.zip', dir: 'out'
```

## Snippet: Matrix

```groovy
matrix {
    axes {
        axis {
            name 'OS'
            values 'linux', 'windows'
        }
        axis {
            name 'BROWSER'
            values 'chrome', 'firefox'
        }
    }
    stages {
        stage('Test') {
            steps {
                echo "OS=${OS}, Browser=${BROWSER}"
            }
        }
    }
}
```

## Snippet: Parallel

```groovy
parallel(
    unit: { sh 'npm test:unit' },
    integ: { sh 'npm test:integration' },
    failFast: true
)
```

## Snippet: Conditional Stages

```groovy
stage('Deploy') {
    when {
        branch 'main'
        expression { env.CHANGE_ID == null }  // not a PR
        allOf { ... }   // AND
        anyOf { ... }   // OR
        not { ... }
    }
    steps { ... }
}
```

## Common Patterns

```groovy
// Increment version
def version = readFile('VERSION').trim()
writeFile file: 'VERSION', text: version

// Docker build + push
script {
    def img = docker.build("myapp:${BUILD_NUMBER}", '--build-arg VERSION=1.0 .')
    img.push()
    img.push('latest')
}

// Conditional post
post {
    regression { emailext subject: 'New failures' }
    fixed { emailext subject: 'Now green' }
}

// Manual approval
input id: 'approve', message: 'Deploy to prod?', ok: 'Go'

// Abort hanging
timeout(activity: true, time: 30) { sh 'make test' }
```

## Key Concepts

| Concept | Summary |
|---------|---------|
| **Declarative** | structured, `pipeline {}`, simpler |
| **Scripted** | groovy-native, `node {}`, more flexible |
| **Shared Library** | reusable pipeline code in `vars/` and `src/` |
| **Agent** | where pipeline runs (any, label, docker) |
| **Stage** | logical phase (build, test, deploy) |
| **Step** | single action (sh, git, echo) |
| **Post** | cleanup based on result |
| **When** | conditional stage execution |
| **Input** | manual approval gate |
| **Tools** | auto-install configured tools |
| **Credentials** | bind secret to var |
| **Stash/Unstash** | pass files between stages on different nodes |
