#!/bin/bash
yum update -y
yum install docker -y
service docker start
docker run -d -p 80:5000 bnuth/devops-final-app:latest
