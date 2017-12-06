source $(dirname $0)/common.sh

function configure_apache {
  if [ -z ${APACHE_OIDC_METADATA_URL+x} ]; then
    missing_var_exit "APACHE_OIDC_METADATA_URL"
  fi

  if [ -z ${APACHE_OIDC_CLIENT_ID+x} ]; then
    missing_var_exit "APACHE_OIDC_CLIENT_ID"
  fi

  if [ -z ${APACHE_OIDC_INTROSPECTION_ENDPOINT+x} ]; then
    missing_var_exit "APACHE_OIDC_INTROSPECTION_ENDPOINT"
  fi

  if [ -z ${APACHE_OIDC_REDIRECT_URI+x} ]; then
    missing_var_exit "APACHE_OIDC_REDIRECT_URI"
  fi

  if [ -z ${APACHE_OIDC_CLIENT_SECRET+x} ] && [ -z ${APACHE_OIDC_CLIENT_SECRET_FILE+x} ]; then
    missing_var_exit "APACHE_OIDC_CLIENT_SECRET_FILE"
  fi

  if [ ${APACHE_OIDC_CLIENT_SECRET_FILE+x} ]; then
    if [ ${APACHE_OIDC_CLIENT_SECRET+x} ]; then
      error_exit "Variables 'APACHE_OIDC_CLIENT_SECRET' and 'APACHE_OIDC_CLIENT_SECRET_FILE' cannot be set togather" 2
    fi

    export APACHE_OIDC_CLIENT_SECRET=$(cat ${APACHE_OIDC_CLIENT_SECRET_FILE})
  fi

  if [ -z ${APACHE_OIDC_CRYPTO_PASSPHRASE+x} ] && [ -z ${APACHE_OIDC_CRYPTO_PASSPHRASE_FILE+x} ]; then
    missing_var_exit "APACHE_OIDC_CRYPTO_PASSPHRASE_FILE"
  fi

  if [ ${APACHE_OIDC_CRYPTO_PASSPHRASE_FILE+x} ]; then
    if [ ${APACHE_OIDC_CRYPTO_PASSPHRASE+x} ]; then
      error_exit "Variables 'APACHE_OIDC_CRYPTO_PASSPHRASE' and 'APACHE_OIDC_CRYPTO_PASSPHRASE_FILE' cannot be set togather" 2
    fi

    export APACHE_OIDC_CRYPTO_PASSPHRASE=$(cat ${APACHE_OIDC_CRYPTO_PASSPHRASE_FILE})
  fi

  export APACHE_HOST="${APACHE_HOST:-*}"
  export APACHE_PORT="${APACHE_PORT:-5000}"
  export APACHE_SSL_CERT="${APACHE_SSL_CERT:-/etc/ssl/certs/ssl-cert-snakeoil.pem}"
  export APACHE_SSL_KEY="${APACHE_SSL_KEY:-/etc/ssl/private/ssl-cert-snakeoil.key}"
  export APACHE_SSL_CA="${APACHE_SSL_CA:-/etc/grid-security/certificates}"
  export APACHE_SSL_CRL="${APACHE_SSL_CRL:-/etc/grid-security/certificates}"
  export APACHE_LOG_LEVEL="${APACHE_LOG_LEVEL:-info}"
  export APACHE_LOG_ACCESS="${APACHE_LOG_ACCESS:-/var/log/apache-keystorm/access.log}"
  export APACHE_LOG_ERROR="${APACHE_LOG_ERROR:-/var/log/apache-keystorm/error.log}"
  export APACHE_SERVER_NAME="${APACHE_SERVER_NAME:-localhost}"
  export APACHE_IDENTITY_PROVIDER="${APACHE_IDENTITY_PROVIDER:-egi.eu}"
  export APACHE_PROXY="${APACHE_PROXY:-http://127.0.0.1:3000}"

  envsubst < /keystorm/config/keystorm.apache > /etc/apache2/sites-available/keystorm.conf
  if [ ${DEBUG} == "1" ]; then
    cat /etc/apache2/sites-available/keystorm.conf
  fi

  sed -i "s/#export APACHE_ARGUMENTS=''/export APACHE_ARGUMENTS='-DFOREGROUND'/g" /etc/apache2/envvars
  sed -i -r "s/Listen\s+443/Listen ${APACHE_PORT}/g" /etc/apache2/ports.conf
  sed -i -r "/Listen\s+80/d" /etc/apache2/ports.conf

  a2ensite keystorm
}

function run_apache {
  apache2ctl start
}
