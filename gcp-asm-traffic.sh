#!/bin/bash
#
# Copyright 2019 Shiyghan Navti. Email shiyghan@gmail.com
#
#################################################################################
####   Explore ASM BookInfo Microservice Application in Google Cloud Shell  #####
#################################################################################

# User prompt function
function ask_yes_or_no() {
    read -p "$1 ([y]yes to preview, [n]o to create, [d]del to delete): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        n|no)  echo "no" ;;
        d|del) echo "del" ;;
        *)     echo "yes" ;;
    esac
}

function ask_yes_or_no_proj() {
    read -p "$1 ([y]es to change, or any key to skip): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

clear
MODE=1
export TRAINING_ORG_ID=$(gcloud organizations list --format 'value(ID)' --filter="displayName:techequity.training" 2>/dev/null)
export ORG_ID=$(gcloud projects get-ancestors $GCP_PROJECT --format 'value(ID)' 2>/dev/null | tail -1 )
export GCP_PROJECT=$(gcloud config list --format 'value(core.project)' 2>/dev/null)  

echo
echo
echo -e "                        👋  Welcome to Cloud Sandbox! 💻"
echo 
echo -e "              *** PLEASE WAIT WHILE LAB UTILITIES ARE INSTALLED ***"
sudo apt-get -qq install pv > /dev/null 2>&1
echo 
export SCRIPTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function join_by { local IFS="$1"; shift; echo "$*"; }

mkdir -p `pwd`/gcp-asm-traffic > /dev/null 2>&1
export PROJDIR=`pwd`/gcp-asm-traffic
export SCRIPTNAME=gcp-asm-traffic.sh

if [ -f "$PROJDIR/.env" ]; then
    source $PROJDIR/.env
else
cat <<EOF > $PROJDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=europe-west1
export GCP_ZONE=europe-west1-b
export GCP_CLUSTER=asm-gke-cluster
export ASM_VERSION=1.17.2-asm.8
export ASM_REVISION=asm-1172-2
export ASM_INSTALL_SCRIPT_VERSION=1.17
export ISTIO_VERSION=1.17.2
EOF
source $PROJDIR/.env
fi

export APPLICATION_NAMESPACE=bookinfo # if this changes, search for "bookinfo" and replace
export APPLICATION_NAME=bookinfo

# Display menu options
while :
do
clear
cat<<EOF
========================================================================
Explore Traffic Management, Resiliency and Telemetry Features using ASM
------------------------------------------------------------------------
Please enter number to select your choice:
 (1) Install tools
 (2) Enable APIs
 (3) Create Kubernetes cluster
 (4) Install Anthos Service Mesh
 (5) Configure namespace for automatic sidecar injection
 (6) Configure service and deployment
 (7) Configure gateway and virtual service
 (8) Configure subsets
 (9) Explore traffic routing
(10) Explore circuit breaking
 (G) Launch user guide
 (Q) Quit
-----------------------------------------------------------------------------
EOF
echo "Steps performed${STEP}"
echo
echo "What additional step do you want to perform, e.g. enter 0 to select the execution mode?"
read
clear
case "${REPLY^^}" in

"0")
start=`date +%s`
source $PROJDIR/.env
echo
echo "Do you want to run script in preview mode?"
export ANSWER=$(ask_yes_or_no "Are you sure?")
cd $HOME
if [[ ! -z "$TRAINING_ORG_ID" ]]  &&  [[ $ORG_ID == "$TRAINING_ORG_ID" ]]; then
    export STEP="${STEP},0"
    MODE=1
    if [[ "yes" == $ANSWER ]]; then
        export STEP="${STEP},0i"
        MODE=1
        echo
        echo "*** Command preview mode is active ***" | pv -qL 100
    else 
        if [[ -f $PROJDIR/.${GCP_PROJECT}.json ]]; then
            echo 
            echo "*** Authenticating using service account key $PROJDIR/.${GCP_PROJECT}.json ***" | pv -qL 100
            echo "*** To use a different GCP project, delete the service account key ***" | pv -qL 100
        else
            while [[ -z "$PROJECT_ID" ]] || [[ "$GCP_PROJECT" != "$PROJECT_ID" ]]; do
                echo 
                echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
                gcloud auth login  --brief --quiet
                export ACCOUNT=$(gcloud config list account --format "value(core.account)")
                if [[ $ACCOUNT != "" ]]; then
                    echo
                    echo "Copy and paste a valid Google Cloud project ID below to confirm your choice:" | pv -qL 100
                    read GCP_PROJECT
                    gcloud config set project $GCP_PROJECT --quiet 2>/dev/null
                    sleep 3
                    export PROJECT_ID=$(gcloud projects list --filter $GCP_PROJECT --format 'value(PROJECT_ID)' 2>/dev/null)
                fi
            done
            gcloud iam service-accounts delete ${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com --quiet 2>/dev/null
            sleep 2
            gcloud --project $GCP_PROJECT iam service-accounts create ${GCP_PROJECT} 2>/dev/null
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$GCP_PROJECT@$GCP_PROJECT.iam.gserviceaccount.com --role=roles/owner > /dev/null 2>&1
            gcloud --project $GCP_PROJECT iam service-accounts keys create $PROJDIR/.${GCP_PROJECT}.json --iam-account=${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com 2>/dev/null
            gcloud --project $GCP_PROJECT storage buckets create gs://$GCP_PROJECT > /dev/null 2>&1
        fi
        export GOOGLE_APPLICATION_CREDENTIALS=$PROJDIR/.${GCP_PROJECT}.json
        cat <<EOF > $PROJDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=$GCP_REGION
export GCP_ZONE=$GCP_ZONE
export GCP_CLUSTER=$GCP_CLUSTER
export ASM_VERSION=$ASM_VERSION
export ASM_INSTALL_SCRIPT_VERSION=$ASM_INSTALL_SCRIPT_VERSION
export ISTIO_VERSION=$ISTIO_VERSION
EOF
        gsutil cp $PROJDIR/.env gs://${GCP_PROJECT}/${SCRIPTNAME}.env > /dev/null 2>&1
        echo
        echo "*** Google Cloud project is $GCP_PROJECT ***" | pv -qL 100
        echo "*** Google Cloud region is $GCP_REGION ***" | pv -qL 100
        echo "*** Google Cloud zone is $GCP_ZONE ***" | pv -qL 100
        echo "*** Google Cloud cluster is $GCP_CLUSTER ***" | pv -qL 100
        echo "*** Anthos Service Mesh version is $ASM_VERSION ***" | pv -qL 100
        echo "*** Anthos Service Mesh install script version is $ASM_INSTALL_SCRIPT_VERSION ***" | pv -qL 100
        echo "*** Istio version is $ISTIO_VERSION ***" | pv -qL 100
        echo
        echo "*** Update environment variables by modifying values in the file: ***" | pv -qL 100
        echo "*** $PROJDIR/.env ***" | pv -qL 100
        if [[ "no" == $ANSWER ]]; then
            MODE=2
            echo
            echo "*** Create mode is active ***" | pv -qL 100
        elif [[ "del" == $ANSWER ]]; then
            export STEP="${STEP},0"
            MODE=3
            echo
            echo "*** Resource delete mode is active ***" | pv -qL 100
        fi
    fi
else 
    if [[ "no" == $ANSWER ]] || [[ "del" == $ANSWER ]] ; then
        export STEP="${STEP},0"
        if [[ -f $SCRIPTPATH/.${SCRIPTNAME}.secret ]]; then
            echo
            unset password
            unset pass_var
            echo -n "Enter access code: " | pv -qL 100
            while IFS= read -p "$pass_var" -r -s -n 1 letter
            do
                if [[ $letter == $'\0' ]]
                then
                    break
                fi
                password=$password"$letter"
                pass_var="*"
            done
            while [[ -z "${password// }" ]]; do
                unset password
                unset pass_var
                echo
                echo -n "You must enter an access code to proceed: " | pv -qL 100
                while IFS= read -p "$pass_var" -r -s -n 1 letter
                do
                    if [[ $letter == $'\0' ]]
                    then
                        break
                    fi
                    password=$password"$letter"
                    pass_var="*"
                done
            done
            export PASSCODE=$(cat $SCRIPTPATH/.${SCRIPTNAME}.secret | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:$password 2> /dev/null)
            if [[ $PASSCODE == 'AccessVerified' ]]; then
                MODE=2
                echo && echo
                echo "*** Access code is valid ***" | pv -qL 100
                if [[ -f $PROJDIR/.${GCP_PROJECT}.json ]]; then
                    echo 
                    echo "*** Authenticating using service account key $PROJDIR/.${GCP_PROJECT}.json ***" | pv -qL 100
                    echo "*** To use a different GCP project, delete the service account key ***" | pv -qL 100
                else
                    while [[ -z "$PROJECT_ID" ]] || [[ "$GCP_PROJECT" != "$PROJECT_ID" ]]; do
                        echo 
                        echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
                        gcloud auth login  --brief --quiet
                        export ACCOUNT=$(gcloud config list account --format "value(core.account)")
                        if [[ $ACCOUNT != "" ]]; then
                            echo
                            echo "Copy and paste a valid Google Cloud project ID below to confirm your choice:" | pv -qL 100
                            read GCP_PROJECT
                            gcloud config set project $GCP_PROJECT --quiet 2>/dev/null
                            sleep 3
                            export PROJECT_ID=$(gcloud projects list --filter $GCP_PROJECT --format 'value(PROJECT_ID)' 2>/dev/null)
                        fi
                    done
                    gcloud iam service-accounts delete ${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com --quiet 2>/dev/null
                    sleep 2
                    gcloud --project $GCP_PROJECT iam service-accounts create ${GCP_PROJECT} 2>/dev/null
                    gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$GCP_PROJECT@$GCP_PROJECT.iam.gserviceaccount.com --role=roles/owner > /dev/null 2>&1
                    gcloud --project $GCP_PROJECT iam service-accounts keys create $PROJDIR/.${GCP_PROJECT}.json --iam-account=${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com 2>/dev/null
                    gcloud --project $GCP_PROJECT storage buckets create gs://$GCP_PROJECT > /dev/null 2>&1
                fi
                export GOOGLE_APPLICATION_CREDENTIALS=$PROJDIR/.${GCP_PROJECT}.json
                cat <<EOF > $PROJDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=$GCP_REGION
export GCP_ZONE=$GCP_ZONE
export GCP_CLUSTER=$GCP_CLUSTER
export ASM_VERSION=$ASM_VERSION
export ASM_INSTALL_SCRIPT_VERSION=$ASM_INSTALL_SCRIPT_VERSION
export ISTIO_VERSION=$ISTIO_VERSION
EOF
                gsutil cp $PROJDIR/.env gs://${GCP_PROJECT}/${SCRIPTNAME}.env > /dev/null 2>&1
                echo
                echo "*** Google Cloud project is $GCP_PROJECT ***" | pv -qL 100
                echo "*** Google Cloud region is $GCP_REGION ***" | pv -qL 100
                echo "*** Google Cloud zone is $GCP_ZONE ***" | pv -qL 100
                echo "*** Google Cloud cluster is $GCP_CLUSTER ***" | pv -qL 100
                echo "*** Anthos Service Mesh version is $ASM_VERSION ***" | pv -qL 100
                echo "*** Anthos Service Mesh install script version is $ASM_INSTALL_SCRIPT_VERSION ***" | pv -qL 100
                echo "*** Istio version is $ISTIO_VERSION ***" | pv -qL 100
                echo
                echo "*** Update environment variables by modifying values in the file: ***" | pv -qL 100
                echo "*** $PROJDIR/.env ***" | pv -qL 100
                if [[ "no" == $ANSWER ]]; then
                    MODE=2
                    echo
                    echo "*** Create mode is active ***" | pv -qL 100
                elif [[ "del" == $ANSWER ]]; then
                    export STEP="${STEP},0"
                    MODE=3
                    echo
                    echo "*** Resource delete mode is active ***" | pv -qL 100
                fi
            else
                echo && echo
                echo "*** Access code is invalid ***" | pv -qL 100
                echo "*** You can use this script in our Google Cloud Sandbox without an access code ***" | pv -qL 100
                echo "*** Contact support@techequity.cloud for assistance ***" | pv -qL 100
                echo
                echo "*** Command preview mode is active ***" | pv -qL 100
            fi
        else
            echo
            echo "*** You can use this script in our Google Cloud Sandbox without an access code ***" | pv -qL 100
            echo "*** Contact support@techequity.cloud for assistance ***" | pv -qL 100
            echo
            echo "*** Command preview mode is active ***" | pv -qL 100
        fi
    else
        export STEP="${STEP},0i"
        MODE=1
        echo
        echo "*** Command preview mode is active ***" | pv -qL 100
    fi
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"1")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},1i"
    echo
    echo "$ curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_\${ASM_INSTALL_SCRIPT_VERSION} > \$PROJDIR/asmcli # to download script" | pv -qL 100
    echo
    echo "$ curl -L https://github.com/istio/istio/releases/download/\${ISTIO_VERSION}/istio-\${ISTIO_VERSION}-linux-amd64.tar.gz | tar xz -C \$PROJDIR # to download Istio" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},1"
    echo
    echo "$ curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_${ASM_INSTALL_SCRIPT_VERSION} > $PROJDIR/asmcli # to download script" | pv -qL 100
    curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_${ASM_INSTALL_SCRIPT_VERSION} > $PROJDIR/asmcli
    echo
    echo "$ chmod +x $PROJDIR/asmcli # to make the script executable" | pv -qL 100
    chmod +x $PROJDIR/asmcli
    echo
    echo "$ curl -L https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux-amd64.tar.gz | tar xz -C $PROJDIR # to download Istio" | pv -qL 100
    curl -L https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux-amd64.tar.gz | tar xz -C $PROJDIR 
    export PATH=$PROJDIR/istio-${ASM_VERSION}/bin:$PATH > /dev/null 2>&1 # to set ASM path 
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},1x"
    echo
    echo "$ rm -rf $PROJDIR/asmcli # to delete script" | pv -qL 100
    rm -rf $PROJDIR/asmcli
    echo
    echo "$ rm -rf $PROJDIR/istio-${ISTIO_VERSION} # to delete download" | pv -qL 100
    rm -rf $PROJDIR/istio-${ISTIO_VERSION}
