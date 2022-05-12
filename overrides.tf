terraform {
  backend "remote" {
    organization = "Imperva-OCTO"
    workspaces {
      name = "amplify-deployment"
    }
  }
}