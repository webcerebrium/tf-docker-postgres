resource "local_file" "shell" {
   count = var.disabled > 0 ? 0 : 1
   content = <<EOF
#!/usr/bin/env bash
set -x
docker exec -it ${local.host} bash -c 'psql -U $POSTGRES_USER -h 127.0.0.1 -d $POSTGRES_DB'
EOF
   filename = "./bin/postgres-shell.sh"
   file_permission = "0777"
}

