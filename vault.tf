variable "vault_hostname" {
  default = "http://127.0.0.1:8200"
}
provider "vault" {
  address = var.vault_hostname
  token   = "root"
}


resource "vault_identity_oidc" "server" {
  issuer = var.vault_hostname
}

resource "vault_identity_oidc_key" "key" {
  name      = "consul-key"
  algorithm = "RS256"
}

resource "vault_identity_oidc_role" "role" {
  name = "role"
  key  = vault_identity_oidc_key.key.name
  // setting up the audience
  client_id = "consul.example.com"
  // other template fields
  template = <<EOF
{
  "nbf": {{time.now}},
  "entity_name": {{identity.entity.name}},
  "cost-code": {{identity.entity.metadata.cost-code}},
  "alias_name": {{identity.entity.aliases.${vault_auth_backend.userpass.accessor}.name}},
  "alias_id": {{identity.entity.aliases.${vault_auth_backend.userpass.accessor}.id}}
}
EOF
}

resource "vault_identity_oidc_key_allowed_client_id" "role" {
  key_name          = vault_identity_oidc_key.key.name
  allowed_client_id = vault_identity_oidc_role.role.client_id
}


// create identiy
resource "vault_identity_entity" "example" {
  name = "test-service-entity"
  metadata = {
    "cost-code" = "A123"
  }

}


// setup user and policy access

resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_policy" "jwt-role-policy" {
  name   = "jwt-role-policy"
  policy = <<EOF
  path "identity/oidc/token/role"
{
  capabilities = ["read"]
}
EOF
}

resource "vault_generic_endpoint" "student" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/test-service"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["jwt-role-policy"],
  "password": "changeme"
}
EOT
}

resource "vault_identity_entity_alias" "test" {
  name           = "test-service"
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.example.id
}