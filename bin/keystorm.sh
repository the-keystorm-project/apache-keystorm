#!/bin/bash

# End on any non-zero return code
set -e

if [ "${DEBUG}" == "1" ]; then
  set -x
fi

source $(dirname $0)/apache.sh
source $(dirname $0)/voms.sh

configure_apache
generate_voms_configuration
run_apache
