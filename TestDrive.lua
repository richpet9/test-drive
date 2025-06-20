-- This software is the intellectual property of Richard Petrosino (owner of
-- this LUA code) and GIANTS Software GmbH (owner of the software this code
-- modifies) as of June 2025.
--
-- This work may be reproduced and/or redstributed for non-commercial purposes
-- with the written consent of the author, Richard Petrosino. This work may
-- be reproduced and/or redstributed by GIANTS Software GmbH. for any purpose.
-- The author can be contacted at: https://github.com/richpet9
TestDrive = {}
TestDrive.dir = g_currentModDirectory
TestDrive.modName = g_currentModName

TestDrive.isInitialized = false
TestDrive.isButtonAdded = false
TestDrive.manager = nil

ShopConfigScreen.onVehiclesLoaded = Utils.appendedFunction(ShopConfigScreen.onVehiclesLoaded, function(self)
    TestDrive.maybeAddTestDriveButton(self)
end)

ShopConfigScreen.onClose = Utils.appendedFunction(ShopConfigScreen.onClose, function(self)
    TestDrive.removeTestDriveButton(self)
end)

function TestDrive.maybeAddTestDriveButton(shopConfigScreen)
    if TestDrive.manager:isTestDriveActive() or TestDrive.isButtonAdded then
        return
    end

    local vehicle = shopConfigScreen.previewVehicles[1]
    if vehicle == nil then
        return
    end

    local isDrivable = SpecializationUtil.hasSpecialization(Drivable, vehicle.specializations)
    if TestDrive.manager.settings.onlyDrivables and not isDrivable then
        return
    end

    if shopConfigScreen.testDriveButton == nil then
        shopConfigScreen.testDriveButton = TestDrive.createTestDriveButton(shopConfigScreen)
    end

    shopConfigScreen.buyButton.parent:addElement(shopConfigScreen.testDriveButton)
    TestDrive.isButtonAdded = true
end

function TestDrive.createTestDriveButton(shopConfigScreen)
    if shopConfigScreen.testDriveButton ~= nil then
        return
    end

    local testDriveButton = shopConfigScreen.buyButton:clone(shopConfigScreen.buttonsPanel)
    testDriveButton:setText(g_i18n:getText("rp_TEST_DRIVE"))
    testDriveButton:setInputAction("MENU_EXTRA_2")
    testDriveButton.onClickCallback = function()
        TestDrive.manager:startTestDrive(shopConfigScreen.storeItem, shopConfigScreen.configurations)
    end

    return testDriveButton
end

function TestDrive.removeTestDriveButton(shopConfigScreen)
    if not TestDrive.isButtonAdded then
        return
    end

    shopConfigScreen.testDriveButton.parent:removeElement(shopConfigScreen.testDriveButton)
    TestDrive.isButtonAdded = false
end

-- This function handles if the test drive vehicle is removed by anything other than this mod.
Vehicle.delete = Utils.prependedFunction(Vehicle.delete, function(self)
    if TestDrive.manager.vehicle ~= nil and TestDrive.manager.vehicle:getUniqueId() == self:getUniqueId() then
        if TestDrive.manager:isTimerRunning() then
            -- Vehicle delete was not triggered by timer expiring, so reset everything.
            TestDrive.manager:reset()
        end
    end
end)

BaseMission.update = Utils.appendedFunction(BaseMission.update, function()
    if TestDrive.manager ~= nil then
        TestDrive.manager:update()
    end
end)

local function init()
    if TestDrive.isInitialized then
        return
    end

    local settings = TestDriveSettings.newFromXml()
    TestDrive.manager = TestDriveManager.new(settings)
    TestDrive.isInitialized = true
end

init()

