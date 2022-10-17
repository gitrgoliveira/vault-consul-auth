#! /bin/sh
vault server -dev -dev-root-token-id=root >vault.log 2>&1 &
consul agent -server -dev -auto-reload-config  -config-file=consul_config.hcl >consul.log 2>&1 &

sleep 5

consul acl bootstrap -format=json > consul.token.json
