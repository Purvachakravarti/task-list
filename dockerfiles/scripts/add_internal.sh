#!/bin/bash

  netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2" host.docker.internal"}' >> /etc/hosts