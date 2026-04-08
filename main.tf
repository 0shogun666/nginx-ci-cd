provider "kubernetes" {
  config_path = "~/.kube/config"
}

 resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name = "nginx"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "test-nginx:1.5"
	  image_pull_policy = "Never"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name = "nginx-service"
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "nginx" {
  metadata {
    name = "nginx-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "nginx.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  set = [
    {
      name  = "grafana.service.type"
      value = "NodePort"
    },
    {
      name  = "grafana.datasources.datasources\\.yaml.apiVersion"
      value = "1"
    },
    {
      name  = "grafana.datasources.datasources\\.yaml.datasources[0].name"
      value = "Prometheus"
    },
    {
      name  = "grafana.datasources.datasources\\.yaml.datasources[0].type"
      value = "prometheus"
    },
    {
      name  = "grafana.datasources.datasources\\.yaml.datasources[0].access"
      value = "proxy"
    },
    {
      name  = "grafana.datasources.datasources\\.yaml.datasources[0].url"
      value = "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
    },
    {
      name  = "grafana.datasources.datasources\\.yaml.datasources[0].isDefault"
      value = "false"
    },

    # SMTP nastavení
    {
      name  = "grafana.smtp.enabled"
      value = "true"
    },
    {
      name  = "grafana.smtp.host"
      value = "smtp.gmail.com:587"
    },
    {
      name  = "grafana.smtp.user"
      value = "<tvůj_email>@gmail.com"
    },
    {
      name  = "grafana.smtp.password"
      value = "<app_password_z_gmailu>"
    },
    {
      name  = "grafana.smtp.fromAddress"
      value = "<tvůj_email>@gmail.com"
    },
    {
      name  = "grafana.smtp.fromName"
      value = "Grafana Alerts"
    },
    {
      name  = "grafana.smtp.skipVerify"
      value = "false"
    }
  ]
}
