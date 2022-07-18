resource "kubernetes_job" "example" {
  metadata {
    name      = "terraform-example"
    namespace = "something"
    labels = {
      test = "MyExampleApp"
    }
  }

  spec {
    automount_service_account_token = true
    selector {
      match_labels = {
        test = "MyExampleApp"
      }
    }
  }
}
