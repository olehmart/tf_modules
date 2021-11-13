resource "google_container_cluster" "gke_cluster" {
  for_each = {
    for gke in local.gke_config_properties:
        join(":", [
          gke.location,
          gke.name,
          ]
        ) => gke
  }
  provider = google-beta
  name     = each.value.name
  location = each.value.location
  project  = var.project_id
  min_master_version = each.value.min_master_version
  network = each.value.vpc_self_link
  subnetwork = each.value.subnetwork_self_link
  node_locations = each.value.node_locations

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    service_account = each.value.service_account_email
  }

  master_auth {
    //username = ""
    //password = ""

    client_certificate_config {
      issue_client_certificate = each.value.enable_client_certificate_authorization
    }
  }

  enable_binary_authorization = each.value.enable_binary_authorization

  pod_security_policy_config {
    enabled = each.value.pod_security_policy_enabled
  }

  network_policy {
    enabled = each.value.network_policy_enabled
    provider = each.value.network_policy_provider
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  depends_on = [google_container_cluster.gke_cluster]
  for_each = {
    for node_pool in local.node_pools_config_properties:
        join(":", [
          node_pool.cluster_name,
          node_pool.location,
          node_pool.name,
          ]
        ) => node_pool
  }
  project = var.project_id
  provider = google-beta
  name       = each.value.name
  location   = each.value.location
  cluster    = each.value.cluster_name
  node_count = each.value.initial_node_count

  node_config {
    preemptible  = false
    machine_type = each.value.machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = each.value.service_account_email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}