-- This software is the intellectual property of Richard Petrosino (owner of
-- this LUA code) and GIANTS Software GmbH. (owner of the software this code
-- utelizes) as of June 2025.
--
-- This work may be reproduced and/or redstributed for non-commercial purposes
-- with the written consent of the author, Richard Petrosino. This work may
-- be reproduced and/or redstributed by GIANTS Software GmbH. for any purpose.
-- The author can be contacted at: https://github.com/richpet9
TestDrivePurchaseInsuranceEvent = {}
TestDrivePurchaseInsuranceEvent_mt = Class(TestDrivePurchaseInsuranceEvent, Event)

InitEventClass(TestDrivePurchaseInsuranceEvent, "TestDrivePurchaseInsuranceEvent")

function TestDrivePurchaseInsuranceEvent.emptyNew()
    local self = Event.new(TestDrivePurchaseInsuranceEvent_mt)
    return self
end

function TestDrivePurchaseInsuranceEvent.new(amount, farmId)
    local self = TestDrivePurchaseInsuranceEvent.emptyNew()
    self.amount = amount
    self.farmId = farmId
    return self
end

function TestDrivePurchaseInsuranceEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.amount)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function TestDrivePurchaseInsuranceEvent:readStream(streamId, connection)
    self.amount = streamReadFloat32(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self:run(connection)
end

function TestDrivePurchaseInsuranceEvent:run(connection)
    if not connection:getIsServer() then
        g_currentMission:addMoney(self.amount, self.farmId, MoneyType.LEASING_COSTS, true)
        if g_currentMission:getFarmId() == self.farmId then
            local text = g_i18n:getText("rp_TEST_DRIVE_INSURANCE")
            g_currentMission.hud:showMoneyChange(MoneyType.LEASING_COSTS, text)
        end
    else
        g_messageCenter:publish(TestDrivePurchaseInsuranceEvent.new(self.amount, self.farmid))
    end
end
