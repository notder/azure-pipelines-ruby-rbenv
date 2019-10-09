[![GitHub](https://img.shields.io/badge/github-azure--pipelines--ruby--rbenv-blue.svg "notder")](https://github.com/notder/azure-pipelines-ruby-rbenv)

# Azure Pepelines Ruby rbenv Docker Image
This image using [ubuntu 16.04 official image](https://hub.docker.com/_/ubuntu) and NodeJS 10.x for run self-hosted agents on Azure Pipelines

### [Running a self-hosted agent in Docker](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops)

# Supported tags and respective `Dockerfile` links

- `latest` [Dockerfile](https://github.com/notder/azure-pipelines-ruby-rbenv/blob/master/Dockerfile)

### Build image
`docker build -t azure-pipelines-ruby-rbenv .`

### [Environment Variable](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#environment-variables)

- AZURE_REPOSITORY_URL: https://dev.azure.com/{your_organization}  
- AZURE_TOKEN: XXXXXXXXXXXXXXXXXXXXXX [Setup](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#authenticate-with-a-personal-access-token-pat)  
- AZURE_POOL: ruby-rbenv [Setup](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops#creating-agent-pools) (`https://dev.azure.com/{your_organization}/_settings/agentpools`)  
- AGENT_NAME: agent-01

### Run docker
```
docker run -e AZP_URL=[AZURE_REPOSITORY_URL] -e AZP_TOKEN=[AZURE_TOKEN] -e AZP_AGENT_NAME=[AGENT_NAME] -e AZP_POOL=[AZURE_POOL] --name [CONTAINER_NAME] notder/azure-pipelines-ruby-rbenv:[TAG_NAME]
```

### Run docker-compose.yml
- mount docker.sock for using docker command
```
version: '3'
services:
  agent-01:
    image: notder/azure-pipelines-ruby-rbenv:latest
    environment:
      AZP_POOL: [agent_pool]
      AZP_AGENT_NAME: [agent_name]
      AZP_URL: https://dev.azure.com/[organization]
      AZP_TOKEN: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
    networks:
      - azure-rbenv-network

networks:
  azure-rbenv-network:
    driver: bridge
```

### Example `azure_pipelines.yml`
```
trigger:
- master
- develop

jobs:
- job: continuous_integration
  pool: ruby-rbenv
  variables:
    RAILS_ENV: 'test'
    COMMIT_ID: '$(Build.SourceVersion)'
  steps:
  - script: yarn install
    displayName: 'Install package'

  - script: |
      cp -f config/database.azure.yml config/database.yml
      cp -f config/application.sample.yml config/application.yml
    displayName: 'Copy file for test'

  - script: |
      export SHORT_COMMIT_ID=${COMMIT_ID:0:7}
      export CONTAINER_NAME=azure-postgres-$SHORT_COMMIT_ID
      export CONTAINER_ID=$(docker run -d --network azure-docker-compose_azure-rbenv-network -e POSTGRES_DB=db-$CONTAINER_NAME -e POSTGRES_USER=tester -e POSTGRES_PASSWORD=password --name $CONTAINER_NAME postgres)
      echo "Database container name $CONTAINER_NAME"
      sed -i "s/localhost/$CONTAINER_NAME/g" config/database.yml
      sed -i "s/azure-test/db-$CONTAINER_NAME/g" config/database.yml
      rbenv install 2.6.3 --skip-existing
      rbenv rehash
      rbenv global 2.6.3
      gem install bundler -v 2.0.2 --force
      bundle install
      bundle exec rake db:migrate
      bundle exec rspec
    displayName: 'Ruby Operation'

- job: cleanup
  pool: ruby-rbenv
  variables:
    COMMIT_ID: '$(Build.SourceVersion)'
  dependsOn: continuous_integration
  condition: always() ## this step will always run, even if the pipeline is cancelled
  steps:
  - script: |
      export SHORT_COMMIT_ID=${COMMIT_ID:0:7}
      export CONTAINER_NAME=azure-postgres-$SHORT_COMMIT_ID
      echo "database container name $CONTAINER_NAME"
      docker rm -f $CONTAINER_NAME
    displayName: 'Remove database container'
```