else
    export STEP="${STEP},1i"
    echo
    echo "1. Download ASM script" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"2")
start=`date +%s`
source $PROJDIR/.env
gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},2i"
    echo
    echo "$ gcloud --project \$GCP_PROJECT services enable container.googleapis.com compute.googleapis.com monitoring.googleapis.com logging.googleapis.com cloudtrace.googleapis.com meshca.googleapis.com mesh.googleapis.com meshconfig.googleapis.com iamcredentials.googleapis.com anthos.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com cloudresourcemanager.googleapis.com stackdriver.googleapis.com # to enable APIs" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},2"
    echo
    echo "$ gcloud --project $GCP_PROJECT services enable container.googleapis.com compute.googleapis.com monitoring.googleapis.com logging.googleapis.com cloudtrace.googleapis.com meshca.googleapis.com mesh.googleapis.com meshconfig.googleapis.com iamcredentials.googleapis.com anthos.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com cloudresourcemanager.googleapis.com stackdriver.googleapis.com # to enable APIs" | pv -qL 100
    gcloud --project $GCP_PROJECT services enable container.googleapis.com compute.googleapis.com monitoring.googleapis.com logging.googleapis.com cloudtrace.googleapis.com meshca.googleapis.com mesh.googleapis.com meshconfig.googleapis.com iamcredentials.googleapis.com anthos.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com cloudresourcemanager.googleapis.com stackdriver.googleapis.com 
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},2x"
    echo
    echo "*** Nothing to delete ***" | pv -qL 100
