LAST_DIR="$(pwd -P)"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P)"
psql -U protwis -h localhost -o /dev/null protwis < "$DIR/prepare.sql" 2>/dev/null
cd "$LAST_DIR"
