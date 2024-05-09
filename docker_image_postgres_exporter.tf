resource "docker_image" "postgres_exporter" {
  name = "quay.io/prometheuscommunity/postgres-exporter"
  count = var.enable_metrics ? 1 : 0
  keep_locally = true
}