else
    export STEP="${STEP},2i"
    echo
    echo "1. Enable APIs" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"3")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},3i"
    echo
    echo "$ gcloud --project \$GCP_PROJECT beta container clusters create \${GCP_CLUSTER} --machine-type=e2-standard-4 --num-nodes=3 --workload-pool=\${WORKLOAD_POOL} --labels=mesh_id=\${MESH_ID},location=\$GCP_REGION --spot # to create container cluster" | pv -qL 100
    echo      
    echo "$ gcloud --project \$GCP_PROJECT container clusters get-credentials \$GCP_CLUSTER --zone \$GCP_ZONE # to retrieve the credentials for cluster" | pv -qL 100
    echo
    echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"\$(gcloud config get-value core/account)\" # to enable current user to set RBAC rules" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},3"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    export MESH_ID="proj-${PROJECT_NUMBER}" # sets the mesh_id label on the cluster, required for metrics to get displayed on ASM Dashboard
    export PROJECT_ID=${GCP_PROJECT}
    export WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
    export CLUSTER_NAME=${GCP_CLUSTER}
    echo
    echo "$ gcloud --project $GCP_PROJECT beta container clusters create ${GCP_CLUSTER} --machine-type=e2-standard-4 --num-nodes=3 --workload-pool=${WORKLOAD_POOL} --labels=mesh_id=${MESH_ID},location=$GCP_REGION --spot # to create container cluster" | pv -qL 100
    gcloud --project $GCP_PROJECT beta container clusters create ${GCP_CLUSTER} --zone $GCP_ZONE --machine-type=e2-standard-4 --num-nodes=3 --workload-pool=${WORKLOAD_POOL} --labels=mesh_id=${MESH_ID},location=$GCP_REGION --spot
    echo      
    echo "$ gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE # to retrieve the credentials for cluster" | pv -qL 100
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE
    echo
    echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"\$(gcloud config get-value core/account)\" # to enable current user to set RBAC rules" | pv -qL 100
    kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},3"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    export MESH_ID="proj-${PROJECT_NUMBER}" # sets the mesh_id label on the cluster, required for metrics to get displayed on ASM Dashboard
    export PROJECT_ID=${GCP_PROJECT}
    export WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
    export CLUSTER_NAME=${GCP_CLUSTER}
    echo
    echo "$ gcloud --project $GCP_PROJECT beta container clusters delete ${GCP_CLUSTER} --zone $GCP_ZONE # to create container cluster" | pv -qL 100
    gcloud --project $GCP_PROJECT beta container clusters delete ${GCP_CLUSTER} --zone $GCP_ZONE
else
    export STEP="${STEP},3i"
    echo
    echo "1. Create cluster" | pv -qL 100
    echo "2. Retrieve credentials for cluster" | pv -qL 100
    echo "3. Ensure user has admin priviledges" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"4")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},4i"
    echo
    echo "$ cat > \$PROJDIR/tracing.yaml <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
  values:
    global:
      proxy:
        tracer: stackdriver
EOF" | pv -qL 100
    echo "$ \$PROJDIR/asmcli validate --project_id \$GCP_PROJECT --cluster_name \$GCP_CLUSTER --cluster_location \$GCP_ZONE --fleet_id \$GCP_PROJECT --output_dir \$PROJDIR # to validate your configuration and download the installation file and asm package to the OUTPUT_DIR directory" | pv -qL 100
    echo
    echo "$ \$PROJDIR/asmcli install --project_id \$GCP_PROJECT --cluster_name \$GCP_CLUSTER --cluster_location \$GCP_ZONE --option vm --output_dir \$PROJDIR --enable_all --ca mesh_ca --custom_overlay \$PROJDIR/tracing.yaml # to install ASM" | pv -qL 100
    echo
    echo "$ kubectl create namespace \$APPLICATION_NAMESPACE # to create namespace" | pv -qL 100
    echo
    echo "$ kubectl label namespace \$APPLICATION_NAMESPACE istio.io/rev=\$ASM_REVISION --overwrite # to create ingress" | pv -qL 100
    echo
    echo "$ kubectl apply -n \$APPLICATION_NAMESPACE -f \$PROJDIR/samples/gateways/istio-ingressgateway # to create ingress" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},4"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    echo
    echo "$ gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE # to retrieve the credentials for cluster" | pv -qL 100
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE
    echo
    echo "$ cat > $PROJDIR/tracing.yaml <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
  values:
    global:
      proxy:
        tracer: stackdriver
EOF" | pv -qL 100
cat > $PROJDIR/tracing.yaml <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
  values:
    global:
      proxy:
        tracer: stackdriver
