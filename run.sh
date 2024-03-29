#!/bin/sh
set -e

if [ -z "$1" ]; then
	echo "The server argument must be set."
	exit 1
fi

if [ -z "$2" ]; then
	echo "The concurrency argument must be set."
	exit 1
fi

if [ "$LOG_ADDRESS" ]; then
	LOG="log $LOG_ADDRESS format rfc5424 local0"
	if [ "$LOG_FORMAT" ]; then
		LOG_FORMAT="log-format \"${LOG_FORMAT}\""
	else
		LOG_FORMAT="option httplog"
	fi
fi

cat <<EOF > /usr/local/etc/haproxy/haproxy.cfg

global
	maxconn ${MAX_CONNECTIONS:-2000}

defaults
	mode http
	timeout connect 5s
	timeout client 30s
	timeout server ${SERVER_TIMEOUT:-30s}
	timeout queue ${QUEUE_TIMEOUT:-5s}

frontend http
	bind *:${PORT:-8000}
	acl is_healthcheck path ${HEALTHCHECK_PATH:-/healthcheck}
	use_backend healthcheck if is_healthcheck
	default_backend app
	$LOG
	$LOG_FORMAT

backend app
	server main $1 maxconn $2

backend healthcheck
	server main $1

EOF

haproxy -f /usr/local/etc/haproxy/haproxy.cfg
