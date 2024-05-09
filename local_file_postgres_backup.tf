resource "local_file" "backup" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash
set -ex

now() {
    date +"%Y%m%dT%H%M%S"
}

export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export DIR_EXCHANGE=${local.volume_exchange}

export PID=$(docker ps --filter "label=host=${local.host}" --format "{{.ID}}")
if [[ "$PID" != "" ]]; then
    
    export LAST_SQL=${local.project}-${local.database}-`now`.sql
    export LAST_SQL_GZ=$LAST_SQL.gz
    echo "Starting Postgres backup $LAST_SQL_GZ"
    docker exec -i $PID pg_dump --no-owner --clean -U ${local.root_user} -h 127.0.0.1 ${local.database} | gzip > $DIR_EXCHANGE/$LAST_SQL_GZ
    
    ${var.network_params.env != "dev" ? "" : "rsync -arvc -e \"ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null\" $DIR_EXCHANGE/$LAST_SQL_GZ backup-dev@storage.karta.com:/home/backup-dev/" } 
    ${var.network_params.env != "prod" ? "" : "rsync -arvc -e \"ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null\" $DIR_EXCHANGE/$LAST_SQL_GZ backup-prod@storage.karta.com:/home/backup-prod/" }  
    
    ${var.network_params.env != "dev" && var.network_params.env != "prod" ? "" : "rm -f $DIR_EXCHANGE/$LAST_SQL_GZ" }
   

else 
   echo "ERROR: postgres docker process was not found"
   exit 1
fi
EOF
   filename = "./bin/postgres-backup.sh"
   file_permission = "0777"
}