EOF
    echo
    sudo apt-get install ncat -y > /dev/null 2>&1 
    echo "$ $PROJDIR/asmcli install --project_id $GCP_PROJECT --cluster_name $GCP_CLUSTER --cluster_location $GCP_ZONE --fleet_id $GCP_PROJECT --option vm --output_dir $PROJDIR --enable_all --ca mesh_ca --custom_overlay $PROJDIR/tracing.yaml # to install ASM" | pv -qL 100
    $PROJDIR/asmcli install --project_id $GCP_PROJECT --cluster_name $GCP_CLUSTER --cluster_location $GCP_ZONE --fleet_id $GCP_PROJECT --option vm --output_dir $PROJDIR --enable_all --ca mesh_ca --custom_overlay $PROJDIR/tracing.yaml 
    echo "$ kubectl create namespace $APPLICATION_NAMESPACE # to create namespace" | pv -qL 100
    kubectl create namespace $APPLICATION_NAMESPACE
    echo
    echo "$ kubectl label namespace $APPLICATION_NAMESPACE istio.io/rev=$ASM_REVISION --overwrite # to create ingress" | pv -qL 100
    kubectl label namespace $APPLICATION_NAMESPACE istio.io/rev=$ASM_REVISION --overwrite
    echo
    echo "$ kubectl apply -n $APPLICATION_NAMESPACE -f $PROJDIR/samples/gateways/istio-ingressgateway # to create ingress" | pv -qL 100
    kubectl apply -n $APPLICATION_NAMESPACE -f $PROJDIR/samples/gateways/istio-ingressgateway
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},4x"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    export CLUSTER_LOCATION=$GCP_ZONE
    echo
    echo "$ kubectl label namespace $APPLICATION_NAMESPACE istio.io/rev # to remove labels" | pv -qL 100
    kubectl label namespace $APPLICATION_NAMESPACE istio.io/rev-
    echo
    echo "$ kubectl delete validatingwebhookconfiguration,mutatingwebhookconfiguration -l operator.istio.io/component=Pilot # to remove webhooks" | pv -qL 100
    kubectl delete validatingwebhookconfiguration,mutatingwebhookconfiguration -l operator.istio.io/component=Pilot
    echo
    echo "$ $PROJDIR/istio-$ASM_VERSION/bin/istioctl x uninstall --purge # to remove the in-cluster control plane" | pv -qL 100
    $PROJDIR/istio-$ASM_VERSION/bin/istioctl x uninstall --purge
    echo && echo
    echo "$  kubectl delete namespace istio-system asm-system --ignore-not-found=true # to remove namespace" | pv -qL 100
     kubectl delete namespace istio-system asm-system --ignore-not-found=true
else
    export STEP="${STEP},4i"
    echo
    echo "1. Retrieve the credentials for cluster" | pv -qL 100
    echo "2. Configure Istio Operator" | pv -qL 100
    echo "3. Install Anthos Service Mesh" | pv -qL 100
    echo "4. Create and label namespace" | pv -qL 100
    echo "5. Configure istio ingress gateway" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"5")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},5i"
    echo
    echo "$ kubectl apply -n \$APPLICATION_NAMESPACE -f \$PROJDIR/samples/gateways/istio-ingressgateway # to install ingress-gateway" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},5"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    echo
    echo "$ kubectl apply -n $APPLICATION_NAMESPACE -f $PROJDIR/samples/gateways/istio-ingressgateway # to install ingress-gateway" | pv -qL 100
    kubectl apply -n $APPLICATION_NAMESPACE -f $PROJDIR/samples/gateways/istio-ingressgateway
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},5x"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    echo
    echo "$ kubectl delete -n $APPLICATION_NAMESPACE -f $PROJDIR/samples/gateways/istio-ingressgateway # to uninstall ingress-gateway" | pv -qL 100
    kubectl delete -n $APPLICATION_NAMESPACE -f $PROJDIR/samples/gateways/istio-ingressgateway
else
    export STEP="${STEP},5i"
    echo
    echo "1. Configure istio ingress gateway" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"6")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},6i"
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f \$PROJDIR/istio-\${ASM_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml # to configure application" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec -it \$(kubectl -n \$APPLICATION_NAMESPACE get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o \"<title>.*</title>\" # to validate access to application" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},6"        
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    cd $PROJDIR/istio-${ASM_VERSION}
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml # to configure application" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE apply -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml
    echo
    echo "$ kubectl wait --for=condition=available --timeout=600s deployment --all -n $APPLICATION_NAMESPACE # to wait for the deployment to finish" | pv -qL 100
    kubectl wait --for=condition=available --timeout=600s deployment --all -n $APPLICATION_NAMESPACE
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec -it \$(kubectl -n $APPLICATION_NAMESPACE get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o \"<title>.*</title>\" # to validate access to application" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec -it $(kubectl -n $APPLICATION_NAMESPACE get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},6x"        
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml # to delete application" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml
else
    export STEP="${STEP},6i"
    echo
    echo "1. Apply application manifests" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"7")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},7i"
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f \$PROJDIR/istio-\${ASM_VERSION}/samples/bookinfo/networking/bookinfo-gateway.yaml # to configure gateway and virtual service" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},7"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    cd $PROJDIR/istio-${ASM_VERSION}
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/bookinfo-gateway.yaml # to configure gateway and virtual service" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE apply -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/bookinfo-gateway.yaml
    export INGRESS_HOST=$(kubectl -n $APPLICATION_NAMESPACE get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE get gateway # to confirm gateway configutation" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE get gateway
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE get virtualservice # to confirm virtualservice configutation" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE get virtualservice
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},7x"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    cd $PROJDIR/istio-${ASM_VERSION}
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/bookinfo-gateway.yaml # to configure gateway and virtual service" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete -f $PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/bookinfo-gateway.yaml
else
    export STEP="${STEP},7i"
    echo
    echo "1. Configure gateway and virtual service" | pv -qL 100
fi
echo
read -n 1 -s -r -p "$ "
;;

"8")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},8i"
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f \$PROJDIR/istio-\${ASM_VERSION}/samples/bookinfo/networking/destination-rule-all.yaml # to apply yaml file" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},8"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    export CFILE=$PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/destination-rule-all.yaml
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE # to apply yaml file" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},8x"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    export CFILE=$PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/destination-rule-all.yaml
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE # to apply yaml file" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE
else
    export STEP="${STEP},8i"
    echo
    echo "1. Apply service mesh manifests" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;
   
"9")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},9i"
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f \$PROJDIR/istio-\${ASM_VERSION}/samples/bookinfo/networking/virtual-service-all-v1.yaml # to route all traffic to v1 of each microservice" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f \$PROJDIR/istio-\${ASM_VERSION}/samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml # to route requests to jason user" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f \$PROJDIR/istio-\${ASM_VERSION}/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml # to redirect 50% of traffic to v3" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE delete VirtualService reviews # to delete VirtualService" | pv -qL 100
    echo
    echo "$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  http:
  - route:
    - destination:
        host: productpage
        subset: v1
    retries:
      attempts: 1
      perTryTimeout: 2s
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE delete VirtualService productpage # to delete VirtualService" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings
  http:
  - match:
    - headers:
        user-agent:
      regex: ^(.*?;)?(iPhone)(;.*)?$
    route:
    - destination:
        host: ratings-iPhone # to route request based on user agent
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: ratings
  namespace: bookinfo
spec:
  egress:
  - hosts:
    - \"./*\"
    - \"istio-system/*\" # to limit the set of services that the Envoy proxy can reach
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings-port
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy: # Apply to all ports
    portLevelSettings:
    - port:
        number: 80
      loadBalancer:
        simple: LEAST_CONN
    - port:
        number: 9080
      loadBalancer:
        simple: ROUND_ROBIN # load balancing configuration
