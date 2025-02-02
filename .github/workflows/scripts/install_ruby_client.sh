#!/bin/bash

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by it. Please use
# './plugin-template --github pulp_ansible' to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

set -euv

# make sure this script runs at the repo root
cd "$(dirname "$(realpath -e "$0")")"/../../..

export PULP_URL="${PULP_URL:-https://pulp}"

export REPORTED_VERSION=$(http $PULP_URL/pulp/api/v3/status/ | jq --arg plugin ansible --arg legacy_plugin pulp_ansible -r '.versions[] | select(.component == $plugin or .component == $legacy_plugin) | .version')
export DESCRIPTION="$(git describe --all --exact-match `git rev-parse HEAD`)"
if [[ $DESCRIPTION == 'tags/'$REPORTED_VERSION ]]; then
  export VERSION=${REPORTED_VERSION}
else
  export EPOCH="$(date +%s)"
  export VERSION=${REPORTED_VERSION}${EPOCH}
fi

export response=$(curl --write-out %{http_code} --silent --output /dev/null https://rubygems.org/gems/pulp_ansible_client/versions/$VERSION)

if [ "$response" == "200" ];
then
  echo "pulp_ansible client $VERSION has already been released. Installing from RubyGems.org."
  gem install pulp_ansible_client -v $VERSION
  touch pulp_ansible_client-$VERSION.gem
  tar cvf ruby-client.tar ./pulp_ansible_client-$VERSION.gem
  exit
fi

cd ../pulp-openapi-generator
rm -rf pulp_ansible-client
./generate.sh pulp_ansible ruby $VERSION
cd pulp_ansible-client
gem build pulp_ansible_client
gem install --both ./pulp_ansible_client-$VERSION.gem
tar cvf ../../pulp_ansible/ruby-client.tar ./pulp_ansible_client-$VERSION.gem
