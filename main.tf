provider "incapsula" {
  api_id = var.api_id
  api_key = var.api_key
}

locals {
  sites = csvdecode(file("${path.cwd}/sites.csv"))
}

module "sites" {
  source = "../modules/terraform-incapsula-sites"
  for_each = { for site in local.sites : site.local_id => site }
  domain = each.value.domain
  site_ip = each.value.site_ip
  account_id = 2398
  force_ssl = true
  ignore_ssl = true
}

module "security_rules" {
  depends_on = [module.sites]
  for_each = module.sites
  source = "../modules/terraform-incapsula-security-rules"
  site_id = module.sites[each.key].site_ids.id
}

module "associate_policies" {
  depends_on = [module.sites]
  for_each = module.sites
  source = "../modules/terraform-incapsula-policies-association"
  asset_id = module.sites[each.key].site_ids.id
  policy_id = module.policies.embargo_nation_block_id
}

module "dynamic_country_associate_policies" {
  depends_on = [module.sites]
  for_each = module.sites
  source = "../modules/terraform-incapsula-policies-association"
  asset_id = module.sites[each.key].site_ids.id
  policy_id = module.policies.dynamic_country_block_id
}

module "dynamic_ip_associate_policies" {
  depends_on = [module.sites]
  for_each = module.sites
  source = "../modules/terraform-incapsula-policies-association"
  asset_id = module.sites[each.key].site_ids.id
  policy_id = module.policies.dynamic_ip_block_id
}

module "policies" {
  source = "../modules/terraform-incapsula-policies"
  countries = ["CA", "JP", "JM"]
  ips = ["209.121.2.0/24", "3.3.3.3"]
}

module "nel_rules" {
  depends_on = [module.sites]
  for_each = module.sites
  source = "../modules/terraform-incapsula-rules"
  site_id = module.sites[each.key].site_ids.id
}

output "site-ids" {
  value = [for id in module.sites : id.site_ids[*].id]
}
