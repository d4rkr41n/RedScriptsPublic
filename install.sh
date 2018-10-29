#!/bin/bash

echo "*** Don't forget dependacies ***"
echo "sudo apt install xclip"

chmod +x rshells.sh
echo "Linking rshells to /usr/local/bin/rshells"
ln -sf $(pwd)/rshells.sh /usr/local/bin/rshells
