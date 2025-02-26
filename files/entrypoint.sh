#!/bin/bash

# To be able to use the volumes user aska needs access
doas -u root chown -R aska:aska /home/aska
exec "$@"
