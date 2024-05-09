resource "local_file" "crontab_postgres" {
  content = var.network_params.env == "local" ? "" : <<EOF
PATH=/usr/bin:/bin:/usr/local/bin
0 3 * * * karta bash ${path.cwd}/bin/postgres-backup.sh >> /var/log/postgres-backup.log 2>&1
EOF

  filename = "./cron.d/crontab_postgres"
  file_permission = "0777"
}
