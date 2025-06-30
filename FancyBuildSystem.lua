include "SolutionItems.lua"

require "ninja/ninja"
require "compilation-database/export-compile-commands"

FBS = {
    Configurations = {},
    Dependencies = {},
    WorkspaceDirectory = os.getcwd(),
    LoadedModules = {},
}

-- Utility function for converting the first character to uppercase
function FBS.FirstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

-- Utility function for generating an enum from a list of keys
function FBS.Enum(keys)
    local Enum = {}

    for _, value in ipairs(keys) do
        Enum[value] = {}
    end

    return Enum
end

-- Utility function for checking if a given configuration is in the list of configurations
function FBS.IsInConfiguration(config)
    return table.contains(FBS.Configurations, config)
end

-- Utility function for checking if a given configuration is in a group of configurations
function FBS.IsInConfigurationGroup(configs)
    for _, config in ipairs(configs) do
        if FBS.IsInConfiguration(config) then
            return true
        end
    end

    return false
end

function AddDependencyIncludes(table)
	if table.IncludeDirs ~= nil then
		externalincludedirs { table.IncludeDirs }
	end
end

function AddDependencyDefines(table)
	if table.Defines ~= nil then
		defines { table.Defines }
	end
end

function LinkDependency(table)
	if table.LibDirs ~= nil then
		libdirs { table.LibDirs }
	end

	local libsToLink = nil

    if table.LibsToLink ~= nil then
		libsToLink = table.LibsToLink
	end

	if libsToLink ~= nil then
		links { libsToLink }

        return true
	end

	return false
end

-- Include the dependencies for the given configuration
function FBS.IncludeDependencies(deps, config)
    local target = FBS.FirstToUpper(os.target())

    for key, libraryData in pairs(deps) do

        if config == nil or libraryData.Configurations == nil or FBS.IsInConfigurationGroup(config) then
            -- Process target scope
            if libraryData[target] ~= nil then
                AddDependencyIncludes(libraryData[target])
            end

            -- Process global scope
            AddDependencyIncludes(libraryData)
        end

    end
end

-- Include the defines for the given configuration
function FBS.IncludeDefines(deps, config)
    local target = FBS.FirstToUpper(os.target())

    for key, libraryData in pairs(deps) do

        if config == nil or libraryData.Configurations == nil or FBS.IsInConfigurationGroup(config) then
            -- Process target scope
            if libraryData[target] ~= nil then
                AddDependencyDefines(libraryData[target])
            end

            -- Process global scope
            AddDependencyDefines(libraryData)
        end

    end
end

-- Link the dependencies for the given configuration
function FBS.LinkDependencies(deps, config)
    local target = FBS.FirstToUpper(os.target())

    for key, libraryData in pairs(deps) do

        if config == nil or libraryData.Configurations == nil or FBS.IsInConfigurationGroup(config) then
            -- Process target scope
            if libraryData[target] ~= nil then
                LinkDependency(libraryData[target])
            end

            -- Process global scope
            LinkDependency(libraryData)
        end

    end
end

-- Process the dependencies for the given configuration
function FBS.ProcessDependencies(config)
    FBS.IncludeDependencies(FBS.Dependencies, config)
    FBS.IncludeDefines(FBS.Dependencies, config)
    FBS.LinkDependencies(FBS.Dependencies, config)
end

-- Process the local dependencies for the given configuration
-- Instead of a gloal dependencies table, this function uses the local dependencies table
function FBS.ProcessLocalDependencies(deps, config)
    FBS.IncludeDependencies(deps, config)
    FBS.IncludeDefines(deps, config)
    FBS.LinkDependencies(deps, config)
end

function FBS.ImportModule(modulePath)
    local path = modulePath .. "/Module.lua"

    if FBS.LoadedModules[modulePath] then
        print("Module already loaded, importing: " .. modulePath)
        return FBS.LoadedModules[modulePath]
    end

    print ("Importing module: " .. path)
    if not os.isfile(path) then
        error("Module file not found: " .. path)
    end

    local module = include(path)
    if module == nil then
        error("Failed to import module: " .. path)
    end
    print("Module imported: " .. path)

    local content = module(modulePath)

    if content == nil then
        error("Module did not return any content: " .. path)
    end

    FBS.LoadedModules[modulePath] = content

    return content
end

-- Get a module by its path
function FBS.GetModule(modulePath)
    if FBS.LoadedModules[modulePath] then
        return FBS.LoadedModules[modulePath]
    else
        error("Module not found: " .. modulePath)
    end
end

-- Merge dependencies from a base table with a collection of dependency tables
-- This function will merge platform-specific dependencies and other tables like LibsToLink and IncludeDirs
function FBS.MergeDependencies(baseDeps, depsCollection)
    local target = FBS.FirstToUpper(os.target())

    for _, value in pairs(depsCollection) do
        for subKey, subValue in pairs(value) do
            if subKey ~= "Name" then
                if type(subValue) == "table" and (subKey == "Windows" or subKey == "Linux" or subKey == "Mac") then
                    -- Handle platform-specific tables
                    if subKey == target then
                        if not baseDeps[subKey] then
                            baseDeps[subKey] = {}
                        end
                        for platformKey, platformValue in pairs(subValue) do
                            if not baseDeps[subKey][platformKey] then
                                baseDeps[subKey][platformKey] = {}
                            end
                            if type(platformValue) == "table" then
                                for _, item in ipairs(platformValue) do
                                    table.insert(baseDeps[subKey][platformKey], item)
                                end
                            else
                                baseDeps[subKey][platformKey] = platformValue
                            end
                        end
                    end
                elseif type(subValue) == "table" then
                    -- Handle non-platform tables like LibsToLink and IncludeDirs
                    if not baseDeps[subKey] then
                        baseDeps[subKey] = {}
                    end
                    for _, item in ipairs(subValue) do
                        table.insert(baseDeps[subKey], item)
                    end
                end
            end
        end
    end

    return baseDeps
end
