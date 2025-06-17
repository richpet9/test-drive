TestDriveManager = {}
TestDriveManager.duration = 5 -- minutes.
TestDriveManager.insurancePriceThreshold = 100000
TestDriveManager.insurancePricePercent = 0.002 -- 2% total price

local TestDriverManger_mt = Class(TestDriveManager)
function TestDriveManager.new()
    self = setmetatable({}, TestDriverManger_mt)

    self.vehicle = nil
    self.timer = Timer.new(TestDriveManager.duration * 60 * 1000)
    self.timer:setFinishCallback(function()
        self:showFinishDialogAndReset()
    end)

    return self
end

function TestDriveManager:showFinishDialogAndReset()
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

    local insurancePrice = self:getInsurancePrice(storeItem, configurations)
    local shouldContinue = insurancePrice == 0

    local function purchaseInsurance(self, yes)
        if yes then
            -- TODO: deduct funds before finalizing test drive.
            self:finalizeTestDrive(storeItem, configurations)
        end
    end

    if insurancePrice > 0 then
        -- TODO format money string with l10n.
        YesNoDialog.show(purchaseInsurance, self,
                         "The dealer requires that this vehicle have insurance purchased prior to your test drive.\n" ..
                             ("They are requesting $%s for insurance.\n"):format(insurancePrice) ..
                             "Do you wish to continue?")
    else
        self:finalizeTestDrive(storeItem, configurations)
    end
end

function TestDriveManager:getInsurancePrice(storeItem, configurations)
    local buyPrice = g_currentMission.economyManager:getBuyPrice(storeItem, configurations)
    if buyPrice < TestDriveManager.insurancePriceThreshold then
        return 0
    end
    return math.ceil(buyPrice * TestDriveManager.insurancePricePercent)
end

function TestDriveManager:finalizeTestDrive(storeItem, configurations)
    self:loadVehicle(storeItem, configurations)

    local message = ("Your test drive has begun! The dealer will take back the vehicle in %s minutes."):format(
                        TestDriveManager.duration)

    InfoDialog.show(message, function()
        self.timer:setDuration(TestDriveManager.duration * 60 * 1000)
        self.timer:start()
        self.vehicle.isTestDriveVehicle = true
    end)

    TestDrive.removeTestDriveButton(g_gui.screenControllers[ShopConfigScreen])
end

function TestDriveManager:loadVehicle(storeItem, configurations)
    local data = VehicleLoadingData.new()
    data:setStoreItem(storeItem)
    data:setConfigurations(configurations)
    data:setLoadingPlace(g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces)
    data:setPropertyState(VehiclePropertyState.LEASED)
    data:setOwnerFarmId(g_localPlayer.farmId)

    data:load(function(_, loadedvehicles)
        self.vehicle = loadedvehicles[1]
    end)
end

function TestDriveManager:isTestDriveActive()
    return self.vehicle ~= nil or self.timer:getIsRunning()
end

function TestDriveManager:reset()
    self.vehicle = nil
    self.timer:reset()
end
