#!/bin/sh

defaults() {
    : ${DEVPISERVER_SERVERDIR="/data/server"}
    : ${DEVPI_CLIENTDIR="/data/client"}
    : ${DEVPI_HOST="0.0.0.0"}
    : ${DEVPI_PORT=3141}

    export DEVPISERVER_SERVERDIR \
        DEVPI_CLIENTDIR \
        DEVPI_HOST \
        DEVPI_PORT
}

DEVPI_LISTEN_HOST="0.0.0.0"
CLIENT_INSTALLED="false"
KEEP_CLIENT="false"


print(){
    echo "$@" >&2
}

usage(){
    cat <<EOF

Container Usage:
    
    docker run -it --rm \\
        -v "\$PWD/data":/data \\ # for persistance on the host
        -e DEVPI_PASSWORD=password \\ # set password for devpi root user
        -e DEVPI_PORT=3143 \\ # use custom port (default 3141)
        -p "80:3143" \\ # host_port:container_port
        mhoush/devpi-server [options...] [args...]

    Options:
        
        -w | --web:         Enable devpi-web interface
        -c | --client:      Enable devpi-client
        -h | --help:        Show this page and devpi-server help page

    Args:

        Get passed to devpi-server command.

    Environment Variable Settings:

        DEVPI_PASSWORD:         Password for the root devpi user (default '')
        DEVPI_PORT:             Port the server listens on. (default 3141)
        DEVPISERVER_SERVERDIR:  Directory to store server information to. (default /data)
        DEVPI_CLIENTDIR:        Directory to store client information to. (default /data)

Devpi-Server Usage:
EOF
}

initialize() {
    if [[ "$CLIENT_INSTALLED" == "false" ]]; then
        print ""
        print "=> Installing devpi-client to initialize server"
        pip install -q --no-cache-dir --ignore-installed \
            devpi-client
    fi

    print ""
    print "=> Initializing devpi-server"
    devpi-server --restrict-modify root --start --host "$DEVPI_LISTEN_HOST" --port "$DEVPI_PORT" --init $@
    devpi-server --status --host "$DEVPI_LISTEN_HOST" --port "$DEVPI_PORT" $@
    devpi use "http://$DEVPI_HOST:$DEVPI_PORT"
    devpi login root --password=''
    devpi user -m root password="${DEVPI_PASSWORD}"
    devpi logoff
    devpi-server --stop --host "$DEVPI_LISTEN_HOST" --port "$DEVPI_PORT" $@
    devpi-server --status --host "$DEVPI_LISTEN_HOST" --port "$DEVPI_PORT" $@
    
    if [[ "$KEEP_CLIENT" == "false" ]]; then
        print ""
        print "=> We are done with devpi-client when prompted hit [y] to uninstall"
        print -n "Uninstall devpi-client (Y/n)?"
        read -t 3 answer
        case $answer in
            n* | N* )
                ;;
            * )
                echo y | pip uninstall -q devpi-client;
                echo ""
                ;;
        esac
    fi
}

start_devpi_server() {
    if ! [[ -f "$DEVPISERVER_SERVERDIR/.serverversion" ]]; then
        initialize $@
    fi
    print ""
    print "=> Starting server..."
    if [ $# -gt 0 ]; then
        exec devpi-server --restrict-modify root --host "$DEVPI_LISTEN_HOST" --port "$DEVPI_PORT" $@
    else
        exec devpi-server --restrict-modify root --host "$DEVPI_LISTEN_HOST" --port "$DEVPI_PORT"
    fi
}

main() {
    
    # set-up defaults
    defaults

    if [[ "$1" == "" ]]; then
        # start a server without any args/commands
        start_devpi_server
    elif [[ "$1" == "sh" ]]; then
        print "=> Running non-devpi commands: $@"
        exec "$@"
    else
        if [[ "$1" == "devpi" ]]; then
            shift
        fi

        args=""
        while [[ "$1" != "" ]]; do
            case $1 in

                -w | --web )
                    print ""
                    print "=> Installing devpi-web..."
                    pip install --no-cache-dir devpi-web
                    ;;
                -c | --client )
                    print ""
                    print "=> Installing devpi-client..."
                    pip install --no-cache-dir devpi-client
                    CLIENT_INSTALLED="true"
                    KEEP_CLIENT="true"
                    ;;
                -h | --help )
                    print ""
                    print "$(usage)"
                    print ""
                    exec devpi-server --help
                    ;;
                *)
                    if [[ "$args" != "" ]]; then
                        args="$args $1"
                    else
                        args="$1"
                    fi
                    ;;
            esac
            shift
        done

        start_devpi_server $args
    fi
}

main "$@"
