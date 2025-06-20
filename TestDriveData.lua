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
