#!/bin/bash

if [ "$1" = './grakn' ]; then

  : ${STORAGE_LISTEN_ADDRESS='auto'}
  if [ "$STORAGE_LISTEN_ADDRESS" = 'auto' ]; then
    STORAGE_LISTEN_ADDRESS="$(hostname --ip-address)"
  fi

  : ${STORAGE_BROADCAST_ADDRESS="$STORAGE_LISTEN_ADDRESS"}
  : ${STORAGE_RPC_ADDRESS:=$STORAGE_LISTEN_ADDRESS}

  if [ "$STORAGE_BROADCAST_ADDRESS" = 'auto' ]; then
    STORAGE_BROADCAST_ADDRESS="$(hostname --ip-address)"
  fi

  : ${STORAGE_BROADCAST_RPC_ADDRESS:=$STORAGE_BROADCAST_ADDRESS}

  if [ -n "${STORAGE_NAME:+1}" ]; then
    : ${STORAGE_SEEDS:="cassandra"}
  fi
  : ${STORAGE_SEEDS:="$STORAGE_BROADCAST_ADDRESS"}

  sed -ri 's/(- seeds:).*/\1 "'"$STORAGE_SEEDS"'"/' "$STORAGE_CONFIG/cassandra.yaml"

  for yaml in \
    broadcast_address \
    broadcast_rpc_address \
    cluster_name \
    endpoint_snitch \
    listen_address \
    num_tokens \
    rpc_address \
    start_rpc \
  ; do
    var="STORAGE_${yaml^^}"
    val="${!var}"
    if [ "$val" ]; then
      sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$STORAGE_CONFIG/cassandra.yaml"
    fi
  done

  # Fix queue bind address
  sed -ri 's/^bind 127.0.0.1/bind '"${STORAGE_LISTEN_ADDRESS}"'/' /grakn/services/redis/redis.conf

  # Fix connections strings in grakn.properties
  sed -ri 's/^storage.hostname=.*/storage.hostname='"${STORAGE_LISTEN_ADDRESS}"'/' /grakn/conf/grakn.properties
  sed -ri 's/^queue.host=.*/queue.host='"${STORAGE_LISTEN_ADDRESS}"':6379/' /grakn/conf/grakn.properties

  # Ensure queue directory exists
  mkdir -p /grakn/db/redis

fi

exec "$@"
