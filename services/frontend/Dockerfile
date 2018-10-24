FROM node:10.12.0-alpine

# Install Global Depedencies
RUN apk add --no-cache yarn
RUN apk add --no-cache git
RUN apk add --no-cache python
RUN apk add --no-cache g++
RUN apk add --no-cache make

# Create app directory
WORKDIR /opt/application

ENV NODE_ENV test

# Install app dependencies
COPY package*.json ./
COPY yarn.lock ./

RUN yarn

# copy app source
COPY . .
