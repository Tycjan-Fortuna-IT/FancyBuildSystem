# FancyBuildSystem (FBS) for Premake C++ / C#

FancyBuildSystem (FBS) is a build configuration and dependency management system designed for use with **Premake**. It simplifies the management of platform-specific and configuration-specific build settings such as preprocessor definitions, linked libraries, include directories, and more. This system is ideal for cross-platform C++ projects, allowing you to specify dependencies and build settings in a clear, modular fashion.

## Getting Started

To start using FancyBuildSystem in your **Premake** project, include it in your premake entry file like so:

```lua
include "FancyBuildSystem/FancyBuildSystem.lua"
```

## Basic Setup

FancyBuildSystem uses **scopes** to define configuration-specific, platform-specific, and global build settings. Each scope can optionally include any of the following properties:

```lua
Defines = {
    -- List of defines to add to the project
    "DEFINE1",
    "DEFINE2",
},
LibsToLink = {
    -- List of libraries to link
    "LIB1",
    "LIB2",
},
IncludeDirs = {
    -- List of include directories
    "%{wks.location}/INCLUDE_DIR1",
    "INCLUDE_DIR2",
},
LibDirs = {
    -- List of library directories
    "LIB_DIR1",
    "LIB_DIR2",
    os.getenv("LIB_DIR3") .. "/lib",
},
```

### Configuration Support

FBS supports multiple build configurations. You can define them as follows:

```lua
FBS.Configurations = FBS.Enum { "Debug", "Release", "Dist" }
```

## Defining Dependencies

You can define dependencies for different platforms or globally. This gives you flexibility to link libraries, include directories, and apply defines based on the target platform and configuration.

### Per-Platform Dependencies

In the example below, platform-specific settings are declared for both Windows and Linux. These settings apply when building on the respective platforms:

```lua
FBS.Dependencies = {
    {
        Name = "ExampleLibrary",
        Windows = {
            Defines = {
                "WIN32_DEFINE",
            },
            LibsToLink = {
                "windows_specific_lib",
            },
            IncludeDirs = {
                "%{wks.location}/vendor/WindowsLibs",
            },
            LibDirs = {
                "libs/windows",
            },
        },
        Linux = {
            Defines = {
                "LINUX_DEFINE",
            },
            LibsToLink = {
                "linux_specific_lib",
            },
            IncludeDirs = {
                "%{wks.location}/vendor/LinuxLibs",
            },
            LibDirs = {
                "libs/linux",
            },
        },
        -- This dependency only applies in the Debug configuration
        Configurations = { FBS.Configurations.Debug }
    }
}
```

### Global Dependencies

Alternatively, you can define dependencies that apply globally, regardless of the platform. This is useful for dependencies that are shared across all platforms and configurations.

```lua
FBS.Dependencies = {
    {
        Name = "CommonLibrary",
        Defines = {
            "COMMON_DEFINE",
        },
        LibsToLink = {
            "common_lib",
        },
        IncludeDirs = {
            "%{wks.location}/vendor/CommonLibs",
        },
        LibDirs = {
            "libs/common",
        },
        -- Restrict to specific configurations (optional, all configurations by default)
        Configurations = { FBS.Configurations.Debug, FBS.Configurations.Release }
    }
}
```

### Mixing Global and Platform-Specific Dependencies

You can mix global and platform-specific dependencies in the same configuration. This allows you to define common dependencies that apply to all platforms, as well as platform-specific dependencies.

```lua
FBS.Dependencies = {
    {
        Name = "CommonLibrary",
        Defines = {
            "COMMON_DEFINE",
        },
        IncludeDirs = {
            "%{wks.location}/vendor/CommonLibs",
        },
        Windows = {
            LibsToLink = {
                "windows_common_lib",
            },
        },
        Linux = {
            LibsToLink = {
                "linux_common_lib",
            },
        },
        Configurations = { FBS.Configurations.Debug, FBS.Configurations.Release }
    },
}
```

## Using FancyBuildSystem in Your Project

Once your dependencies are defined, you can include them in your project with the following methods:

- `FBS.IncludeDependencies` - Includes dependencies for the current configuration
- `FBS.IncludeDefines` - Adds the defined preprocessor definitions for the current configuration
- `FBS.LinkDependencies` - Links the required libraries for the current configuration
- Or use the convenience method `FBS.IncludeAllDependencies` to perform all of the above in one step.

### Example Usage in a Premake Project File

Here’s how you can process the dependencies in your Premake project file for a specific configuration:

```lua
FBS.ProcessDependencies(FBS.Configurations.Debug)
```

This will include defines, link libraries, and include directories specified for the **Debug** configuration in your `FBS.Dependencies`.

### Tracy Example
```lua
{
    Name = "Tracy",
    IncludeDir = "%{wks.location}/Engine/vendor/tracy/tracy/public",
    LibsToLink = { "Tracy" },
    Windows = {
        LibsToLink = { "ws2_32", "Dbghelp" },
    },
    Linux = {
        LibsToLink = { "pthread" },
    },
},
```

## Modules
Modules allow you to group dependencies together, making it easier to manage and organize dependencies related to specific features or subsystems. To use a module, simply add the following line to your dependencies table:
```lua
FBS.ImportModule("Engine/modules/Logger");
```

In the module's `Module.lua` file, define the module as follows:

```lua
return function(basePath)
    return {
        Name = "SW Logger Module",
        LibsToLink = { "Logger" },
        IncludeDirs = {
            basePath .. "/src",
            basePath .. "/vendor/spdlog/include"
        },
    }
end
```

All paths are relative to the project root. This setup ensures that all features are supported and dependencies are correctly managed.