EOF" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},9"
    gcloud config set project $GCP_PROJECT  > /dev/null 2>&1
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER}  > /dev/null 2>&1
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER  > /dev/null 2>&1
    export INGRESS_HOST=$(kubectl -n $APPLICATION_NAMESPACE get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}') 2>/dev/null
    export CFILE=$PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/virtual-service-all-v1.yaml
    while true; do curl -s -o /dev/null http://${INGRESS_HOST}/productpage ; sleep 1; done &
    echo
    echo "$ cat $CFILE # to view yaml file for routing all traffic to v1 of each microservice" | pv -qL 100
    cat $CFILE
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE # to route all traffic to v1 of each microservice" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE # to delete rule" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE
    export PFILE=$CFILE
    export CFILE=$PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml
    echo 
    echo "$ cat $CFILE # to view yaml file" | pv -qL 100
    cat $CFILE
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE # to route requests to jason user" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE
    while true; do curl -s -H 'end-user: jason' -o /dev/null http://${INGRESS_HOST}/productpage ; sleep 1; done &
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE # to delete rule" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE
    export PFILE=$CFILE
    export CFILE=$PROJDIR/istio-${ASM_VERSION}/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
    echo 
    echo "$ cat $CFILE # to view yaml file" | pv -qL 100
    cat $CFILE 
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE # to redirect 50% of traffic to v3" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE # to delete rule" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s # add a half second request timeout for calls to the reviews service
EOF
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete VirtualService reviews # to delete VirtualService" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete VirtualService reviews
    echo
    echo "$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  http:
  - route:
    - destination:
        host: productpage
        subset: v1
    retries:
      attempts: 1
      perTryTimeout: 2s
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  http:
  - route:
    - destination:
        host: productpage
        subset: v1
    retries:
      attempts: 1
      perTryTimeout: 2s
EOF
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete VirtualService productpage # to delete VirtualService" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete VirtualService productpage
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings
  http:
  - match:
    - headers:
        user-agent:
      regex: ^(.*?;)?(iPhone)(;.*)?$
    route:
    - destination:
        host: ratings-iPhone # to route request based on user agent
EOF" | pv -qL 100
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: ratings
  namespace: bookinfo
spec:
  egress:
  - hosts:
    - \"./*\"
    - \"istio-system/*\" # to limit the set of services that the Envoy proxy can reach
EOF" | pv -qL 100
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100    
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings-port
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy: # Apply to all ports
    portLevelSettings:
    - port:
        number: 80
      loadBalancer:
        simple: LEAST_CONN
    - port:
        number: 9080
      loadBalancer:
        simple: ROUND_ROBIN # load balancing configuration
EOF" | pv -qL 100
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},9x"
    echo
    echo "*** Nothing to delete ***" | pv -qL 100
else
    export STEP="${STEP},9i"
    echo
    echo "1. Apply service mesh manifests" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"-10")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},10i"
    echo
    echo "$ cat << \"EOF\" > $PROJDIR/init-mysql
#!/bin/bash

# Wait until Envoy is ready before installing mysql
while true; do
  rt=\$(curl -s 127.0.0.1:15000/ready)
  if [[ \$? -eq 0 ]] && [[ \"\${rt}\" -eq \"LIVE\" ]]; then
    echo \"envoy is ready\"
    break
  fi
  sleep 1
done

# Wait until DNS is ready before installing mysql
while true; do
  curl -I productpage.bookinfo.svc:9080
  if [[ \$? -eq 0 ]]; then
    echo \"dns is ready\"
    break
  fi
  sleep 1
done

sudo apt-get update && sudo apt-get install -y mariadb-server

sudo sed -i '/bind-address/c\bind-address  = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf

cat <<EOD | sudo mysql
# Grant access to root
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

# Grant root access to other IPs
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit
EOD

sudo systemctl restart mysql

curl -LO https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/src/mysql/mysqldb-init.sql

mysql -u root -ppassword < mysqldb-init.sql
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
 name: $WORKLOAD_NAME
spec:
 metadata:
   labels:
     app.kubernetes.io/name: $WORKLOAD_NAME
     app.kubernetes.io/version: $WORKLOAD_VERSION
   annotations:
     security.cloud.google.com/IdentityProvider: google
 template:
   serviceAccount: ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com # to create the WorkloadGroup for the VMs to be registered
EOF" | pv -qL 100
    echo
    echo "$ gcloud beta compute instance-templates create $ASM_INSTANCE_TEMPLATE --mesh gke-cluster=$GCP_ZONE/$CLUSTER_NAME,workload=$APPLICATION_NAMESPACE/$WORKLOAD_NAME --project $PROJECT_ID --metadata-from-file=startup-script=$PROJDIR/init-mysql --image-family=debian-10 --image-project=debian-cloud --boot-disk-size=10GB # to create a Compute Engine instance from a template that includes a startup script to install MySQL and add a ratings database upon startup" | pv -qL 100
    echo
    echo "$ gcloud compute instance-groups managed create ${WORKLOAD_NAME}-instance --template $ASM_INSTANCE_TEMPLATE --zone=$GCP_ZONE --project=$PROJECT_ID --size=1 # to create MIG" | pv -qL 100
    echo
    gcloud --project $GCP_PROJECT compute firewall-rules delete $APPLICATION_NAME-k8s-to-${WORKLOAD_NAME}-vm --quiet > /dev/null 2>&1
    echo "$ gcloud --project $GCP_PROJECT compute firewall-rules create $APPLICATION_NAME-k8s-to-${WORKLOAD_NAME}-vm --allow=tcp:3306 --network=default --direction=INGRESS --priority=900 --source-ranges=\"\${ALL_CLUSTER_CIDRS}\" --quiet # to create firewall rule" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},10"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    export PROJECT_NUMBER=$(gcloud projects describe ${GCP_PROJECT} --format="value(projectNumber)")
    export WORKLOAD_NAME=mysql # to set the workload the VM is part of
    export WORKLOAD_VERSION=v1 # to set the workload version the VM is part of
    export ASM_INSTANCE_TEMPLATE=${WORKLOAD_NAME}-asm-tpl # to set the name of the instance template to be created
    export SOURCE_INSTANCE_TEMPLATE=${WORKLOAD_NAME}-src-tpl # to set the template name to base the generated template on
    export INSTANCE_GROUP_NAME=${WORKLOAD_NAME}-inst-grp # to set the name of the Compute Engine instance group to create
    export INSTANCE_GROUP_ZONE=${GCP_ZONE} # to set the zone of the Compute Engine instance group to be created
    export SIZE=1 # to set the size of the instance group to be created
    echo
    echo "$ cat << \"EOF\" > $PROJDIR/init-mysql
#!/bin/bash

# Wait until Envoy is ready before installing mysql
while true; do
  rt=\$(curl -s 127.0.0.1:15000/ready)
  if [[ \$? -eq 0 ]] && [[ \"\${rt}\" -eq \"LIVE\" ]]; then
    echo \"envoy is ready\"
    break
  fi
  sleep 1
done

# Wait until DNS is ready before installing mysql
while true; do
  curl -I productpage.bookinfo.svc:9080
  if [[ \$? -eq 0 ]]; then
    echo \"dns is ready\"
    break
  fi
  sleep 1
done

sudo apt-get update && sudo apt-get install -y mariadb-server

sudo sed -i '/bind-address/c\bind-address  = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf

cat <<EOD | sudo mysql
# Grant access to root
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

# Grant root access to other IPs
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit
EOD

sudo systemctl restart mysql

curl -LO https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/src/mysql/mysqldb-init.sql

mysql -u root -ppassword < mysqldb-init.sql
EOF" | pv -qL 100
cat << "EOF" > $PROJDIR/init-mysql
#!/bin/bash

# Wait until Envoy is ready before installing mysql
while true; do
  rt=$(curl -s 127.0.0.1:15000/ready)
  if [[ $? -eq 0 ]] && [[ "${rt}" -eq "LIVE" ]]; then
    echo "envoy is ready"
    break
  fi
  sleep 1
done

# Wait until DNS is ready before installing mysql
while true; do
  curl -I productpage.bookinfo.svc:9080
  if [[ $? -eq 0 ]]; then
    echo "dns is ready"
    break
  fi
  sleep 1
done

sudo apt-get update && sudo apt-get install -y mariadb-server

sudo sed -i '/bind-address/c\bind-address  = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf

cat <<EOD | sudo mysql
# Grant access to root
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

# Grant root access to other IPs
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit
EOD

sudo systemctl restart mysql

curl -LO https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/src/mysql/mysqldb-init.sql

mysql -u root -ppassword < mysqldb-init.sql
EOF
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
 name: $WORKLOAD_NAME
spec:
 metadata:
   labels:
     app.kubernetes.io/name: $WORKLOAD_NAME
     app.kubernetes.io/version: $WORKLOAD_VERSION
   annotations:
     security.cloud.google.com/IdentityProvider: google
 template:
   serviceAccount: ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com # to create the WorkloadGroup for the VMs to be registered
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
 name: $WORKLOAD_NAME
spec:
 metadata:
   labels:
     app.kubernetes.io/name: $WORKLOAD_NAME
     app.kubernetes.io/version: $WORKLOAD_VERSION
   annotations:
     security.cloud.google.com/IdentityProvider: google
 template:
   serviceAccount: ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com # to create the WorkloadGroup for the VMs to be registered
EOF
    echo
    echo "$ gcloud beta compute instance-templates create $ASM_INSTANCE_TEMPLATE --mesh gke-cluster=$GCP_ZONE/$CLUSTER_NAME,workload=$APPLICATION_NAMESPACE/$WORKLOAD_NAME --project $PROJECT_ID --metadata-from-file=startup-script=$PROJDIR/init-mysql --image-family=debian-10 --image-project=debian-cloud --boot-disk-size=10GB # to create a Compute Engine instance from a template that includes a startup script to install MySQL and add a ratings database upon startup" | pv -qL 100
    gcloud beta compute instance-templates create $ASM_INSTANCE_TEMPLATE --mesh gke-cluster=$GCP_ZONE/$CLUSTER_NAME,workload=$APPLICATION_NAMESPACE/$WORKLOAD_NAME --project $PROJECT_ID --metadata-from-file=startup-script=$PROJDIR/init-mysql --image-family=debian-10 --image-project=debian-cloud --boot-disk-size=10GB
    echo
    echo "$ gcloud compute instance-groups managed create ${WORKLOAD_NAME}-instance --template $ASM_INSTANCE_TEMPLATE --zone=$GCP_ZONE --project=$PROJECT_ID --size=1 # to create MIG" | pv -qL 100
    gcloud compute instance-groups managed create ${WORKLOAD_NAME}-instance --template $ASM_INSTANCE_TEMPLATE --zone=$GCP_ZONE --project=$PROJECT_ID --size=1
    echo
    export ALL_CLUSTER_CIDRS=$(gcloud --project $GCP_PROJECT container clusters list --format='value(clusterIpv4Cidr)' | sort | uniq) # to retrieve cluster CIDR ranges"
    export ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}")) # to create a list of all cluster CIDR ranges"
    gcloud --project $GCP_PROJECT compute firewall-rules delete $APPLICATION_NAME-k8s-to-${WORKLOAD_NAME}-vm --quiet > /dev/null 2>&1
    echo "$ gcloud --project $GCP_PROJECT compute firewall-rules create $APPLICATION_NAME-k8s-to-${WORKLOAD_NAME}-vm --allow=tcp:3306 --network=default --direction=INGRESS --priority=900 --source-ranges=\"${ALL_CLUSTER_CIDRS}\" --quiet # to create firewall rule" | pv -qL 100
    gcloud --project $GCP_PROJECT compute firewall-rules create $APPLICATION_NAME-k8s-to-${WORKLOAD_NAME}-vm --allow=tcp:3306 --network=default --direction=INGRESS --priority=900 --source-ranges="${ALL_CLUSTER_CIDRS}" --quiet
else
    export STEP="${STEP},10i"
    echo
    echo "1. Configure database startup script" | pv -qL 100
    echo "2. Create WorkloadGroup for VMs to be registered" | pv -qL 100
    echo "3. Create virtual machine from template including startup script" | pv -qL 100
    echo "4. Create managed instance group" | pv -qL 100
    echo "5. Configure firewall rule" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"-11")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},11i"
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
 name: $WORKLOAD_NAME
 labels:
   asm_resource_type: VM
