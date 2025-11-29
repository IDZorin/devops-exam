resource "yandex_container_registry" "reg" {
  name = var.registry_name
  labels = { project = "fastapi-serverless" }
}

resource "yandex_container_repository" "repo" {
  name = "${yandex_container_registry.reg.id}/${var.repository_name}"
}

resource "yandex_serverless_container" "api" {
  name      = var.container_name
  folder_id = var.yc_folder_id

  image {
    url = "cr.yandex/${yandex_container_registry.reg.id}/${var.repository_name}:${var.image_tag}"
    environment = {
      PORT = "8080"
    }
  }

  cores             = 1
  memory            = 256
  execution_timeout = "10s"
  concurrency       = 16

  service_account_id = yandex_iam_service_account.sa.id
}

resource "yandex_iam_service_account" "sa" {
  name      = "fastapi-sls-sa"
  folder_id = var.yc_folder_id
}

resource "yandex_serverless_container_iam_binding" "public" {
  container_id = yandex_serverless_container.api.id
  role         = "serverless.containers.invoker"
  members      = ["system:allUsers"]
}

resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = yandex_container_registry.reg.id
  role        = "container-registry.images.puller"

  members = [
    "serviceAccount:${yandex_iam_service_account.sa.id}",
  ]
}
