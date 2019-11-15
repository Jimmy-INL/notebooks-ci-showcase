#!/bin/bash -u

NOTEBOOK_GCS_PATH="gs://notebooks-ci/demo.ipynb"
NOTEBOOK_OUT_GCS_PATH="gs://notebooks-ci/demo-out.ipynb"

gsutil cp ./demo.ipynb "${NOTEBOOK_GCS_PATH}"

UUID=$(cat /proc/sys/kernel/random/uuid)
JOB_NAME=$(echo "demo-nb-run-${UUID}" | tr '-' '_')
REGION="us-central1"
IMAGE_NAME=$(<container_uri)
gcloud ai-platform jobs submit training "${JOB_NAME}" \
  --region "${REGION}" \
  --master-image-uri "${IMAGE_NAME}" \
  -- nbexecutor \
  --input-notebook "${NOTEBOOK_GCS_PATH}" \
  --output-notebook "${NOTEBOOK_OUT_GCS_PATH}"


while [[ $(gcloud ai-platform jobs describe "${JOB_NAME}" | grep "PREPARING") ]]
do
    echo "still preparing"
    sleep 10
done

while [[ $(gcloud ai-platform jobs describe "${JOB_NAME}" | grep "RUNNING") ]]
do
    echo "still running"
    sleep 10
done

if [[  $(gcloud ai-platform jobs describe "${JOB_NAME}" | grep "SUCCEEDED") ]]; then
    exit 0
else
    exit 1
fi