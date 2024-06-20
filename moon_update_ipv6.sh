#!/bin/bash

NETWORK_INTERFACE=eth0
ZEROTIER_ONE_PATH=/var/lib/zerotier-one
MOON_UDP_PORT=9993
IPV6_PREFIX=24

cd ${ZEROTIER_ONE_PATH}
ZEROTIER_ID=$(zerotier-cli info | awk -F"\ " '{print $3}')
echo "Your Zerotier ID is ${ZEROTIER_ID}."
CURRENT_IPV6=$(ifconfig -a | grep -A 6 ${NETWORK_INTERFACE} | awk '{if ($1=="inet6" && $4==128)  print $2}' | grep -v fe80: | grep -v fd*: | grep ${IPV6_PREFIX}*:*)
echo "Current IPv6 address is: ${CURRENT_IPV6}"
if [ ! -e ${ZEROTIER_ONE_PATH}/moon.json ]; then
  echo "Generating moon.json..."
  sudo ${ZEROTIER_ONE_PATH}/zerotier-idtool initmoon ${ZEROTIER_ONE_PATH}/identity.public >> ${ZEROTIER_ONE_PATH}/moon.json
  sudo sed -i "s/\[\]/\[\"${CURRENT_IPV6}\/${MOON_UDP_PORT}\"\]/g" ${ZEROTIER_ONE_PATH}/moon.json
  sudo sed -i "s/${MOON_IPV6}/${CURRENT_IPV6}/g" ${ZEROTIER_ONE_PATH}/moon.json
  sudo zerotier-idtool genmoon ${ZEROTIER_ONE_PATH}/moon.json ${ZEROTIER_ONE_PATH}
  sudo mkdir -p ${ZEROTIER_ONE_PATH}/moons.d
  sudo mv ${ZEROTIER_ONE_PATH}/00000*.moon ${ZEROTIER_ONE_PATH}/moons.d  
  echo "Restarting Zerotier..."
  sudo systemctl restart zerotier-one.service
else
  echo "Find the moon.json at ${ZEROTIER_ONE_PATH}/moon.json"
  MOON_IPV6=$(jq -r '.roots[0].stableEndpoints[0] | split("/")[0]' ${ZEROTIER_ONE_PATH}/moon.json)
  echo "Moon IPv6 address is: ${MOON_IPV6}"
  if [ "${CURRENT_IPV6}" != "${MOON_IPV6}" ]; then
    echo "Updating moon..."
    sudo sed -i "s/${MOON_IPV6}/${CURRENT_IPV6}/g" ${ZEROTIER_ONE_PATH}/moon.json
    sudo zerotier-idtool genmoon ${ZEROTIER_ONE_PATH}/moon.json ${ZEROTIER_ONE_PATH}
    sudo mkdir -p ${ZEROTIER_ONE_PATH}/moons.d
    sudo mv ${ZEROTIER_ONE_PATH}/00000*.moon ${ZEROTIER_ONE_PATH}/moons.d
    echo "Restarting Zerotier..."
    sudo systemctl restart zerotier-one.service
  fi
fi

echo "All Done!"