spec:
 ports:
 - name: mysql
   port: 3306
   protocol: TCP
   targetPort: 3306
 selector:
   app.kubernetes.io/name: $WORKLOAD_NAME # to add a Kubernetes Service to expose VM workloads
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
 name: ratings-v2-mysql-vm
 labels:
   app: ratings
   version: v2-mysql-vm
spec:
 replicas: 1
 selector:
   matchLabels:
     app: ratings
     version: v2-mysql-vm
 template:
   metadata:
     labels:
       app: ratings
       version: v2-mysql-vm
   spec:
     serviceAccountName: bookinfo-ratings
     containers:
     - name: ratings
       image: docker.io/istio/examples-bookinfo-ratings-v2:1.16.2
       imagePullPolicy: IfNotPresent
       env:
         - name: DB_TYPE
           value: \"mysql\"
         - name: MYSQL_DB_HOST
           value: mysql.${APPLICATION_NAMESPACE}.svc.cluster.local
         - name: MYSQL_DB_PORT
           value: \"3306\"
         - name: MYSQL_DB_USER
           value: root
         - name: MYSQL_DB_PASSWORD
           value: password
       ports:
       - containerPort: 9080 # to create a new rating service to use the MySQL instance
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
 name: reviews
spec:
 hosts:
 - reviews
 http:
 - route:
   - destination:
       host: reviews
       subset: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
 name: ratings
spec:
 hosts:
 - ratings
 http:
 - route:
   - destination:
       host: ratings
       subset: v2-mysql-vm # to create a routing rule
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: reviews
spec:
 host: reviews
 subsets:
 - name: v1
   labels:
     version: v1
 - name: v2
   labels:
     version: v2
 - name: v3
   labels:
     version: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: ratings
spec:
 host: ratings
 subsets:
 - name: v1
   labels:
     version: v1
 - name: v2
   labels:
     version: v2
 - name: v2-mysql
   labels:
     version: v2-mysql
 - name: v2-mysql-vm
   labels:
     version: v2-mysql-vm # to apply destination rules for the created services.
