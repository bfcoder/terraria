#!/bin/bash
# Starts the Terraria server with stdin fed from a FIFO so the server runs
# without a TTY, commands can be injected with `terraria-cmd`, and SIGTERM
# (docker stop) saves the world before exiting.
set -euo pipefail

DATA_DIR=/data
WORLD_DIR="$DATA_DIR/worlds"
CONFIG="$DATA_DIR/serverconfig.txt"
FIFO=/tmp/terraria.stdin

mkdir -p "$WORLD_DIR"

# Generate a config from env vars unless the user supplied their own.
if [ ! -f "$CONFIG" ] || [ "${REGENERATE_CONFIG:-0}" = "1" ]; then
    echo "Generating $CONFIG from environment"
    {
        echo "world=$WORLD_DIR/$WORLD_NAME.wld"
        echo "worldpath=$WORLD_DIR"
        echo "worldname=$WORLD_NAME"
        echo "autocreate=$WORLD_SIZE"
        echo "difficulty=$DIFFICULTY"
        echo "maxplayers=$MAX_PLAYERS"
        echo "port=$PORT"
        echo "secure=$SECURE"
        echo "language=$LANGUAGE"
        echo "npcstream=$NPC_STREAM"
        echo "priority=$PRIORITY"
        echo "upnp=$UPNP"
        echo "banlist=$DATA_DIR/banlist.txt"
        [ -n "$PASSWORD" ] && echo "password=$PASSWORD"
        [ -n "$MOTD" ] && echo "motd=$MOTD"
        [ -n "$SEED" ] && echo "seed=$SEED"
    } > "$CONFIG"
fi

rm -f "$FIFO"
mkfifo "$FIFO"

# Keep the FIFO open for writing so the server never sees EOF on stdin.
exec 3<>"$FIFO"

cd /opt/terraria
./TerrariaServer.bin.x86_64 -config "$CONFIG" "$@" < "$FIFO" &
SERVER_PID=$!

shutdown() {
    echo "Received stop signal, saving world and shutting down..."
    echo "exit" > "$FIFO"
    wait "$SERVER_PID" || true
    exit 0
}
trap shutdown SIGTERM SIGINT

wait "$SERVER_PID"
