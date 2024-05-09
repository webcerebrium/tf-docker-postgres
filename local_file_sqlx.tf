resource "local_file" "sqlx" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash

export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[[ $DB == "" ]] && {
    export DB="${local.database}"
}

export DATABASE_URL="postgres://${local.root_user}:${local.root_password}@${local.host}:${local.port}/$DB?sslmode=disable"
cd $DIR/../../../

[ ! -d "$(pwd)/migrations/postgres/$DB" ] && {
    echo "Folder does not exist: $(pwd)/migrations/postgres/$DB";
    exit 1
}

docker run --name sqlx-postgres-cli --network=${local.network_id} --rm -it \
    -v $(pwd)/migrations/postgres/$DB:/app/migrations \
    -w /app \
    -e DATABASE_URL=$DATABASE_URL \
    wcrbrm/sqlx-postgres $@


if [[ $1 == "migrate" ]]; then
  if [[ $2 == "add" ]]; then
 	sudo chown -R `whoami`:`whoami` $(pwd)/migrations/postgres/$DB
  fi
fi

EOF
   filename = "./bin/sqlx.sh"
   file_permission = "0777"
}

