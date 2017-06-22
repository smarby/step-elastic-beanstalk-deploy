#!/bin/bash
set +e

cd $HOME
if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_APP_NAME" ]
then
    fail "Missing or empty option APP_NAME, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME" ]
then
    fail "Missing or empty option ENV_NAME, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY" ]
then
    fail "Missing or empty option KEY, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET" ]
then
    fail "Missing or empty option SECRET, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION" ]
then
    warn "Missing or empty option REGION, defaulting to us-west-2"
    WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION="us-west-2"
fi

if [ -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_DEBUG" ]
then
    warn "Debug mode turned on, this can dump potentially dangerous information to log files."
fi

echo 'Synchronizing References in apt-get...'
sudo apt-get update

echo 'Installing pip...'
sudo apt-get install -y python-pip libpython-all-dev

echo 'Installing awscli...'
sudo pip install awsebcli

echo 'eb version show...'
eb --version

mkdir -p "$HOME/.aws"
mkdir -p "$WERCKER_SOURCE_DIR/.elasticbeanstalk/"
if [ $? -ne "0" ]
then
    fail "Unable to make directory.";
fi

debug "Change back to the source dir.";
cd $WERCKER_SOURCE_DIR

AWSEB_EB_CONFIG_FILE="$WERCKER_SOURCE_DIR/.elasticbeanstalk/config.yml"

debug "Setting up eb config..."

cat <<EOF >> $AWSEB_EB_CONFIG_FILE
branch-defaults:
  default:
    environment: $WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME
  $WERCKER_GIT_BRANCH:
    environment: $WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME
global:
  application_name: $WERCKER_ELASTIC_BEANSTALK_DEPLOY_APP_NAME
  default_platform: 64bit Amazon Linux 2014.03 v1.0.0 running Ruby 2.1 (Puma)
  default_region: $WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION
  profile: null
  sc: git
EOF

if [ -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_DEBUG" ]
then
    debug "Dumping config file."
    cat $AWSEB_EB_CONFIG_FILE
fi

eb use $WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME || fail "EB is not working or is not set up correctly."

debug "Checking if eb exists and can connect."
eb status
if [ $? -ne "0" ]
then
    fail "EB is not working or is not set up correctly."
fi

debug "Pushing to AWS eb servers."

set -e

eb deploy --timeout 25

success 'Successfully pushed to Amazon Elastic Beanstalk'
