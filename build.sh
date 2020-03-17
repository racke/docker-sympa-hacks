#! /bin/bash

docker build -t sympa:6.2.52 .
docker build -t dancer:0.0.1 -f Dockerfile.Dancer .
