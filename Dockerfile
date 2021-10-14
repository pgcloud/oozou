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

RUN if [ "$BUILDTIME_NODE_ENV" = "test" ] ; then npm install --only=development; fi

RUN if [ "$BUILDTIME_NODE_ENV" = "development" ] ; then npm install --only=development; fi

RUN if [ "$BUILDTIME_NODE_ENV" = "production" ] ; then npm install --only=production; fi

CMD ["node", "index.js"]
