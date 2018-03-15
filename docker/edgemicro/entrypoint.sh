#!/bin/bash

# Log Location on Server.
LOG_LOCATION=/opt/apigee/logs
exec > >(tee -i $LOG_LOCATION/edgemicro.log)
exec 2>&1

echo "Log Location should be: [ $LOG_LOCATION ]"

echo $EDGEMICRO_DECORATOR >> /tmp/test.txt
echo $EDGEMICRO_ORG >> /tmp/test.txt
echo $EDGEMICRO_ENV >> /tmp/test.txt
echo $EDGEMICRO_KEY >> /tmp/test.txt
echo $EDGEMICRO_SECRET >> /tmp/test.txt
echo $EDGEMICRO_MGMTURL >> /tmp/test.txt
echo $EDGEMICRO_ADMINEMAIL >> /tmp/test.txt
echo $EDGEMICRO_ADMINPASSWORD >> /tmp/test.txt
echo $POD_NAME >> /tmp/test.txt
echo $POD_NAMESPACE >> /tmp/test.txt
echo $INSTANCE_IP >> /tmp/test.txt
SERVICE_NAME=`echo "${SERVICE_NAME}" | tr '[a-z]' '[A-Z]'`
echo $SERVICE_NAME >> /tmp/test.txt
SERVICE_PORT_NAME=${SERVICE_NAME}_SERVICE_PORT
SERVICE_PORT=${!SERVICE_PORT_NAME}
echo $SERVICE_PORT >> /tmp/test.txt
proxy_name=edgemicro_$POD_NAME


if [ ${EDGEMICRO_CONFIG} != "" ]; then
	echo ${EDGEMICRO_CONFIG} >> /tmp/test.txt
	echo ${EDGEMICRO_CONFIG} | base64 --decode > /opt/apigee/.edgemicro/$EDGEMICRO_ORG-$EDGEMICRO_ENV-config.yaml
	# Decorate Proxy with the proxy name
  sed -i.bak s/proxy_name/${proxy_name}/g /tmp/proxies.yaml
  sed -i.bak '/edgemicro:/r /tmp/proxies.yaml' /opt/apigee/.edgemicro/$EDGEMICRO_ORG-$EDGEMICRO_ENV-config.yaml
  chown apigee:apigee /opt/apigee/.edgemicro/*
fi

su - apigee -m -c "cd /opt/apigee && edgemicro start" 
#edgemicro start &

# SIGUSR1-handler
my_handler() {
  echo "my_handler" >> /tmp/entrypoint.log
  su - apigee -m -c "cd /opt/apigee && edgemicro stop"
  #edgemicro stop 
}

# SIGTERM-handler
term_handler() {
  echo "term_handler" >> /tmp/entrypoint.log
  su - apigee -m -c "cd /opt/apigee && edgemicro stop"
  #edgemicro stop
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