EOF" | pv -qL 100
    echo
    echo "*** SSH into the mysql VM and run the command below ***" | pv -qL 100
    echo "*** mysql -u root -ppassword test -e \"select * from ratings;\" ***" | pv -qL 100
    echo
    echo "*** Access application at http://\$INGRESS_HOST/productpage ***" | pv -qL 100
    echo
    echo "*** SSH into the mysql VM and run the command below ***" | pv -qL 100
    echo "*** mysql -u root -ppassword test -e \"update ratings set rating=1 where reviewid=1;select * from ratings;\" ***" | pv -qL 100
    echo
    echo "*** Access application at http://\$INGRESS_HOST/productpage ***" | pv -qL 100
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: $APPLICATION_NAME
spec:
  mtls:
    mode: STRICT # to enable mTLS strict mode for the mesh
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: mysql-deny
spec:
  selector:
    matchLabels:
      app: ratings
      app.kubernetes.io/name: mysql
  action: DENY
  rules:
  - from:
    - source:
        principals: [\"cluster.local/ns/${APPLICATION_NAMESPACE}/sa/bookinfo-ratings\"] # to deny a Kubernetes workload ratings from accessing VM that serves ratings MySQL server
EOF" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},11"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1 
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1 
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE > /dev/null 2>&1 
    export WORKLOAD_NAME=mysql # to set the workload the VM is part of
    export WORKLOAD_VERSION=v1 # to set the workload version the VM is part of
    export ASM_INSTANCE_TEMPLATE=${WORKLOAD_NAME}-asm-tpl # to set the name of the instance template to be created
    export SOURCE_INSTANCE_TEMPLATE=${WORKLOAD_NAME}-src-tpl # to set the template name to base the generated template on
    export INSTANCE_GROUP_NAME=${WORKLOAD_NAME}-inst-grp # to set the name of the Compute Engine instance group to create
    export INSTANCE_GROUP_ZONE=${GCP_ZONE} # to set the zone of the Compute Engine instance group to be created
    export SIZE=1 # to set the size of the instance group to be created
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
 name: $WORKLOAD_NAME
 labels:
   asm_resource_type: VM
spec:
 ports:
 - name: mysql
   port: 3306
   protocol: TCP
   targetPort: 3306
 selector:
   app.kubernetes.io/name: $WORKLOAD_NAME # to add a Kubernetes Service to expose VM workloads
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
 name: $WORKLOAD_NAME
 labels:
   asm_resource_type: VM
spec:
 ports:
 - name: mysql
   port: 3306
   protocol: TCP
   targetPort: 3306
 selector:
   app.kubernetes.io/name: $WORKLOAD_NAME # to add a Kubernetes Service to expose VM workloads
EOF
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
 name: ratings-v2-mysql-vm
 labels:
   app: ratings
   version: v2-mysql-vm
spec:
 replicas: 1
 selector:
   matchLabels:
     app: ratings
     version: v2-mysql-vm
 template:
   metadata:
     labels:
       app: ratings
       version: v2-mysql-vm
   spec:
     serviceAccountName: bookinfo-ratings
     containers:
     - name: ratings
       image: docker.io/istio/examples-bookinfo-ratings-v2:1.16.2
       imagePullPolicy: IfNotPresent
       env:
         - name: DB_TYPE
           value: \"mysql\"
         - name: MYSQL_DB_HOST
           value: mysql.${APPLICATION_NAMESPACE}.svc.cluster.local
         - name: MYSQL_DB_PORT
           value: \"3306\"
         - name: MYSQL_DB_USER
           value: root
         - name: MYSQL_DB_PASSWORD
           value: password
       ports:
       - containerPort: 9080 # to create a new rating service to use the MySQL instance
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
 name: ratings-v2-mysql-vm
 labels:
   app: ratings
   version: v2-mysql-vm
spec:
 replicas: 1
 selector:
   matchLabels:
     app: ratings
     version: v2-mysql-vm
 template:
   metadata:
     labels:
       app: ratings
       version: v2-mysql-vm
   spec:
     serviceAccountName: bookinfo-ratings
     containers:
     - name: ratings
       image: docker.io/istio/examples-bookinfo-ratings-v2:1.16.2
       imagePullPolicy: IfNotPresent
       env:
         - name: DB_TYPE
           value: "mysql"
         - name: MYSQL_DB_HOST
           value: mysql.${APPLICATION_NAMESPACE}.svc.cluster.local
         - name: MYSQL_DB_PORT
           value: "3306"
         - name: MYSQL_DB_USER
           value: root
         - name: MYSQL_DB_PASSWORD
           value: password
       ports:
       - containerPort: 9080 # to create a new rating service to use the MySQL instance
EOF
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
 name: reviews
spec:
 hosts:
 - reviews
 http:
 - route:
   - destination:
       host: reviews
       subset: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
 name: ratings
spec:
 hosts:
 - ratings
 http:
 - route:
   - destination:
       host: ratings
       subset: v2-mysql-vm # to create a routing rule
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
 name: reviews
spec:
 hosts:
 - reviews
 http:
 - route:
   - destination:
       host: reviews
       subset: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
 name: ratings
spec:
 hosts:
 - ratings
 http:
 - route:
   - destination:
       host: ratings
       subset: v2-mysql-vm # to create a routing rule
EOF
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: reviews
spec:
 host: reviews
 subsets:
 - name: v1
   labels:
     version: v1
 - name: v2
   labels:
     version: v2
 - name: v3
   labels:
     version: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: ratings
spec:
 host: ratings
 subsets:
 - name: v1
   labels:
     version: v1
 - name: v2
   labels:
     version: v2
 - name: v2-mysql
   labels:
     version: v2-mysql
 - name: v2-mysql-vm
   labels:
     version: v2-mysql-vm # to apply destination rules for the created services.
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: reviews
spec:
 host: reviews
 subsets:
 - name: v1
   labels:
     version: v1
 - name: v2
   labels:
     version: v2
 - name: v3
   labels:
     version: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: ratings
spec:
 host: ratings
 subsets:
 - name: v1
   labels:
     version: v1
 - name: v2
   labels:
     version: v2
 - name: v2-mysql
   labels:
     version: v2-mysql
 - name: v2-mysql-vm
   labels:
     version: v2-mysql-vm # to apply destination rules for the created services.
EOF
    echo
    echo "*** SSH into the mysql VM and run the command below ***" | pv -qL 100
    read -n 1 -s -r -p "*** mysql -u root -ppassword test -e \"select * from ratings;\" ***" | pv -qL 100
    echo && echo
    export INGRESS_HOST=$(kubectl -n $APPLICATION_NAMESPACE get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    read -n 1 -s -r -p "*** Access application at http://$INGRESS_HOST/productpage ***" | pv -qL 100
    echo && echo
    echo "*** SSH into the mysql VM and run the command below ***" | pv -qL 100
    read -n 1 -s -r -p "*** mysql -u root -ppassword test -e \"update ratings set rating=1 where reviewid=1;select * from ratings;\" ***" | pv -qL 100
    echo && echo
    read -n 1 -s -r -p "*** Access application at http://$INGRESS_HOST/productpage ***" | pv -qL 100
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: $APPLICATION_NAME
spec:
  mtls:
    mode: STRICT # to enable mTLS strict mode for the mesh
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF 
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: $APPLICATION_NAME
spec:
  mtls: | pv -qL 100
    mode: STRICT
EOF
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***' | pv -qL 100
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: mysql-deny
spec:
  selector:
    matchLabels:
      app: ratings
      app.kubernetes.io/name: mysql
  action: DENY
  rules:
  - from:
    - source:
        principals: [\"cluster.local/ns/${APPLICATION_NAMESPACE}/sa/bookinfo-ratings\"] # to deny a Kubernetes workload ratings from accessing VM that serves ratings MySQL server
EOF" | pv -qL 100
kubectl -n $APPLICATION_NAMESPACE apply -f - << EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: mysql-deny
spec:
  selector:
    matchLabels:
      app: ratings
      app.kubernetes.io/name: mysql
  action: DENY
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${APPLICATION_NAMESPACE}/sa/bookinfo-ratings"] # to deny a Kubernetes workload ratings from accessing VM that serves ratings MySQL server
EOF
else
    export STEP="${STEP},11i"
    echo
    echo "1. Apply service mesh manifests" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"10")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},10i"
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE apply -f \$PROJDIR/istio-\${ASM_VERSION}/samples/httpbin/sample-client/fortio-deploy.yaml # to deploy the FORTIO client" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec -it \$FORTIO_POD  -c fortio -- /usr/bin/fortio load -curl -quiet http://\${INGRESS_HOST}/productpage  | grep -o \"<title>.*</title>\" # to invoke the service with one connection and send 1 request" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec -it \$FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://\${INGRESS_HOST}/productpage # to invoke the service with 2 concurrent connections (-c 2) and send 20 requests (-n 20)" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec -it \$FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://\${INGRESS_HOST}/productpage # to invoke the service with 3 concurrent connections (-c 3) and send 30 requests (-n 30)" | pv -qL 100
    echo
    echo "$ kubectl apply -n \$APPLICATION_NAMESPACE -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
EOF" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec -it \$FORTIO_POD  -c fortio -- /usr/bin/fortio load -curl http://\${INGRESS_HOST}/productpage | grep -o \"<title>.*</title>\" # to invoke the service with one connection and send 1 request" | pv -qL 100
    echo
    echo "$ sleep 15 # to wait for 15 secs and load test" | pv -qL 100
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec -it \$FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://\${INGRESS_HOST}/productpage # to invoke the service with 2 concurrent connections (-c 2) and send 20 requests (-n 20)" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec -it \$FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://\${INGRESS_HOST}/productpage # to invoke the service with 3 concurrent connections (-c 3) and send 30 requests (-n 30)" | pv -qL 100
    echo
    echo "$ kubectl -n \$APPLICATION_NAMESPACE exec \$FORTIO_POD -c istio-proxy -- pilot-agent request GET stats | grep productpage | grep pending # to query the istio-proxy stats" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},10"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    kubectl config use-context gke_${GCP_PROJECT}_${GCP_ZONE}_${GCP_CLUSTER} > /dev/null 2>&1
    gcloud --project $GCP_PROJECT container clusters get-credentials $GCP_CLUSTER > /dev/null 2>&1
    export INGRESS_HOST=$(kubectl -n $APPLICATION_NAMESPACE get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo
    export CFILE=$PROJDIR/istio-${ASM_VERSION}/samples/httpbin/sample-client/fortio-deploy.yaml
    echo "$ cat $CFILE # to view yaml" | pv -qL 100
    cat $CFILE
    echo 
    echo "$ kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE # to deploy the FORTIO client" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE apply -f $CFILE
    echo
    echo "$ kubectl wait --for=condition=available --timeout=600s deployment --all -n $APPLICATION_NAMESPACE # to wait for the deployment to finish" | pv -qL 100
    kubectl wait --for=condition=available --timeout=600s deployment --all -n $APPLICATION_NAMESPACE
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    export FORTIO_POD=$(kubectl -n $APPLICATION_NAMESPACE get pods -lapp=fortio -o 'jsonpath={.items[0].metadata.name}') # to set environment variable for client POD.
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -curl -quiet http://${INGRESS_HOST}/productpage  | grep -o \"<title>.*</title>\" # to invoke the service with one connection and send 1 request" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -curl -quiet http://${INGRESS_HOST}/productpage | grep -o "<title>.*</title>" 
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://${INGRESS_HOST}/productpage # to invoke the service with 2 concurrent connections (-c 2) and send 20 requests (-n 20)" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://${INGRESS_HOST}/productpage
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://${INGRESS_HOST}/productpage # to invoke the service with 3 concurrent connections (-c 3) and send 30 requests (-n 30)" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://${INGRESS_HOST}/productpage
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    echo "$ kubectl apply -n $APPLICATION_NAMESPACE -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
EOF" | pv -qL 100
kubectl apply -n $APPLICATION_NAMESPACE -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
EOF
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    export FORTIO_POD=$(kubectl -n $APPLICATION_NAMESPACE get pods -lapp=fortio -o 'jsonpath={.items[0].metadata.name}') # to set environment variable for client POD.
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -curl http://${INGRESS_HOST}/productpage | grep -o \"<title>.*</title>\" # to invoke the service with one connection and send 1 request" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -curl http://${INGRESS_HOST}/productpage | grep -o "<title>.*</title>" 
    echo
    echo "$ sleep 15 # to wait for 15 secs and load test" | pv -qL 100
    sleep 15
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://${INGRESS_HOST}/productpage # to invoke the service with 2 concurrent connections (-c 2) and send 20 requests (-n 20)" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://${INGRESS_HOST}/productpage
    echo
    echo "$ sleep 15 # to wait for 15 secs and load test" | pv -qL 100
    sleep 15
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://${INGRESS_HOST}/productpage # to invoke the service with 3 concurrent connections (-c 3) and send 30 requests (-n 30)" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec -it $FORTIO_POD  -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://${INGRESS_HOST}/productpage
    echo
    echo "$ sleep 15 # to wait for 15 secs and display statistics" | pv -qL 100
    sleep 15 
    echo
    read -n 1 -s -r -p $'*** Press the Enter key to continue ***'
    echo && echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE exec $FORTIO_POD -c istio-proxy -- pilot-agent request GET stats | grep productpage | grep pending # to query the istio-proxy stats" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE exec $FORTIO_POD -c istio-proxy -- pilot-agent request GET stats | grep productpage | grep pending
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},7x"        
    echo
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete DestinationRule productpage # to delete DestinationRule" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete DestinationRule productpage
    echo
    export CFILE=$PROJDIR/istio-${ASM_VERSION}/samples/httpbin/sample-client/fortio-deploy.yaml
    echo "$ kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE # to delete FORTIO" | pv -qL 100
    kubectl -n $APPLICATION_NAMESPACE delete -f $CFILE
