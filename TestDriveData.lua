-- This software is the intellectual property of Richard Petrosino (owner of
-- this LUA code) and GIANTS Software GmbH (owner of the software this code
-- modifies) as of June 2025.
--
-- This work may be reproduced and/or redstributed for non-commercial purposes
-- with the written consent of the author, Richard Petrosino. This work may
-- be reproduced and/or redstributed by GIANTS Software GmbH. for any purpose.
-- The author can be contacted at: https://github.com/richpet9
Vehicle.registers = Utils.appendedFunction(Vehicle.registers, function()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)#isTestDrive", "Is the vehicle a test drive")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#testDriveTimeLeft", "Test drive time left")
end)

Vehicle.load = Utils.appendedFunction(Vehicle.load, function(self)
    local savegame = self.savegame
    if savegame ~= nil then
        local isTestDriveVehicle = savegame.xmlFile:getValue(savegame.key .. "#isTestDrive", false)
        local testDriveTimeLeft = savegame.xmlFile:getValue(savegame.key .. "#testDriveTimeLeft", nil)
        if isTestDriveVehicle and testDriveTimeLeft then
            self.isTestDriveVehicle = true
            TestDrive.manager.vehicle = self
            TestDrive.manager:setTimerDuration(testDriveTimeLeft)
            TestDrive.manager:startTimer()
        end
        self.isTestDriveVehicle = false
    end
end)

Vehicle.saveToXMLFile = Utils.appendedFunction(Vehicle.saveToXMLFile, function(self, xmlFile, key, _)
    if self.isTestDriveVehicle then
        xmlFile:setValue(key .. "#isTestDrive", true)
        xmlFile:setValue(key .. "#testDriveTimeLeft", TestDrive.manager:getTimeLeft())
    end
end)
