#! /bin/sh

vault login -method=userpass -no-store -token-only username=test-service password=changeme > test-service.vault.token
VAULT_TOKEN=$(cat test-service.vault.token) vault read -field=token identity/oidc/token/role > vault.jwt.token

consul login -method=vault -token-sink-file=consul.service.token -bearer-token-file=vault.jwt.token

CONSUL_HTTP_TOKEN=$(cat consul.service.token) consul services register -name=something-else
CONSUL_HTTP_TOKEN=$(cat consul.service.token) consul services register -name=test-service  -tag=cost-code=A123
