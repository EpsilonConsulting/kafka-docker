#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/bitnami/scripts/libkafka.sh
. /opt/bitnami/scripts/libos.sh

# Load Kafka environment variables
eval "$(kafka_env)"

if [[ "${KAFKA_CFG_LISTENERS:-}" =~ SASL ]] || [[ "${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP:-}" =~ SASL ]]; then
    export KAFKA_OPTS="-Djava.security.auth.login.config=${KAFKA_CONF_DIR}/kafka_jaas.conf"
fi

flags=("$KAFKA_CONF_FILE")
[[ -z "${KAFKA_EXTRA_FLAGS:-}" ]] || flags=("${flags[@]}" "${KAFKA_EXTRA_FLAGS[@]}")
START_COMMAND=("$KAFKA_HOME/bin/kafka-server-start.sh" "${flags[@]}")

info "** Starting Kafka **"
if am_i_root; then
    exec gosu "$KAFKA_DAEMON_USER" "${START_COMMAND[@]}" &
else
    exec "${START_COMMAND[@]}" &
fi

{
./opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic my-test-topic || true
} &> /dev/null

./opt/bitnami/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic my-test-topic

echo "TEST"
