resource "local_file" "download" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash
set -ex

export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export DIR_EXCHANGE=${local.volume_exchange}

export PID=$(docker ps --filter "label=host=${local.host}" --format "{{.ID}}")
if [[ "$PID" != "" ]]; then

    if [[ "$LAST_SQL" == "" ]]; then
        export SSH_HOST=$(curl -s https://stat.karta.com/hosts/ | grep dev.internal.karta.com | cut -f1 -d' ')
        export REMOTE_PATH=$(ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null karta@$SSH_HOST 'find /data/exchange/ -type f -name *.sql.gz | sort | tail -n1')
        export LAST_SQL_GZ=$(echo $REMOTE_PATH | rev | cut -d'/' -f1 | rev)
        scp -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null karta@$SSH_HOST:$REMOTE_PATH $DIR_EXCHANGE/$LAST_SQL_GZ
        export LAST_SQL=$(echo $LAST_SQL_GZ | sed -r 's/\.gz$//')
        cd $DIR_EXCHANGE
        if [ -f "$DIR_EXCHANGE/$LAST_SQL_GZ" ]; then
            gunzip -k -f $LAST_SQL_GZ
        fi
    fi

    if [[ -z "$DIR_EXCHANGE/$LAST_SQL" ]]; then
        echo "ERROR: Last SQL file $DIR_EXCHANGE/$LAST_SQL was not found"
        exit 1
    fi

    cd $DIR_EXCHANGE
    cat $LAST_SQL | docker exec -i $PID psql -U ${local.root_user} -d ${local.database} -h 127.0.0.1
    
    echo "Postgres dump installed successfully"
else 
   echo "ERROR: postgres docker process was not found"
   exit 1
fi
EOF
   filename = "./bin/postgres-download.sh"
   file_permission = "0777"
}

