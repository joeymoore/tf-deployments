provider "incapsula" {
  api_id = var.api_id
  api_key = var.api_key
}

locals {
  sites = csvdecode(file("${path.cwd}/sites.csv"))
}

module "sites" {
  source  = "app.terraform.io/Imperva-OCTO/sites/incapsula"
  version = "0.0.1"
  for_each = { for site in local.sites : site.local_id => site }
  domain = each.value.domain
  site_ip = each.value.site_ip
  account_id = var.account_id
  force_ssl = true
  ignore_ssl = true
}

module "security_rules" {
  depends_on = [module.sites]
  for_each = module.sites
  source  = "app.terraform.io/Imperva-OCTO/security-rules/incapsula"
  version = "0.0.1"
  site_id = module.sites[each.key].site_ids.id
}

module "policies-association" {
  source  = "app.terraform.io/Imperva-OCTO/policies-association/incapsula"
  version = "0.0.1"
  depends_on = [module.sites]
  for_each = module.sites
  asset_id = module.sites[each.key].site_ids.id
  policy_id = module.policies.embargo_nation_block_id
}

module "dynamic_country_associate_policies" {
  source  = "app.terraform.io/Imperva-OCTO/policies-association/incapsula"
  version = "0.0.1"
  depends_on = [module.sites]
  for_each = module.sites
  asset_id = module.sites[each.key].site_ids.id
  policy_id = module.policies.dynamic_country_block_id
}

module "dynamic_ip_associate_policies" {
  source  = "app.terraform.io/Imperva-OCTO/policies-association/incapsula"
  version = "0.0.1"
  depends_on = [module.sites]
  for_each = module.sites
  asset_id = module.sites[each.key].site_ids.id
  policy_id = module.policies.dynamic_ip_block_id
}

module "policies" {
  source  = "app.terraform.io/Imperva-OCTO/policies/incapsula"
  version = "0.0.3"
  countries = var.countries
  ips = var.block_ips
}

module "nel_rules" {
  source  = "app.terraform.io/Imperva-OCTO/rules/incapsula"
  version = "0.0.1"
  depends_on = [module.sites]
  for_each = module.sites
  site_id = module.sites[each.key].site_ids.id
}

output "site-ids" {
  value = [for id in module.sites : id.site_ids[*].id]
}