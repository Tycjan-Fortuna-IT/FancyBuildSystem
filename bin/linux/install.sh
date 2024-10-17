#!/bin/bash

if ! command -v premake5 > /dev/null 2>&1; then
    echo "Premake not found. Trying to download and install!"

    wget https://github.com/premake/premake-core/releases/download/v5.0.0-beta2/premake-5.0.0-beta2-linux.tar.gz
    tar -xzf premake-5.0.0-beta2-linux.tar.gz
    sudo mv premake5 /usr/local/bin/
    rm premake-5.0.0-beta2-linux.tar.gz
    rm example.so
    rm libluasocket.so

    echo "Premake has been downloaded and installed. Run the script again to prepare the build system!"
else
    echo "Premake found. No need to download and install!"
fi
