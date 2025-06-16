TestDriveManager = {}
TestDriveManager.duration = 5 -- minutes.

local TestDriverManger_mt = Class(TestDriveManager)
function TestDriveManager.new()
    self = setmetatable({}, TestDriverManger_mt)

    self.vehicle = nil
    self.timer = Timer.new(TestDriveManager.duration * 60 * 1000)
    self.timer:setFinishCallback(function()
        self:onTimerFinish()
    end)

    return self
end

function TestDriveManager:onTimerFinish()
    InfoDialog.show("Your test drive has finished! The dealer has taken back the vehicle.", function()
        self.vehicle:delete()
        self.vehicle = nil
    end)
end

function TestDriveManager:startTestDrive(storeItem, configurations)
    if self:isTestDriveActive() then
        InfoDialog.show("You can only do one test drive at a time!")
        return
    end

    local data = VehicleLoadingData.new()
    data:setStoreItem(storeItem)
    data:setConfigurations(configurations)
    data:setLoadingPlace(g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces)
    data:setPropertyState(VehiclePropertyState.LEASED)
    data:setOwnerFarmId(g_localPlayer.farmId)

    data:load(function(_, loadedvehicles)
        self.vehicle = loadedvehicles[1]
    end)

    TestDrive.removeTestDriveButton(g_gui.screenControllers[ShopConfigScreen])

    local message = ("Your test drive has begun! The dealer will take back the vehicle in %s minutes."):format(
                        TestDriveManager.duration)
    InfoDialog.show(message, function()
        self.timer:start()
    end)
end

function TestDriveManager:isTestDriveActive()
    return self.timer:getIsRunning() and self.vehicle ~= nil
end
