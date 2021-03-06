#!/bin/bash

# Exit script if return code != 0
set -e

# Add user "nobody" to primary group "users" (will remove any other group membership)
usermod -g users nobody

# Add user "nobody" to secondary group "nobody" (will retain primary membership)
usermod -a -G nobody nobody

# Setup env for user nobody
mkdir -p /home/nobody
chown -R nobody:users /home/nobody
chmod -R 775 /home/nobody
