locals {
  sa_config = yamldecode(file(var.config_file))
  sa_email_suffix = "${var.project_id}.iam.gserviceaccount.com"
  sa_names = [for sa_purpose, sa_props in local.sa_config : sa_props["name"]]
  sa_config_project_roles = flatten([
    for sa_purpose_sa_props in local.sa_config: [
      for role_name in sa_props["project_roles"] : {
        sa_name = sa_props["name"]
        role_name = role_name
        sa_email = join("@", [sa_props["name"], local.sa_email_suffix])
        region = sa_props["region"]
  }
  ]
  ])
  sa_config_iam_roles = flatten([
    for sa_purpose, sa_props in local.sa_config :
          concat(
            [
              for role_name, members in sa_props["iam_roles"] : {
                sa_name = sa_props["name"]
                role_name = role_name
                sa_email = join("@", [sa_props["name"], local.sa_email_suffix])
                region = sa_props["region"]
                members = [
                  for member in members: length(regexall(".*[@[/:{~!].*", member)) > 0 ? join(":", ["serviceAccount", member]) : join("@", [
                    member == "SELF" ? join(":", ["serviceAccount", sa_props["name"]]) : join(":", ["serviceAccount", member]),
                    local.sa_email_suffix
                ])
              ]
            }
            ],
            [{
              sa_name = sa_props["name"]
              role_name = "roles/iam.serviceAccountKeyAdmin"
              sa_email = join("@", [sa_props["name"], local.sa_email_suffix])
              region = join("-",[sa_props["region"], "default"])
              members = [join(":", ["serviceAccount", var.tf_service_account])]
            }]
          )
  ])
}