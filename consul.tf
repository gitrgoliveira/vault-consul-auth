locals {
  # get json 
  consul_token = jsondecode(file("${path.module}/consul.token.json"))
}
provider "consul" {
  token = local.consul_token.SecretID
}

resource "consul_acl_auth_method" "vault_jwt" {
  name = "vault"
  type = "jwt"

  config_json = jsonencode({
    JWKSURL          = "${var.vault_hostname}/v1/identity/oidc/.well-known/keys"
    JWTSupportedAlgs = "RS256"
    BoundIssuer      = "${var.vault_hostname}/v1/identity/oidc"
    BoundAudiences   = ["consul.example.com"]
    ClaimMappings = {
      "entity_name" : "entity_name",
      "alias_name" : "alias_name",
      "cost-code" : "cost-code",
    }
  })
}

resource "consul_acl_binding_rule" "binding" {
  auth_method = consul_acl_auth_method.vault_jwt.name
  bind_type   = "service"
  bind_name   = "$${value.alias_name}"
}