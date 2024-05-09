resource "docker_image" "postgres" {
  name = "postgis/postgis:16-3.4-alpine"
  count = var.disabled > 0 ? 0 : 1
  keep_locally = true
}
