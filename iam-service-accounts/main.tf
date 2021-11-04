resource "google_service_account" "service_account" {
  for_each = toset(local.sa_names)
  project = var.project_id
  account_id = each.value
  display_name = each.value
}

resource "time_sleep" "wait_service_accounts" {
  depends_on = [google_service_account.service_account]
  create_duration = var.sleep_after_sa_creation
}

resource "google_project_iam_member" "project_iam_binding" {
  for_each = {
    for pr_role in local.sa_config_project_roles :
    join(":", [
      pr_role.sa_name,
      pr_role.region,
      replace(pr_role.role_name, "/", "_")
    ]
   ) = > pr_role
  }
  depends_on = [
    google_service_account.service_account,
    time_sleep.wait_service_accounts
  ]
  project = var.project_id
  member = "serviceAccount:${each.value.sa_email}"
  role   = each.value.role_name
}

resource "google_service_account_iam_binding" "sa_iam_binding" {
  for_each = {
    for pr_role in local.sa_config_project_roles :
    join(":", [
      pr_role.sa_name,
      pr_role.region,
      replace(pr_role.role_name, "/", "_")
    ]
   ) = > pr_role
  }
  service_account_id = join("/", [
    "projects",
    var.project_id,
    "serviceAccounts",
    each.value.sa_email
    ]
  )
  role               = each.value.role_name
  members            = each.value.members
  depends_on = [
    google_service_account.service_account,
    time_sleep.wait_service_accounts
  ]
}