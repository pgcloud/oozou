#! /bin/bash
sudo apt update

## Install Docker and Docker compose
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo apt install -y docker.io

sudo mkdir -p /opt/app/
sudo chown ubuntu:ubuntu -R /opt/app/
cat <<-EOF > /opt/app/index.js
const lynx = require('lynx');

// instantiate a metrics client
//  Note: the metric hostname is hardcoded here
const metrics = new lynx('graphite-statsd', 8125);

// sleep for a given number of milliseconds
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  // send message to the metrics server
  metrics.timing('test.core.delay', Math.random() * 1000);

  // sleep for a random number of milliseconds to avoid flooding metrics server
  return sleep(3000);
}

// infinite loop
(async () => {
  console.log("🚀🚀🚀");
  while (true) { await main() }
})()
  .then(console.log, console.error);
EOF

cat <<-EOF > /opt/app/package.json
{
  "name": "devops-test",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"PASS\" && exit 0"
  },
  "author": "",
  "license": "UNLICENSED",
  "dependencies": {
    "lynx": "^0.2.0"
  }
}
EOF

cat <<-EOF > /opt/app/package-lock.json
{
  "name": "devops-test",
  "version": "1.0.0",
  "lockfileVersion": 2,
  "requires": true,
  "packages": {
    "": {
      "name": "devops-test",
      "version": "1.0.0",
      "license": "UNLICENSED",
      "dependencies": {
        "lynx": "^0.2.0"
      }
    },
    "node_modules/lynx": {
      "version": "0.2.0",
      "resolved": "https://registry.npmjs.org/lynx/-/lynx-0.2.0.tgz",
      "integrity": "sha1-eeZnRTDaQYPoeVO9aGFx4HDaULk=",
      "dependencies": {
        "mersenne": "~0.0.3",
        "statsd-parser": "~0.0.4"
      }
    },
    "node_modules/mersenne": {
      "version": "0.0.4",
      "resolved": "https://registry.npmjs.org/mersenne/-/mersenne-0.0.4.tgz",
      "integrity": "sha1-QB/ex+whzbngPNPTAhOY2iGycIU="
    },
    "node_modules/statsd-parser": {
      "version": "0.0.4",
      "resolved": "https://registry.npmjs.org/statsd-parser/-/statsd-parser-0.0.4.tgz",
      "integrity": "sha1-y9JDlTzELv/VSLXSI4jtaJ7GOb0="
    }
  },
  "dependencies": {
    "lynx": {
      "version": "0.2.0",
      "resolved": "https://registry.npmjs.org/lynx/-/lynx-0.2.0.tgz",
      "integrity": "sha1-eeZnRTDaQYPoeVO9aGFx4HDaULk=",
      "requires": {
        "mersenne": "~0.0.3",
        "statsd-parser": "~0.0.4"
      }
    },
    "mersenne": {
      "version": "0.0.4",
      "resolved": "https://registry.npmjs.org/mersenne/-/mersenne-0.0.4.tgz",
      "integrity": "sha1-QB/ex+whzbngPNPTAhOY2iGycIU="
    },
    "statsd-parser": {
      "version": "0.0.4",
      "resolved": "https://registry.npmjs.org/statsd-parser/-/statsd-parser-0.0.4.tgz",
      "integrity": "sha1-y9JDlTzELv/VSLXSI4jtaJ7GOb0="
    }
  }
}
EOF

# Dockerfile
cat <<-EOF > /opt/Dockerfile
# syntax=docker/dockerfile:1

# Pull the latest version of node. Note: In production, there may be valid reasons to pin
# this to a specific version. For this assignment, this author presumes the latest version
# is sufficient
FROM node:latest

# Set the NODE_ENV as specified at buildtime
# Note, this can be overridden
ARG BUILDTIME_NODE_ENV
ENV NODE_ENV=\$BUILDTIME_NODE_ENV

RUN mkdir -p /app
WORKDIR /app

COPY app/ /app

RUN if [ "\$BUILDTIME_NODE_ENV" = "test" ] ; then npm install --only=development; fi

RUN if [ "\$BUILDTIME_NODE_ENV" = "development" ] ; then npm install --only=development; fi

RUN if [ "\$BUILDTIME_NODE_ENV" = "production" ] ; then npm install --only=production; fi

CMD ["node", "index.js"]

EOF

# docker-compose
cat <<-EOF > /opt/docker-compose.yml
version: "3"
services:
  nodeapp:
    build:
      context: .
      args:
        BUILDTIME_NODE_ENV: production
  graphite-statsd:
    image: graphiteapp/graphite-statsd
    ports:
      # - 127.0.0.1:2003-2004:2003-2004 carbon receiver - plaintext and pickle. Disabled as not used
      # - 127.0.0.1:2023-2024:2023-2024 carbon aggregator - plaintext and pickle. Disabled as not used
      - 127.0.0.1:8125:8125/udp # Statsd metrics
      - 127.0.0.1:8126:8126 # Statsd admin port
      - 80:80 # nginx/admin
EOF

cd /opt/
docker-compose up -d
