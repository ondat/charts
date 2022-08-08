# This script takes the current state of the working branch and updates the ./azure-package/ directory
# With an updated azure bundle. See for more info: https://github.com/Azure/containersmarketplace_ext/blob/main/packaging-container-app.md
# It takes some files from the azure/ directory as input, as well as the charts
# WARNING: this file is not good. However it is also not high enough priority for me to improve.

# We need to delete the kubeScheduler key if it exists
# As that image is set dynamically by the operator based on the orchestrator version
# And the blank defaults will confuse the bundle builder
yq e -i "del(.images.kubeScheduler)" ./charts/component-charts/ondat-operator/values.yaml

for f in ./charts/component-charts/etcd-cluster-operator/values.yaml ./charts/component-charts/ondat-operator/values.yaml; do
  # Create an array of the keys in the '.images' map
  readarray image_keys< <(yq e -r -I=0 '.images | keys | .[] ' "$f")

  for image_key in "${image_keys[@]}"; do
    registry=$(yq e ".images.$image_key.registry" "$f")
    image=$(yq e ".images.$image_key.image" "$f")
    tag=$(yq e ".images.$image_key.tag" "$f")
    url=$registry/$image:$tag
    echo "Getting digest for image: $url"

    # Pulling the image as there's seemingly no registry-agnostic way of getting the remote digest
    docker pull "$url"
    repo_digest=$(docker inspect --format='{{index .RepoDigests 0}}' "$url")
    # Get the bit after the image url (after the '@')
    digest=${repo_digest#*@}
    echo "Got digest: $digest"
    yq e -i ".images.$image_key.digest=\"$digest\"" "$f"
  done

  # move the images to under .global.azure
  yq e -i '.global.azure.images=.images | del(.images)' "$f"

  # azure requires all images to be defined in all values files
  # so create a tmp file for addition to the umbrella chart
  yq e ".global.azure" "$f" >> tmp.yaml
done

# Add the contents of the tmp file (all images) to the umbrella values file
yq e -i '. * load("tmp.yaml")' ./charts/umbrella-charts/ondat/values.yaml
yq e -i '.global.azure.images=.images | del(.images)' ./charts/umbrella-charts/ondat/values.yaml
rm tmp.yaml

# Update the templates to use the new values
sed -i charts/*/*/templates/* -e 's/.Values.images./.Values.global.azure.images./g'
# This may not be needed
sed -i charts/*/*/templates/* -e 's/\.tag/\.digest/g'
# Revert the change for the etcd version as that's weird at this moment in time
sed -i charts/*/*/templates/* -e 's/{{ trimPrefix "v" .Values.images.etcd.digest }}/{{ trimPrefix "v" .Values.images.etcd.tag }}/g'

mkdir azure-package
cp azure/createUIDefinition.json azure-package/
cp azure/manifest.yaml azure-package/

# point the umbrella chart at the local, modified versions of the component charts
# '2g' is needed to replace the second instance, -z is needed to treat the file as one line
# This is very fragile, I'm not spending more time improving it though
sed -i -z charts/umbrella-charts/ondat/Chart.yaml -e 's/repository: https:\/\/ondat.github.io\/charts/repository: "file:\/\/..\/..\/component-charts\/etcd-cluster-operator"/2g'
sed -i -z charts/umbrella-charts/ondat/Chart.yaml -e 's/repository: https:\/\/ondat.github.io\/charts/repository: "file:\/\/..\/..\/component-charts\/ondat-operator"/1g'

helm dependency update charts/umbrella-charts/ondat
cp -r charts azure-package/
