# Laerdal.Xamarin.Dfu.Android

This is an Xamarin binding library for the Nordic Semiconductors Android library for updating the firmware of their devices over the air via Bluetooth Low Energy.
The Java library is located here: https://github.com/NordicSemiconductor/Android-DFU-Library

[![Build status](https://dev.azure.com/LaerdalMedical/Healthcare%20Responders/_apis/build/status/Github/Laerdal.Xamarin.Dfu.Android)](https://dev.azure.com/LaerdalMedical/Healthcare%20Responders/_build/latest?definitionId=100)
[![NuGet Badge](https://buildstats.info/nuget/Laerdal.Xamarin.Dfu.Android)](https://www.nuget.org/packages/Laerdal.Xamarin.Dfu.Android/)

## Folder structure

- NordicSemiconductor/Android-DFU-Library = Submodule containing [Nordic's code](https://github.com/NordicSemiconductor/Android-DFU-Library)
- Laerdal.Xamarin.Dfu.Android = Xamarin Java Binding Library project and nuget files
- Laerdal.Xamarin.Dfu.Android.Output = Build output from building *Laerdal.Xamarin.Dfu.Android*

## Local build

### Requirements

You'll need :

- Windows or Mac
  - with **gradle**
  - with **Xamarin.Android** (obviously)

### Steps to build

#### 1) Checkout with submodule

```bash
git clone --recurse-submodules https://github.com/Laerdal/Laerdal.Xamarin.Dfu.Android.git
```

Feel free to update the submodule reference / Pull to the latest release from Nordic.

#### 2) Run **make**

There is a *makefile* included that does everything for you, feel free to read it to know more.

To use it simply run :

```bash
make
```

### Clean

To clean the output files and restart the process run :

```bash
make clean
```
