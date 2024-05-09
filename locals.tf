locals {
  network_id = var.network_params.network_id
  project = var.network_params.project
  postfix = var.network_params.postfix

  volume_exchange = var.volume_exchange
  host = "postgres-${var.network_params.postfix}"
  port = 5432
  user = "${var.network_params.project}${var.network_params.postfix}"
  password = random_string.password.result
  root_user = "r${var.network_params.project}${var.network_params.postfix}"
  root_password = random_string.root_password.result
  database = "${var.network_params.project}${var.network_params.postfix}"

  connection = "postgres://${local.root_user}:${local.root_password}@${local.host}:${local.port}/${local.database}?sslmode=disable"
}

locals {

  cmd = [
    "postgres",
    "-c", "fsync=off",
    "-c", "data_sync_retry=true",
  ]

  env = [
    "POSTGRES_USER=${local.root_user}",
    "POSTGRES_PASSWORD=${local.root_password}",
    "POSTGRES_DB=${local.database}",
    "PGDATA=/postgresql/data"
  ]

  init_sh = join("\n", [for d in var.databases : 
    "echo 'CREATE DATABASE ${d}; GRANT ALL PRIVILEGES ON DATABASE ${d} TO ${local.root_user};' | psql -v ON_ERROR_STOP=1 --dbname ${local.database} --username ${local.root_user}\n"
  ]) 

  upload = [{
    content = local.init_sh
    file = "/docker-entrypoint-initdb.d/db-init.sh"
  }]

  mounted_exchange = {
    source = local.volume_exchange
    target = "/exchange"
  }

  mounts = var.disabled > 0 || var.mounted == "" ? [] : [
    {
      source = var.mounted
      target = "/postgresql/data"
    }
  ]

  volumes = var.disabled > 0 || local.mounts != [] ? [] : [{
    container_path = "/postgresql/data"
    volume_name    = docker_volume.storage[0].name
  }]

  ports = var.open_ports ? [{
    internal = 5432
    external = 5432
  }] : []

  credentials = {for d in var.databases: 
    d => {
      database = d
      host     = local.host
      port     = local.port
      user     = local.user
      password = local.password
    }
  }


  labels = [
    { "label": "host", "value": local.host },
    { "label": "role", "value": "postgres" }    
  ]
}
