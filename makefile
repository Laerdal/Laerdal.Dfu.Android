android_native_folder=NordicSemiconductor/Android-DFU-Library
graddle_output=Laerdal.Xamarin.Dfu.Android/Jars
output=Laerdal.Xamarin.Dfu.Android.Output

all: $(output)

$(android_native_folder)/local.properties:
	echo "sdk.dir=$${HOME}/Library/Developer/Xamarin/android-sdk-macosx" >> $(android_native_folder)/local.properties

$(android_native_folder)/dfu/build/outputs/aar/dfu-release.aar: $(android_native_folder)/local.properties
	gradle assembleRelease -p $(android_native_folder)

$(graddle_output)/dfu-release.aar: $(android_native_folder)/dfu/build/outputs/aar/dfu-release.aar
	mkdir -p $(graddle_output)
	cp $(android_native_folder)/dfu/build/outputs/aar/dfu-release.aar $(graddle_output)/dfu-release.aar

$(output): $(graddle_output)/dfu-release.aar
	# Building nuget
	MSBuild Laerdal.Xamarin.Dfu.Android/*.csproj -t:Rebuild -restore:True -p:Configuration=Release -p:PackageOutputPath=../$(output)

clean:
	rm $(android_native_folder)/local.properties
	gradle clean -p $(android_native_folder)
	rm $(graddle_output)/dfu-release.aar
	# Cleaning MSBuild output
	MSBuild Laerdal.Xamarin.Dfu.Android/*.csproj -t:clean