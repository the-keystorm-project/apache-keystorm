source $(dirname $0)/common.sh

function generate_voms_configuration {
  if [ -z ${VOMS_CONFIGURATION+x} ]; then
    missing_var_exit "VOMS_CONFIGURATION"
  fi

  vomsdir="/etc/grid-security/vomsdir"
  jq_args="-r -e"
  jq="jq ${jq_args}"

  voms_file=$(mktemp "${TMPDIR:-/tmp/}keystorm.XXXX")
  echo "${VOMS_CONFIGURATION}" > "${voms_file}"

  voms=$(${jq} ".vos | length" ${voms_file})
  for i in $(seq 0 $((--voms))); do
    vo_name=$(${jq} ".vos[${i}].name" ${voms_file})
    mkdir -p ${vomsdir}/${vo_name}

    endpoints=$(${jq} ".vos[${i}].endpoints | length" ${voms_file})
    for j in $(seq 0 $((--endpoints))); do
      endpoint_name=$(${jq} ".vos[${i}].endpoints[${j}].name" ${voms_file})
      endpoint_file="${vomsdir}/${vo_name}/${endpoint_name}.lsc"
      touch ${endpoint_file}

      dns=$(${jq} ".vos[${i}].endpoints[${j}].dns | length" ${voms_file})
      for k in $(seq 0 $((--dns))); do
        dn=$(${jq} ".vos[${i}].endpoints[${j}].dns[${k}]" ${voms_file})
        echo ${dn} >> "${endpoint_file}"
      done
    done
  done

  rm ${voms_file}
}
