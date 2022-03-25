#!/usr/bin/env bash

# This is a small helper script that generates a service registration file using
# generate_sidecar_configs.py, registers that to Consul, and sets up the appropriate
# directories for systemd to start the sidecar.
#
# Syntax is: connect-inject -service=<service name> -port=<port>

# Exit upon receiving any errors
set -o errexit

SCRIPT_NAME=$(basename "$0")

usage(){
  echo "Usage: $SCRIPT_NAME -service=<name> -port=<port> [-exclude-inbound-port=<port>]"
  exit 1
}

LONG=service:,port:,exclude-inbound-port:
SHORT=s:,p:,e:
OPTS=$(getopt --alternative --name "$SCRIPT_NAME" --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    -p | --port )
      SERVICE_PORT="$2"
      shift 2
      ;;
    -s | --service )
      SERVICE_NAME="$2"
      shift 2
      ;;
    -e | --exclude-inbound-port )
      EXCLUDE_INBOUND_PORT="$2"
      shift 2
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done

# Require service name and port
if [[ -z $SERVICE_PORT || -z $SERVICE_NAME ]]; then
    usage
fi

SERVICE_CONFIG_DIR="/srv/consul/conf/services/${SERVICE_NAME}"
SERVICE_CONFIG_FILE="${SERVICE_CONFIG_DIR}/config.json"

# Create service directory if it does not exist
if [[ ! -d $SERVICE_CONFIG_DIR ]]; then
    mkdir -p "$SERVICE_CONFIG_DIR"
fi

# Create the service config file
jq \
  --raw-output \
  --null-input \
  --arg port "$SERVICE_PORT" \
  --arg service "$SERVICE_NAME" \
  --arg exclude_port "$EXCLUDE_INBOUND_PORT" \
  '{annotations: {"consul.hashicorp.com/connect-service": $service, "consul.hashicorp.com/connect-service-port": $port|tonumber, "consul.hashicorp.com/transparent-proxy": true}} | if ($exclude_port | length) >= 1 then .annotations += {"consul.hashicorp.com/transparent-proxy-exclude-inbound-ports": $exclude_port} else . end' > "$SERVICE_CONFIG_FILE"

if [[ -f "/srv/consul/conf/mesh.json" ]]; then
  CNI_NETWORK=$(jq --raw-output '.network' /srv/consul/conf/mesh.json)
  if [[ (-f "/etc/netns/${SERVICE_NAME}") || (-L "/etc/netns/${SERVICE_NAME}") ]]; then
    # Create /etc/netns/<service name> directory if it does not exist
    rm "/etc/netns/${SERVICE_NAME}"
  fi

  ln --symbolic "/srv/consul/conf/dns/${CNI_NETWORK}" "/etc/netns/${SERVICE_NAME}"
fi

# Create systemd drop-in directory if it does not exist
SYSTEMD_SVC_DROP_IN_DIR="/etc/systemd/system/${SERVICE_NAME}.service.d"
if [[ ! -d "$SYSTEMD_SVC_DROP_IN_DIR" ]]; then
  mkdir "$SYSTEMD_SVC_DROP_IN_DIR"
fi

# Create drop-in file
export SERVICE_NAME=$SERVICE_NAME
envsubst < /srv/consul/conf/systemd-drop-in.template > "${SYSTEMD_SVC_DROP_IN_DIR}/${SERVICE_NAME}.conf"

if [[ $? -ne 0 ]]; then
  echo "Failed to create drop-in file"
  exit 1
fi

# Reload systemd
systemctl daemon-reload

# Generate the service registration file
/srv/consul/generate-sidecar-configs.py --filename "$SERVICE_CONFIG_FILE" --dry --type service-registration > "$SERVICE_CONFIG_DIR/service-registration.json"

# Generate extra arguments
REDIRECT_ARGS=$(/srv/consul/generate-sidecar-configs.py --filename "$SERVICE_CONFIG_FILE" --dry --type redirect)
 jq \
   --raw-output \
   --null-input \
   --arg redirect "$REDIRECT_ARGS" \
   '{redirect: $redirect}' > "$SERVICE_CONFIG_DIR/extra-args.json"

# Assume Consul is up, and register service to Consul
consul services register "$SERVICE_CONFIG_DIR/service-registration.json"
