#!/bin/bash

# GITHUB INFORMATION
github_repo_owner=NordicSemiconductor
github_repo=Android-DFU-Library
github_release_id=34426039
github_info_file="$github_repo_owner.$github_repo.$github_release_id.info.json"

if [ ! -f "$github_info_file" ]; then
    echo ""
    echo "### DOWNLOADING GITHUB INFORMATION ###"
    echo ""
    github_info_file_url=https://api.github.com/repos/$github_repo_owner/$github_repo/releases/$github_release_id
    echo "Downloading $github_info_file_url to $github_info_file"
    curl -s $github_info_file_url > $github_info_file
fi


# VARIABLES
usage(){
    echo "### Wrong parameters ###"
    echo "usage: ./build.local.sh [-r|--revision build_revision]"
}

build_revision=`date +%m%d%H%M%S`

while [ "$1" != "" ]; do
    case $1 in
        -r | --revision )       shift
                                build_revision=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

echo ""
echo "### INFORMATION ###"
echo ""

# Static configuration
nuget_project_folder="Laerdal.Xamarin.Dfu.Android"
nuget_project_name="Laerdal.Xamarin.Dfu.Android"
source_folder="Laerdal.Xamarin.Dfu.Android.Source"
source_zip_folder="Laerdal.Xamarin.Dfu.Android.Zips"
test_project_folder="Laerdal.Xamarin.Dfu.Android.Test"
test_project_name="Laerdal.Xamarin.Dfu.Android.Test"

# Calculated configuration

github_tag_name=`cat $github_info_file | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' `
github_short_version=`echo "$github_tag_name" | sed 's/v//'`
build_version=$github_short_version.$build_revision
echo "##vso[build.updatebuildnumber]$build_version"

nuget_output_folder="$nuget_project_name.Output"
nuget_csproj_path="$nuget_project_folder/$nuget_project_name.csproj"
nuget_filename="$nuget_project_name.$build_version.nupkg"
nuget_output_file="$nuget_output_folder/$nuget_filename"

nuget_jars_folder="$nuget_project_folder/Jars"

source_zip_file_name="$github_short_version.zip"
source_zip_file="$source_zip_folder/$source_zip_file_name"
source_zip_url="http://github.com/$github_repo_owner/$github_repo/zipball/$github_tag_name"

test_csproj_path="$test_project_folder/$test_project_name.csproj"

# Generates variables
echo "build_version = $build_version"
echo ""
echo "github_repo_owner = $github_repo_owner"
echo "github_repo = $github_repo"
echo "github_release_id = $github_release_id"
echo "github_info_file = $github_info_file"
echo "github_tag_name = $github_tag_name"
echo "github_short_version = $github_short_version"
echo ""
echo "source_zip_folder = $source_zip_folder"
echo "source_zip_file_name = $source_zip_file_name"
echo "source_zip_file = $source_zip_file"
echo "source_zip_url = $source_zip_url"
echo ""
echo "nuget_output_folder = $nuget_output_folder"
echo "nuget_csproj_path = $nuget_csproj_path"
echo "nuget_filename = $nuget_filename"
echo "nuget_output_file = $nuget_output_file"
echo "nuget_frameworks_folder = $nuget_frameworks_folder"
echo ""
echo "sharpie_output_path = $sharpie_output_path"
echo "sharpie_output_file = $sharpie_output_file"

if [ ! -f "$source_zip_file" ]; then

    echo ""
    echo "### DOWNLOAD GITHUB RELEASE FILES ###"
    echo ""

    mkdir -p $source_zip_folder
    curl -L -o $source_zip_file $source_zip_url

    if [ ! -f "$source_zip_file" ]; then
        echo "Failed to download $source_zip_url into $source_zip_file"
        exit 1
    fi

    echo "Downloaded $source_zip_url into $source_zip_file"
fi

echo ""
echo "### UNZIP SOURCE ###"
echo ""

rm -rf $source_folder
unzip -qq -n -d "$source_folder" "$source_zip_file"
if [ ! -d "$source_folder" ]; then
    echo "Failed"
    exit 1
fi
echo "Unzipped $source_zip_file into $source_folder"


echo ""
echo "### GRADLE BUILD ###"
echo ""

gradle_base_folder=$(dirname `find ./$source_folder/ -iname "gradlew" | head -n 1`)
echo "Generating $gradle_base_folder/local.properties"
echo ""
echo "sdk.dir=$HOME/Library/Developer/Xamarin/android-sdk-macosx" > $gradle_base_folder/local.properties

#chmod +x $gradle_base_folder/gradlew
#$gradle_base_folder/gradlew dfu:assembleRelease --stacktrace --debug 
gradle assembleRelease -p $gradle_base_folder
gradle_output_file=`find ./$source_folder/ -ipath "*dfu/build/outputs/aar*" -iname "dfu-release.aar" | head -n 1`
echo ""
if [ ! -f "$gradle_output_file" ]; then
    echo "Failed : $gradle_output_file is not a file"
    exit 1
fi
echo "Built : $gradle_output_file"

echo ""
echo "### MSBUILD ###"
echo ""

rm -rf $nuget_jars_folder/dfu-release.aar
cp $gradle_output_file $nuget_jars_folder/dfu-release.aar

rm -rf $nuget_project_folder/bin
rm -rf $nuget_project_folder/obj
msbuild $nuget_csproj_path -t:Rebuild -restore:True -p:Configuration=Release -p:PackageVersion=$build_version

if [ -f "$nuget_output_file" ]; then
    echo ""
    echo "### SUCCESS ###"
    echo ""
else
    echo ""
    echo "### FAILED ###"
    echo ""
    exit 1
fi