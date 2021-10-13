# oozou DevOps Engineer Assignment

### Contents

This repository contains the following files, in support of an application for the role
of **DevOps Engineer** at oozou:

* A `Dockerfile` that containerizes the example application, with support for multiple 
environments (test, development & production)
* A `docker-compose.yml` file that sets up the Node application, `statsd` and the backend.
* Terraform code to deploy this application stack to a Cloud provider


### Exercise One - Dockerfile

The first commit into this repository contains the files provided by oozou, as well as the following:

* .gitignore - To avoid unwanted/unnecessary files being deployed into github
* Dockerfile - Contains the instructions on how to build the Docker container:
  ```yaml
  # syntax=docker/dockerfile:1
  
  # Pull the latest version of node. Note: In production, there may be valid reasons to pin
  # this to a specific version. For this assignment, this author presumes the latest version
  # is sufficient
  FROM node:latest
  
  # Set the NODE_ENV as specified at buildtime
  # Note, this can be overridden
  ARG BUILDTIME_NODE_ENV
  ENV NODE_ENV=$BUILDTIME_NODE_ENV
  
  RUN mkdir -p /app
  WORKDIR /app
  
  COPY app/ /app
  
  RUN if [ "$BuildMode" = "test" ] ; then npm install --only=development; fi
  
  RUN if [ "$BuildMode" = "development" ] ; then npm install --only=development; fi
  
  RUN if [ "$BuildMode" = "production" ] ; then npm install --only=production; fi
  
  CMD ["node", "index.js"]
  ```
  
    This `Dockerfile` can be run using the following command: `docker build --tag node-docker --build-arg BUILDTIME_NODE_ENV=<ENV> .`
    Where `<ENV>` is one of `test`, `development` or `production`.

### Exercise Two - Docker-Compose

This second commit contains updates to this readme file, as well as a couple of small updates to the
Dockerfile, and the creation of the docker-compose.yml `Docker compose` file. 

This `docker-compose` file contains the following configuration:

```yaml
version: "3"
services:
  nodeapp:
    build:
      context: .
      args:
        BUILDTIME_NODE_ENV: test
  graphite-statsd:
    image: graphiteapp/graphite-statsd
    ports:
      # - 127.0.0.1:2003-2004:2003-2004 carbon receiver - plaintext and pickle. Disabled as not used
      # - 127.0.0.1:2023-2024:2023-2024 carbon aggregator - plaintext and pickle. Disabled as not used
      - 127.0.0.1:8125:8125/udp # Statsd metrics
      - 127.0.0.1:8126:8126 # Statsd admin port
      - 127.0.0.1:80:80 # nginx/admin
```

* The nodeJS application is built into a container called "nodeapp" using the **test** ``BUILDTIME_NODE_ENV``. This maps to the conditional `RUN` for **test** in the Dockerfile.
* statsd has been implemented using the community image (graphiteapp/graphite-statds)
* No ports have been exposed on the `nodeapp` and the ports that are available for the `graphite-statsd` container have been set to localhost only.
