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
    InfoDialog.show(g_i18n:getText("rp_TEST_DRIVE_END"), function()
        self.vehicle:delete()
        self.vehicle = nil
    end)
end

function TestDriveManager:startTestDrive(storeItem, configurations)
    if g_client == nil or g_localPlayer == nil then
        return -- Only the client should reach this state.
    end

    if self:isTestDriveActive() then
        InfoDialog.show(g_i18n:getText("rp_TEST_DRIVE_LIMIT"))
        return
    end

    local insurancePrice = self:getInsurancePrice(storeItem, configurations)
    local buyVehicleData = self:getBuyVehicleData(storeItem, configurations, insurancePrice)

    local function purchaseInsurance(self, yes)
        if yes then
            -- TODO: Move into an event for multiplayer support.
            local text = g_i18n:getText("rp_TEST_DRIVE_INSURANCE")
            g_currentMission:addMoney(-insurancePrice, g_localPlayer.farmId, MoneyType.LEASING_COSTS, true)
            g_currentMission.hud:showMoneyChange(MoneyType.LEASING_COSTS, text)
            self:finalizeTestDrive(buyVehicleData)
        end
    end

    if insurancePrice > 0 then
        local insuranceRequired = g_i18n:getText("rp_TEST_DRIVE_INSURANCE_REQUIRED")
        local insuranceRequest = g_i18n:getText("rp_TEST_DRIVE_INSURANCE_REQUEST"):format(insurancePrice)
        local insuranceContinue = g_i18n:getText("rp_TEST_DRIVE_INSURANCE_CONTINUE")

        YesNoDialog.show(purchaseInsurance, self,
                         ("%s\n%s\n%s"):format(insuranceRequired, insuranceRequest, insuranceContinue))
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

        local message = g_i18n:getText("rp_TEST_DRIVE_BEGIN"):format(self.settings.duration)

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
    return self.vehicle ~= nil or self:isTimerRunning()
end

function TestDriveManager:reset()
    self.vehicle = nil
    self.timer:reset()
end

function TestDriveManager:startTimer()
    self.timer:start()
end

function TestDriveManager:setTimerDuration(duration)
    self.timer:setDuration(duration)
end

function TestDriveManager:getTimeLeft()
    return self.timer.timeLeft
end

function TestDriveManager:isTimerRunning()
    return self.timer:getIsRunning()
end
