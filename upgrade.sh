#!/bin/sh

TEAM=$1
UPGRADE_VERSION=$2
APP=$3
CLUSTER_ID=c-jpxcn
PROJECT_ID=p-zwxgj

if [[ -z $TEAM || -z $UPGRADE_VERSION || -z $APP ]]; then
  echo 'One or more variables are undefined, exiting script ...'
  exit 1
fi

echo "Fetching metadata ..."
HOSTNAME=$(kubectl get --all-namespaces ingress -l app=$APP,team=$TEAM -o jsonpath="{.items[0].spec.rules[0].host}")
WEBCONTEXT=$(kubectl get --all-namespaces ingress -l app=$APP,team=$TEAM -o jsonpath="{.items[0].spec.rules[0].http.paths[0].path}")
POD=$(kubectl get pod --all-namespaces -l app=$APP,team=$TEAM -o jsonpath="{.items[0].metadata.name}")
CURRENT_VERSION=$(kubectl get --all-namespaces deployment -l app=$APP,team=$TEAM -o jsonpath="{.items[0].spec.template.spec.containers[1].image}")
CURRENT_VERSION=$(cut -d ":" -f2 <<< "$CURRENT_VERSION")

if [[ -z $HOSTNAME || -z $WEBCONTEXT || -z $POD || -z $CURRENT_VERSION ]]; then
  echo 'One or more variables could not be fetched, exiting script ...'
  exit 1
fi

echo "Logging in to rancher ..."
rancher login https://rancher.cd.murex.com/ --token token-vkq9d:wg8gtt4gbgtk7nzfhlj4gs87dn4w2hxhd9qmcb9fmnqkllgx57792r --context $CLUSTER_ID:$PROJECT_ID
APP_VERSION=$(rancher app | grep $TEAM-$APP | awk '{print $6}')

echo "Removing ingress ..."
rancher app upgrade $TEAM-$APP $APP_VERSION --set ingress.enabled='false' --set $APP.image.tag="$CURRENT_VERSION" --set hostname="$HOSTNAME" --set team="$TEAM"

echo "Backing up database ..."
kubectl -n $APP exec $POD -c sonardb -- bash -c "pg_dump -U sonar sonar > /var/lib/postgresql/backups/db_dump-$CURRENT_VERSION.sql"

echo "Waiting for 5 seconds..."
sleep 5s

echo "Deploying the upgrade ..."
rancher app upgrade $TEAM-$APP $APP_VERSION --set ingress.enabled='true' --set $APP.image.tag="$UPGRADE_VERSION" --set hostname="$HOSTNAME" --set team="$TEAM"

echo "Initiating playbook ..."
ansible-playbook /data/$TEAM/$APP/upgrade/upgrade.yaml --extra-vars "web_context=$WEBCONTEXT hostname=$HOSTNAME"

echo "SonarQube successfully upgrade it to $UPGRADE_VERSION, you can access the app via http://$HOSTNAME$WEBCONTEXT/new"