else
    export STEP="${STEP},7i"
    echo
    echo "1. Explore traffic management" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"R")
echo
echo "
  __                      __                              __                               
 /|            /         /              / /              /                 | /             
( |  ___  ___ (___      (___  ___        (___           (___  ___  ___  ___|(___  ___      
  | |___)|    |   )     |    |   )|   )| |    \   )         )|   )|   )|   )|   )|   )(_/_ 
  | |__  |__  |  /      |__  |__/||__/ | |__   \_/       __/ |__/||  / |__/ |__/ |__/  / / 
                                 |              /                                          
"
echo "
We are a group of information technology professionals committed to driving cloud 
adoption. We create cloud skills development assets during our client consulting 
engagements, and use these assets to build cloud skills independently or in partnership 
with training organizations.
 
You can access more resources from our iOS and Android mobile applications.

iOS App: https://apps.apple.com/us/app/tech-equity/id1627029775
Android App: https://play.google.com/store/apps/details?id=com.techequity.app

Email:support@techequity.cloud 
Web: https://techequity.cloud

Ⓒ Tech Equity 2022" | pv -qL 100
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"G")
cloudshell launch-tutorial $SCRIPTPATH/.tutorial.md
;;

"Q")
echo
exit
;;
"q")
echo
exit
;;
* )
echo
echo "Option not available"
;;
esac
sleep 1
done
