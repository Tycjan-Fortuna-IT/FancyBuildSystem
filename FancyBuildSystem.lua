include "SolutionItems.lua"
include "PropertyTags.lua"

FBS = {
    Configurations = {},
    Dependencies = {},
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
function FBS.IncludeDependencies(config)
    local target = FBS.FirstToUpper(os.target())

    for key, libraryData in pairs(FBS.Dependencies) do

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
function FBS.IncludeDefines(config)
    local target = FBS.FirstToUpper(os.target())

    for key, libraryData in pairs(FBS.Dependencies) do

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
function FBS.LinkDependencies(config)
    local target = FBS.FirstToUpper(os.target())

    for key, libraryData in pairs(FBS.Dependencies) do

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
    FBS.IncludeDependencies(config)
    FBS.IncludeDefines(config)
    FBS.LinkDependencies(config)
end

function FBS.ImportModule(modulePath)
    local module = include(modulePath .. "/Module.lua")("%{wks.location}/" .. modulePath)

    return module;
end
