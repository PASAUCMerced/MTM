#!/bin/sh


deploy_pcm() {
    echo "Deploying PCM tools ..."

    rm -rf pcm 2>/dev/zero

    git clone https://github.com/opcm/pcm.git 

    cd pcm

    make -j

    sudo make install

    cd -
}

echo "Install PCM"
if [ "`which pcm-memory`" = "" ];then
    deploy_pcm
fi
echo "Finished."

