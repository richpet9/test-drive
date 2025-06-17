source(g_currentModDirectory .. "TestDriveManager.lua")
source(g_currentModDirectory .. "TestDriveData.lua")
source(g_currentModDirectory .. "TestDrive.lua")

TestDrive = {}
TestDrive.dir = g_currentModDirectory
TestDrive.modName = g_currentModName

TestDrive.initialized = false
TestDrive.buttonAdded = false
TestDrive.vehicle = nil
TestDrive.manager = nil

function TestDrive.createTestDriveButton(shopConfigScreen)
    if shopConfigScreen.testDriveButton ~= nil then
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
        TestDrive.manager:startTestDrive(shopConfigScreen.storeItem, shopConfigScreen.configurations)
    end

    return testDriveButton
end

function TestDrive.maybeAddTestDriveButton(shopConfigScreen)
    if TestDrive.manager:isTestDriveActive() or TestDrive.buttonAdded then
        return
    end

    if shopConfigScreen.testDriveButton == nil then
        shopConfigScreen.testDriveButton = TestDrive.createTestDriveButton(shopConfigScreen)
    end

    shopConfigScreen.buyButton.parent:addElement(shopConfigScreen.testDriveButton)
    TestDrive.buttonAdded = true
end
ShopConfigScreen.onVehiclesLoaded = Utils.appendedFunction(ShopConfigScreen.onVehiclesLoaded,
                                                           TestDrive.maybeAddTestDriveButton)

function TestDrive.removeTestDriveButton(shopConfigScreen)
    if TestDrive.buttonAdded == false then
        return
    end

    shopConfigScreen.testDriveButton.parent:removeElement(shopConfigScreen.testDriveButton)
    TestDrive.buttonAdded = false
    print("[DEBUG] TestDrive: Removed test drive button.")
end
ShopConfigScreen.onClose = Utils.appendedFunction(ShopConfigScreen.onClose, TestDrive.removeTestDriveButton)

function TestDrive.handleUnexpectedVehicleDelete(vehicle)
    -- This function handles if the test drive vehicle is removed by anything other than this mod.
    if TestDrive.manager.vehicle ~= nil and TestDrive.manager.vehicle:getUniqueId() == vehicle:getUniqueId() then
        if TestDrive.manager.timer:getIsRunning() then
            -- Delete was not triggered by test drive ending.
            TestDrive.manager:reset()
        end
    end
end
Vehicle.delete = Utils.prependedFunction(Vehicle.delete, TestDrive.handleUnexpectedVehicleDelete)

local function init()
    if TestDrive.initialized then
        return
    end

    TestDrive.manager = TestDriveManager.new()
    TestDrive.initialized = true
end

init()
