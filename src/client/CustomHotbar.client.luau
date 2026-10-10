--==================================================
-- POTATIUM LEGACY HOTBAR - RETIRED
--
-- The draggable hotbar now lives inside:
--   InventoryClient.client.luau
--
-- Keep this file as a harmless stub so old copies of
-- this script do not create a duplicate hotbar or
-- compete for 1-8 keyboard input.
--
-- In Roblox Studio, you can disable/delete the old
-- CustomHotbar LocalScript after replacing the inventory
-- script with the new combined version.
--==================================================

local StarterGui = game:GetService("StarterGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

print("Potatium: legacy CustomHotbar is retired; use the combined draggable InventoryClient.")
