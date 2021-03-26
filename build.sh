#!/bin/bash

build_revision=`date +%-m%d%H%M%S`

usage(){
    echo "usage: ./build.sh [-r|--revision build_revision] [-c|--clean-output] [-v|--verbose] [-o|--output path]"
    echo "parameters:"
    echo "  -r | --revision [build_revision]        Sets the revision number, default = mddhhMMSS ($build_revision)"
    echo "  -c | --clean-output                     Cleans the output before building"
    echo "  -v | --verbose                          Enable verbose build details from msbuild and gradle tasks"
    echo "  -o | --output [path]                    Output path"
    echo "  -h | --help                             Prints this message"
}

while [ "$1" != "" ]; do
    case $1 in
        -r | --revision )       shift
                                build_revision=$1
                                ;;
        -o | --output )         shift
                                output_path=$1
                                ;;
        -c | --clean-output )   clean_output=1
                                ;;
        -v | --verbose )        verbose=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     echo "### Wrong parameter: $1 ###"
                                usage
                                exit 1
    esac
    shift
done


# find the latest ID here : https://api.github.com/repos/NordicSemiconductor/Android-DFU-Library/releases/latest
github_repo_owner=NordicSemiconductor
github_repo=Android-DFU-Library
github_release_id=34426039
github_info_file="$github_repo_owner.$github_repo.$github_release_id.info.json"

if [ ! -f "$github_info_file" ]; then
    echo
    echo "### DOWNLOAD GITHUB INFORMATION ###"
    echo
    github_info_file_url=https://api.github.com/repos/$github_repo_owner/$github_repo/releases/$github_release_id
    echo "Downloading $github_info_file_url to $github_info_file"
    curl -s $github_info_file_url > $github_info_file
fi

echo
echo "### INFORMATION ###"
echo

# Set version
github_tag_name=`cat $github_info_file | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' `
github_short_version=`echo "$github_tag_name" | sed 's/v//'`
build_version=$github_short_version.$build_revision
echo "##vso[build.updatebuildnumber]$build_version"
if [ -z "$github_short_version" ]; then
    echo "Failed : Could not read Version"
    cat $github_info_file
    exit 1
fi

# Static configuration
nuget_project_folder="Laerdal.Dfu.Droid"
nuget_project_name="Laerdal.Dfu.Droid"
nuget_output_folder="$nuget_project_name.Output"
nuget_csproj_path="$nuget_project_folder/$nuget_project_name.csproj"
nuget_filename="$nuget_project_name.$build_version.nupkg"
nuget_output_file="$nuget_output_folder/$nuget_filename"

nuget_jars_folder="$nuget_project_folder/Jars"

source_folder="Laerdal.Dfu.Droid.Source"
source_zip_folder="Laerdal.Dfu.Droid.Zips"
source_zip_file_name="$github_short_version.zip"
source_zip_file="$source_zip_folder/$source_zip_file_name"
source_zip_url="http://github.com/$github_repo_owner/$github_repo/zipball/$github_tag_name"

# Generates variables
echo "build_version = $build_version"
echo
echo "github_repo_owner = $github_repo_owner"
echo "github_repo = $github_repo"
echo "github_release_id = $github_release_id"
echo "github_info_file = $github_info_file"
echo "github_tag_name = $github_tag_name"
echo "github_short_version = $github_short_version"
echo
echo "source_folder = $source_folder"
echo "source_zip_folder = $source_zip_folder"
echo "source_zip_file_name = $source_zip_file_name"
echo "source_zip_file = $source_zip_file"
echo "source_zip_url = $source_zip_url"
echo
echo "nuget_project_folder = $nuget_project_folder"
echo "nuget_output_folder = $nuget_output_folder"
echo "nuget_project_name = $nuget_project_name"
echo "nuget_jars_folder = $nuget_jars_folder"
echo "nuget_csproj_path = $nuget_csproj_path"
echo "nuget_filename = $nuget_filename"
echo "nuget_output_file = $nuget_output_file"

if [ "$clean_output" = "1" ]; then

    echo
    echo "### CLEAN OUTPUT ###"
    echo
    rm -rf $nuget_output_folder
    echo "Deleted : $nuget_output_folder"
fi

if [ ! -f "$source_zip_file" ]; then

    echo
    echo "### DOWNLOAD GITHUB RELEASE FILES ###"
    echo

    mkdir -p $source_zip_folder
    curl -L -o $source_zip_file $source_zip_url

    if [ ! -f "$source_zip_file" ]; then
        echo "Failed to download $source_zip_url into $source_zip_file"
        exit 1
    fi

    echo "Downloaded $source_zip_url into $source_zip_file"
fi

echo
echo "### UNZIP SOURCE ###"
echo

rm -rf $source_folder
unzip -qq -n -d "$source_folder" "$source_zip_file"
if [ ! -d "$source_folder" ]; then
    echo "Failed"
    exit 1
fi
echo "Unzipped $source_zip_file into $source_folder"

echo
echo "### GRADLE BUILD ###"
echo

gradle_base_folder=$(dirname `find ./$source_folder/ -iname "gradlew" | head -n 1`)
echo "sdk.dir=$HOME/Library/Developer/Xamarin/android-sdk-macosx" > $gradle_base_folder/local.properties

if [ -f "$gradle_base_folder/local.properties" ]; then
    echo "Created :"
    echo "  - $gradle_base_folder/local.properties"
    echo
else
    echo "Failed : Can't create '$gradle_base_folder/local.properties'"
    exit 1
fi

#chmod +x $gradle_base_folder/gradlew
#$gradle_base_folder/gradlew dfu:assembleRelease --stacktrace --debug 
gradle assembleRelease -p $gradle_base_folder
gradle_output_file=`find ./$source_folder/ -ipath "*dfu/build/outputs/aar*" -iname "dfu-release.aar" | head -n 1`
echo

if [ -f "$gradle_output_file" ]; then
    echo "Created :"
    echo "  - $gradle_output_file"
    rm -rf $nuget_frameworks_folder
else
    echo "Failed : Can't find '$gradle_output_file'"
    exit 1
fi

echo
echo "### COPY AAR FILE ###"
echo

echo "Copying $gradle_output_file to $nuget_jars_folder/dfu-release.aar"
rm -rf $nuget_jars_folder/dfu-release.aar
mkdir -p $nuget_jars_folder
cp $gradle_output_file $nuget_jars_folder/dfu-release.aar

echo
echo "### MSBUILD ###"
echo

msbuild_parameters=""
if [ ! "$verbose" = "1" ]; then
    msbuild_parameters="${msbuild_parameters} -nologo -verbosity:quiet"
fi
msbuild_parameters="${msbuild_parameters} -t:Rebuild"
msbuild_parameters="${msbuild_parameters} -restore:True"
msbuild_parameters="${msbuild_parameters} -p:Configuration=Release"
msbuild_parameters="${msbuild_parameters} -p:PackageVersion=$build_version"
echo "msbuild_parameters = $msbuild_parameters"
echo

rm -rf $nuget_project_folder/bin
rm -rf $nuget_project_folder/obj
msbuild $nuget_csproj_path $msbuild_parameters

if [ -f "$nuget_output_file" ]; then
    echo "Created :"
    echo "  - $nuget_output_file"
    echo
    rm -rf $nuget_frameworks_folder
else
    echo "Failed : Can't find '$nuget_output_file'"
    exit 1
fi

if [ ! -z "$output_path" ]; then

    echo
    echo "### COPY FILES TO OUTPUT ###"
    echo

    mkdir -p $output_path
    cp -a $(dirname $nuget_output_file)/. $output_path

    echo "Copied into $output_path"
fi