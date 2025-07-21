-- This software is the intellectual property of Richard Petrosino (owner of
-- this LUA code) and GIANTS Software GmbH (owner of the software this code
-- modifies) as of June 2025.
--
-- This work may be reproduced and/or redstributed for non-commercial purposes
-- with the written consent of the author, Richard Petrosino. This work may
-- be reproduced and/or redstributed by GIANTS Software GmbH. for any purpose.
-- The author can be contacted at: https://github.com/richpet9
TestDriveSettings = {}

-- These are overridden by the modSettings/testDriveSettings.xml file, if those values are valid.
TestDriveSettings.DEFAULT = {
    duration = 2, -- minutes.
    insuranceThreshold = 100000,
    insuranceRatio = 0.003, -- 0.3% of total price.
    onlyDrivables = true,
}

TestDriveSettings.attemptedXmlLoad = false

local TestDriveSettings_mt = Class(TestDriveSettings)

function TestDriveSettings.new(settings)
    self = setmetatable({}, TestDriveSettings_mt)

    self.duration = settings.duration
    self.insuranceThreshold = settings.insuranceThreshold
    self.insuranceRatio = settings.insuranceRatio
    self.onlyDrivables = settings.onlyDrivables

    return self
end

function TestDriveSettings.newFromXml()
    if TestDriveSettings.attemptedXmlLoad then
        return -- Already initialized settings, or attempted to.
    end

    TestDriveSettings.attemptedXmlLoad = true

    local xmlFile = TestDriveSettings.getOrCreateXmlFile()
    local settings = {
        duration = nil,
        insuranceThreshold = nil,
        insuranceRatio = nil,
     }

    if xmlFile then
        settings.duration = getXMLInt(xmlFile, "testDriveSettings.duration")
        settings.insuranceThreshold = getXMLInt(xmlFile, "testDriveSettings.insuranceThreshold")
        settings.insuranceRatio = getXMLFloat(xmlFile, "testDriveSettings.insuranceRatio")
        settings.onlyDrivables = getXMLBool(xmlFile, "testDriveSettings.onlyDrivables")
        delete(xmlFile) -- From memory, not disk.
    end

    if settings.duration == nil then
        settings.duration = TestDriveSettings.DEFAULT.duration
    end

    if settings.insuranceThreshold == nil then
        settings.insuranceThreshold = TestDriveSettings.DEFAULT.insuranceThreshold
    end

    if settings.insuranceRatio == nil then
        settings.insuranceRatio = TestDriveSettings.DEFAULT.insuranceRatio
    end

    if settings.onlyDrivables == nil then
        settings.onlyDrivables = TestDriveSettings.DEFAULT.onlyDrivables
    end

    print(
        ("[DEBUG] TestDriveSettings: Loaded settings (duration=%s, insuranceThreshold=%s, insuranceRatio=%s, onlyDrivables=%s)"):format(
            settings.duration, settings.insuranceThreshold, settings.insuranceRatio, settings.onlyDrivables))

    return TestDriveSettings.new(settings)
end

function TestDriveSettings.saveToXml(settings, xml)
    local xmlFile = xml or TestDriveSettings.getXmlFile()

    setXMLInt(xmlFile, "testDriveSettings.duration", settings.duration)
    setXMLInt(xmlFile, "testDriveSettings.insuranceThreshold", settings.insuranceThreshold)
    setXMLFloat(xmlFile, "testDriveSettings.insuranceRatio", settings.insuranceRatio)
    setXMLBool(xmlFile, "testDriveSettings.onlyDrivables", settings.onlyDrivables)

    saveXMLFile(xmlFile)
end

function TestDriveSettings.getOrCreateXmlFile()
    local xmlFilePath = TestDriveSettings.getXmlFilePath()
    if xmlFilePath ~= nil then
        local xmlFile = nil
        if not fileExists(xmlFilePath) then
            return TestDriveSettings.createNewSettingsXmlFile(xmlFilePath)
        end

        return TestDriveSettings.getXmlFile()
    end
end

--- Returns the XML file object, or nil.
function TestDriveSettings.getXmlFile()
    local xmlFilePath = TestDriveSettings.getXmlFilePath()

    if xmlFilePath ~= nil then
        if not fileExists(xmlFilePath) then
            print("[DEBUG] TestDriveSettings: Attempted to open non-existent XML File: " .. xmlFilePath)
            return
        end

        return loadXMLFile("testDriveSettings", xmlFilePath)
    end
end

function TestDriveSettings.getXmlFilePath()
    if g_dedicatedServerInfo == nil then
        return Utils.getFilename("modSettings/testDriveSettings.xml", getUserProfileAppPath())
    end
    print("[DEBUG] TestDriveSettings: Failed to load from XML, filePath failed to build. Is this a server?")
end

function TestDriveSettings.createNewSettingsXmlFile(xmlFilePath)
    local xmlFilePath = TestDriveSettings.getXmlFilePath()
    local xmlFile = createXMLFile("testDriveSettings", xmlFilePath, "testDriveSettings")

    TestDriveSettings.saveToXml(TestDriveSettings.DEFAULT, xmlFile)

    return xmlFile
end
