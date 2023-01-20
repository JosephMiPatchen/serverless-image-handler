#!/bin/bash
#
# This assumes all of the OS-level configuration has been completed and git repo has already been cloned
#
# This script should be run from the repo's deployment directory
# cd deployment
# ./build-s3-dist.sh source-bucket-base-name trademarked-solution-name version-code
#
# For example: ./build-s3-dist.sh solutions my-solution v1.0.0
# Parameters:
#  - source-bucket-base-name: Name for the S3 bucket location where the template will source the Lambda
#    code from. The template will append '-[region_name]' to this bucket name.
#    The template will then expect the source code to be located in the solutions-[region_name] bucket
#  - trademarked-solution-name: name of the solution for consistency
#  - version-code: version of the package

[ "$DEBUG" == 'true' ] && set -x
set -e

# Check to see if input has been provided:
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Please provide the base source bucket name, trademark approved solution name and version where the lambda code will eventually reside."
    echo "For example: ./build-s3-dist.sh solutions trademarked-solution-name v1.0.0"
    exit 1
fi

function headline(){
  echo "------------------------------------------------------------------------------"
  echo "$1"
  echo "------------------------------------------------------------------------------"
}

headline "[Init] Setting up paths"
template_dir="$PWD"
template_dist_dir="$template_dir/global-s3-assets"
build_dist_dir="$template_dir/regional-s3-assets"
source_dir="$template_dir/../source"
cdk_source_dir="$source_dir/constructs"

headline "[Init] Clean old folders"
rm -rf "$template_dist_dir"
mkdir -p "$template_dist_dir"
rm -rf "$build_dist_dir"
mkdir -p "$build_dist_dir"

headline "[Package] CDK project into a CloudFormation template"
export SOLUTION_BUCKET_NAME_PLACEHOLDER=$1
export SOLUTION_NAME_PLACEHOLDER=$2
export SOLUTION_VERSION_PLACEHOLDER=$3

cd "$cdk_source_dir"
npm run clean:install
overrideWarningsEnabled=false npx cdk synth --asset-metadata false --path-metadata false --json false>"$template_dist_dir"/"$2".template

headline "[Package] Lambda binaries and copy to build_dist_dir"
cd "$source_dir"
npm run build:all
find . -mindepth 1 -maxdepth 3 -type f -iname "*.zip" -exec cp {} "$build_dist_dir" \;

headline "[Package] Serverless Image Handler Demo UI"
mkdir "$build_dist_dir"/demo-ui/
cp -r "$source_dir"/demo-ui/** "$build_dist_dir"/demo-ui/

headline "[Package] Console manifest"
cd "$source_dir"/demo-ui
manifest=($(find * -type f ! -iname ".DS_Store"))
manifest_json=$(
    IFS=,
    printf "%s" "${manifest[*]}"
)
echo "{\"files\":[\"$manifest_json\"]}" | sed 's/,/","/g' >>"$build_dist_dir"/demo-ui-manifest.json