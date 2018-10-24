# This Dockerfile is mainly used for CI testing
# The build directory is served by Netlify
# It also has a http server as default command for development only. 

FROM node:10.12.0-alpine

# Install global depedencies
RUN apk add --no-cache yarn
RUN apk add --no-cache git
RUN apk add --no-cache python
RUN apk add --no-cache g++
RUN apk add --no-cache make
RUN yarn global add serve

# Define app directory
WORKDIR /opt/application

# Dotenv environment name
ENV NODE_ENV test

# Install app dependencies
COPY package*.json ./
COPY yarn.lock ./

# See https://git.io/fx1W5  https://git.io/fx1RF  # debug with --verbose
RUN yarn install --ignore-optional --frozen-lockfile --network-timeout 1000000 --network-concurrency 1 

# Copy app source
COPY . .

EXPOSE 5000

# Build and serve
# For now we are avoiding running yarn build during docker build stage to reduce CI times
CMD yarn build && serve --single ./build --listen tcp://0.0.0.0:5000