# Laerdal.Dfu.Android

This is an Xamarin binding library for the Nordic Semiconductors Android library for updating the firmware of their devices over the air via Bluetooth Low Energy.

The Java library is located here: https://github.com/NordicSemiconductor/Android-DFU-Library

[![Build status](https://dev.azure.com/LaerdalMedical/Laerdal%20Nuget%20Platform/_apis/build/status/MAN-Laerdal.Dfu.Android)](https://dev.azure.com/LaerdalMedical/Laerdal%20Nuget%20Platform/_build/latest?definitionId=110)

[![NuGet Badge](https://buildstats.info/nuget/Laerdal.Dfu.Android?includePreReleases=true)](https://www.nuget.org/packages/Laerdal.Dfu.Android/)

## Requirements

You'll need :

- Windows or Mac
  - with **gradle**
  - with **Xamarin.Android**

## Steps to build

### 1) Checkout

```bash
git clone https://github.com/Laerdal/Laerdal.Dfu.Android.git
```

### 2) Run build script

To build the nuget, run :

```bash
./build.sh
```

You'll find the nuget in `Laerdal.Dfu.Android.Output/`
