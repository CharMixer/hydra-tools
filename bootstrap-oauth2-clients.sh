#!/bin/sh

IDPBE_SECRET=$(./create_hydra_client.sh -i idp-be -n identity-provider-backend -s hydra -g client_credentials -t token -a hydra -u -h "https://127.0.0.1:4445/clients")
IDPFE_SECRET=$(./create_hydra_client.sh -i idp-fe -n identity-provider-frontend -s idpbe.authenticate -s openid -g authorization_code -g client_credentials -a idpbe -t code -t token -r "https://dev-larn.fullrate.dk:8081/callback" -u -h "https://127.0.0.1:4445/clients")
CPBE_SECRET=$(./create_hydra_client.sh -i cp-be -n consent-provider-backend -s hydra -g client_credentials -t token -a hydra -u -h "https://127.0.0.1:4445/clients")
CPFE_SECRET=$(./create_hydra_client.sh -i cp-fe -n consent-provider-frontend -s cpbe.authorize -s openid -g client_credentials -a cpbe -t token -t code -u -h "https://127.0.0.1:4445/clients")

SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
echo "IDP_BACKEND_OAUTH2_CLIENT_ID=idp-be" > env/idpbe_secrets.env
echo "IDP_BACKEND_OAUTH2_CLIENT_SECRET=$IDPBE_SECRET" >> env/idpbe_secrets.env
echo "IDP_BACKEND_CSRF_AUTH_KEY=$SECRET" >> env/idpbe_secrets.env

SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
echo "IDP_FRONTEND_OAUTH2_CLIENT_ID=idp-fe" > env/idpfe_secrets.env
echo "IDP_FRONTEND_OAUTH2_CLIENT_SECRET=$IDPFE_SECRET" >> env/idpfe_secrets.env
echo "IDP_FRONTEND_CSRF_AUTH_KEY=$SECRET" >> env/idpfe_secrets.env
SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
echo "IDP_FRONTEND_SESSION_AUTH_KEY=$SECRET" >> env/idpfe_secrets.env

SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
echo "CP_BACKEND_OAUTH2_CLIENT_ID=cp-be" > env/cpbe_secrets.env
echo "CP_BACKEND_OAUTH2_CLIENT_SECRET=$CPBE_SECRET" >> env/cpbe_secrets.env
echo "CP_BACKEND_CSRF_AUTH_KEY=$SECRET" >> env/cpbe_secrets.env

SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
echo "CP_FRONTEND_OAUTH2_CLIENT_ID=cp-fe" > env/cpfe_secrets.env
echo "CP_FRONTEND_OAUTH2_CLIENT_SECRET=$CPFE_SECRET" >> env/cpfe_secrets.env
echo "CP_FRONTEND_CSRF_AUTH_KEY=$SECRET" >> env/cpfe_secrets.env
SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
echo "CP_FRONTEND_SESSION_AUTH_KEY=$SECRET" >> env/cpfe_secrets.env
