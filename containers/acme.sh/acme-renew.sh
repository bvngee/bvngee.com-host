#!/bin/sh
# Only for use within this acme.sh docker container!

cd /acme.sh || exit

echo "INFO: Requesting SSL certificates!"

## ISSUE CERTIFICATES
# Notes: 
# --set-default-ca is only useful when debugging (manually calling acme.sh)
# -dns dns_cf tells acme.sh to use the dnsapi mode with cloudflare's api (bvngee.com use cloudflare for nameserver).
# ^ this depends on the CF_Token and CF_Account_ID env vars being set
./acme.sh --set-default-ca --server letsencrypt --issue --dns dns_cf \
    -d 'bvngee.com' \
    -d '*.bvngee.com' \

# we're using webroot mode to get a certificate for this fs subdomain only
./acme.sh --set-default-ca --server letsencrypt --issue \
    -d 'telemetry.formulaslug.com' \
    -d 'graf.telemetry.formulaslug.com' \
    -d 'clickhouse.telemetry.formulaslug.com' \
    -w /website-static


## INSTALL CERTIFICATES
# This just places the previously attained cert files into the docker volume
./acme.sh --install-cert \
    -d 'bvngee.com' \
    -d '*.bvngee.com' \
    --key-file /acme.sh-certs/key.pem \
    --fullchain-file /acme.sh-certs/fullchain.pem \

./acme.sh --install-cert \
    -d 'telemetry.formulaslug.com' \
    -d 'graf.telemetry.formulaslug.com' \
    -d 'clickhouse.telemetry.formulaslug.com' \
    --key-file /acme.sh-certs/key-telem.pem \
    --fullchain-file /acme.sh-certs/fullchain-telem.pem \

echo "INFO: Finished renewing SSL certificates!"

cd /
