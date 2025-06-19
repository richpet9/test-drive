TestDriveManager = {}

local TestDriverManger_mt = Class(TestDriveManager)

function TestDriveManager.new(settings)
    self = setmetatable({}, TestDriverManger_mt)

    self.settings = settings
    self.vehicle = nil
    self.timer = Timer.new(self.settings.duration * 60 * 1000)
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
    if g_client == nil then
        return -- Only the client should reach this state.
    end

    if self:isTestDriveActive() then
        InfoDialog.show("You can only do one test drive at a time!")
        return
    end

    local insurancePrice = self:getInsurancePrice(storeItem, configurations)
    local buyVehicleData = self:getBuyVehicleData(storeItem, configurations, insurancePrice)

    local function doTestDrive(self, yes)
        if yes then
            self:finalizeTestDrive(buyVehicleData)
        end
    end

    if insurancePrice > 0 then
        -- TODO format money string with l10n.
        YesNoDialog.show(doTestDrive, self,
                         "The dealer requires that this vehicle have insurance purchased prior to your test drive.\n" ..
                             ("They are requesting $%s for insurance.\n"):format(insurancePrice) ..
                             "Do you wish to continue?")
    else
        self:finalizeTestDrive(buyVehicleData)
    end
end

function TestDriveManager:getInsurancePrice(storeItem, configurations)
    local buyPrice = g_currentMission.economyManager:getBuyPrice(storeItem, configurations)
    if buyPrice < self.settings.insuranceThreshold then
        return 0
    end
    return math.ceil(buyPrice * self.settings.insuranceRatio)
end

function TestDriveManager:finalizeTestDrive(buyVehicleData)
    if g_client == nil then
        return -- Only the client should reach this state.
    end

    buyVehicleData.onBought = function(data, boughtVehicles)
        self.vehicle = boughtVehicles[1]

        local message = ("Your test drive has begun! The dealer will take back the vehicle in %s minutes."):format(
                            self.settings.duration)

        InfoDialog.show(message, function()
            self.timer:setDuration(self.settings.duration * 60 * 1000)
            self.timer:start()
            self.vehicle.isTestDriveVehicle = true
        end)

        TestDrive.removeTestDriveButton(g_gui.screenControllers[ShopConfigScreen])
    end

    g_client:getServerConnection():sendEvent(BuyVehicleEvent.new(buyVehicleData, buyCallback))
end

function TestDriveManager:getBuyVehicleData(storeItem, configurations, insurancePrice, callback)
    local data = BuyVehicleData.new()
    data:setStoreItem(storeItem)
    data:setConfigurations(configurations)
    data:setIsFreeOfCharge(insurancePrice <= 0)
    data:setPrice(insurancePrice)
    data:setLeaseVehicle(true)
    data:setOwnerFarmId(g_localPlayer.farmId)
    return data
end

function TestDriveManager:isTestDriveActive()
    return self.vehicle ~= nil or self.timer:getIsRunning()
end

function TestDriveManager:reset()
    self.vehicle = nil
    self.timer:reset()
end
