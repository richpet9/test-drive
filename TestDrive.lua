source(g_currentModDirectory .. "TestDrive.lua")

TestDrive = {}
TestDrive.dir = g_currentModDirectory
TestDrive.modName = g_currentModName

TestDrive.initialized = false
TestDrive.vehicle = nil
TestDrive.manager = nil

ShopConfigScreen.onVehiclesLoaded = Utils.appendedFunction(ShopConfigScreen.onVehiclesLoaded, function(self)
    TestDrive.createTestDriveButton(self)
end)

ShopConfigScreen.onClose = Utils.appendedFunction(ShopConfigScreen.onClose, function(self)
    TestDrive.removeTestDriveButton(self)
end)

function TestDrive.createTestDriveButton(shopConfigScreen)
    if shopConfigScreen.testDriveButton ~= nil then
        return
    end

    if TestDrive.manager:isTestDriveActive() then
        return
    end

    local vehicle = shopConfigScreen.previewVehicles[1]
    if SpecializationUtil.hasSpecialization(Drivable, vehicle.specializations) ~= true then
        print("[DEBUG] TestDrive: Not adding button, not a drivable vehicle.")
        return
    end

    local testDriveButton = shopConfigScreen.buyButton:clone(shopConfigScreen.buttonsPanel)
    testDriveButton:setText(g_i18n:getText("rp_TEST_DRIVE"))
    testDriveButton:setInputAction("MENU_EXTRA_2")
    testDriveButton.onClickCallback = function()
        TestDrive.manager:startTestDrive(shopConfigScreen.storeItem)
    end

    shopConfigScreen.buyButton.parent:addElement(testDriveButton)
    shopConfigScreen.testDriveButton = testDriveButton
end

function TestDrive.removeTestDriveButton(shopConfigScreen)
    if shopConfigScreen.testDriveButton == nil then
        return -- Already gone.
    end
    -- TODO: remove from memory?
    shopConfigScreen.testDriveButton.parent:removeElement(shopConfigScreen.testDriveButton)
    shopConfigScreen.testDriveButton = nil
    print("[DEBUG] TestDrive: Removed test drive button.")
end

local function init()
    if TestDrive.initialized then
        return
    end

    TestDrive.manager = TestDriveManager.new()
    TestDrive.initialized = true
end

init()
