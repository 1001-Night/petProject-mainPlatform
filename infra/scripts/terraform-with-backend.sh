#!/usr/bin/env bash
set -euo pipefail

if (( $# < 2 )); then
  echo "Usage: $0 <main|bootstrap> <terraform arguments...>" >&2
  exit 2
fi

stack="$1"
shift

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd -- "$script_dir/../.." && pwd)"

case "$stack" in
  main)
    terraform_directory="$repository_root/infra/terraform"
    ;;
  bootstrap)
    terraform_directory="$repository_root/infra/terraform-bootstrap"
    ;;
  *)
    echo "Unknown stack: $stack" >&2
    exit 2
    ;;
esac

secret_name="mainplatform-tfstate-credentials"
bucket_name="mainplatform-tfstate-b1gc3jl7gdoihb7cvg74"

(
  export AWS_ACCESS_KEY_ID
  AWS_ACCESS_KEY_ID="$(
    yc lockbox payload get --name "$secret_name" --key access_key
  )"

  export AWS_SECRET_ACCESS_KEY
  AWS_SECRET_ACCESS_KEY="$(
    yc lockbox payload get --name "$secret_name" --key secret_key
  )"

  export TF_VAR_yc_token
  TF_VAR_yc_token="$(yc iam create-token)"

  if [[ "$1" == "init" ]]; then
    set -- "$@" "-backend-config=bucket=$bucket_name"
  fi

  terraform -chdir="$terraform_directory" "$@"
)
