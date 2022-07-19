resource "kubernetes_pod" "example" {
  metadata {
    name      = "terraform-example"
    namespace = "default"
    labels = {
      test = "MyExampleApp"
    }
  }

  spec {
    automount_service_account_token = true
    security_context{
    }
    selector {
      match_labels = {
        test = "MyExampleApp"
      }
    }
  }
}
