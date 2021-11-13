locals {
  gke_config_decoded = yamldecode(file(var.config_file))

  gke_config_properties = flatten([
    for gke_purpose, gke_props in local.gke_config_decoded : [
      {
        name = gke_props["name"]
        min_master_version = gke_props["min_master_version"]
        location = gke_props["location"]
        vpc_self_link = gke_props["vpc_self_link"]
        subnetwork_self_link = gke_props["subnetwork_self_link"]
        node_locations = gke_props["node_locations"]
        enable_client_certificate_authorization = lookup(gke_props, "enable_client_certificate_authorization", "false")
        service_account_email = gke_props["common_node_pool_config"]["service_account_email"]
        network_policy_enabled = lookup(lookup(gke_props, "network_policy", {}), "enabled", "false")
        network_policy_provider = lookup(lookup(gke_props, "network_policy", {}), "provider", "CALICO")
        enable_binary_authorization = lookup(gke_props, "enable_binary_authorization", "false")
        pod_security_policy_enabled = lookup(gke_props, "pod_security_policy_enabled", "false" )
      }
  ]
  ])

  node_pools_config_properties = flatten([
    for gke_purpose, gke_props in local.gke_config_decoded : [
      for node_pool_props in lookup(gke_props, "node_pool_configurations_list", []) : [
        {
          cluster_name = gke_props["name"]
          name = node_pool_props["name"]
          location = gke_props["location"]
          initial_node_count = node_pool_props["initial_node_count"]
          service_account_email = lookup(node_pool_props, "service_account_email", gke_props["common_node_pool_config"]["service_account_email"])
          machine_type = node_pool_props["machine_type"]
        }
  ]
  ]
  ])
}