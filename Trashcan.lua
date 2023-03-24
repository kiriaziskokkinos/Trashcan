-- ==============================================================
-- ------- Trash Can -------
-- Mod Date:	3.7.09
-- Author:	Wortahk
-- Desc: 	Added slashcmd to toggle Trashcan feature
-- Usage:  	/tc <on> <off> <status> <count> <list> <purge>
-- ==============================================================
MyAddon = { }
local frame = CreateFrame("Frame")
-- trigger event with /reloadui or /rl

frame:SetScript("OnEvent", function(this, event, ...)
    MyAddon[event](MyAddon, ...)
end)










-- Functions
function Load_Trashcan()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("LOOT_CLOSED")
	this:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function Trashcan_OnEvent()
	if (event == "ADDON_LOADED" and arg1 == "Trashcan") then
		if not Config then
			Config = {}
			print("Trashcan Initialized")
		end

		if type(Config["status"]) ~= "boolean" then

			Config["status"] = true
		end
		if type(Config["trash"]) ~= "boolean" then
			Config["trash"] = true
		end
		if not Config["UnwantedItemList"] then
			Config["UnwantedItemList"] = {}
		end

		if type(Config["autoreport"]) ~= "boolean" then
			Config["autoreport"] = true
		end



		local check = next(Config["UnwantedItemList"])
		if Config["UnwantedItemList"][check] and type(Config["UnwantedItemList"][check]) == "boolean" then
			print("Old SaveVariable format detected, converting...")
			for i in pairs(Config["UnwantedItemList"]) do 
	
				local item = Item:CreateFromID(i)
				item:ContinueOnLoad(
					function() 
						SlashCmdList.TC("remove "..i)
						SlashCmdList.TC("add "..i) 
					end
				)
			end
		end



	elseif (event == "LOOT_CLOSED" or ( event == "UNIT_INVENTORY_CHANGED" and arg1 == "player")) then
		TrashcanMainFrame:Show()
	end
end

function Trashcan_OnUpdate(self, elapsed)
self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
	while (self.TimeSinceLastUpdate > 1.5) do
		DestroyJunk()
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate - 1.5;
	end
end

function tc_Init()
  -- Add Slash Commands
	-- print("Trashcan Slash cmd Loaded!")
  SlashCmdList["TC"] = tc_toggle;
  SLASH_TC1 = "/tc";
end

function tc_toggle(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if (not cmd) then 
		print("Trashcan Commands:\n",
			"/tc on/off : Enabled or disables Trashcan\n",
			"/tc trash on/off : Enabled or disables auto deletion of trash items.\n",
			"/tc status : Shows if trashcan is enabled or disabled.\n",
			"/tc count : Shows the amount of unwanted items in your inventory.\n",
			"/tc list : Displays a list of all unwanted items in your inventory.\n",
			"/tc purge : Deletes all unwanted items in your inventory.\n",
			"/tc add itemID : Adds the itemID specified to the list of unwanted items.\n",
			"/tc remove itemID : Removes the itemID specified from the list of unwanted items.\n",
			"/tc dump : Displays the list of manually added itemIDs.\n",
			"/tc autoreport on/off : Toggle the report of automatic deletion."

		)
	elseif (cmd == "off") then
		Config["status"] = false
		print("Trashcan:  DISABLED!")
	elseif (cmd == "on") then
		Config["status"] = true
		print("Trashcan:  ENABLED!")
	elseif (cmd == "status") then

		print("---- Trashcan status report ----")

		if (Config["status"]) then
			print("Trashcan is currently ENABLED.")
		else
			print("Trashcan is currently DISABLED.")
		end
	
		if (Config["trash"]) then
			print("Trashcan will delete trash items.")
		else
			print("Trashcan will *NOT* delete trash items.")
		end

		if (Config["autoreport"]) then
			print("Trashcan will report automatic deletion.")
		else
			print("Trashcan will *NOT* report automatic deletion.")
		end



		print("--------------------------------")


	elseif (cmd == "count") then
		--start searching bags for gray level item(s) to count
		local bag, slot, link, quality
		local listCount = 0
		for bag = 0,4 do
			for slot = 1,GetContainerNumSlots(bag) do
				link = GetContainerItemLink(bag, slot)
				if (link) then
					_, _, quality = GetItemInfo(link)
					local itemID = GetItemInfoFromHyperlink(link)
					if (quality == 0 and Config["trash"]) or Config["UnwantedItemList"][tostring(itemID)] then
						listCount = listCount + 1
						--PickupContainerItem(bag, slot)
						--DeleteCursorItem()
					end
				end
			end
		end
		print("Total Items: "..tostring(listCount));
	elseif (cmd == "list") then
		local totalItems = 0
		--start searching bags for gray level item(s) to list
		local bag, slot, link, quality
		for bag = 0,4 do
			for slot = 1,GetContainerNumSlots(bag) do
				link = GetContainerItemLink(bag, slot)
				if (link) then
					_, _, quality = GetItemInfo(link)
					local itemID = GetItemInfoFromHyperlink(link)
					if (quality == 0 and Config["trash"])  or Config["UnwantedItemList"][tostring(itemID)] then
					totalItems = totalItems + 1
					DEFAULT_CHAT_FRAME:AddMessage("Item found:"..link,1,0,0)
					end
				end
			end
		end
		if (totalItems == 0) then
			print("No items found.")
		end
	elseif (cmd == "purge") then
		local iCounter = 0
		local bag, slot, link, quality
		for bag = 0,4 do
			for slot = 1,GetContainerNumSlots(bag) do
			link = GetContainerItemLink(bag, slot)
				if (link) then
					_, _, quality = GetItemInfo(link)
					local itemID = GetItemInfoFromHyperlink(link)
					if (quality == 0 and Config["trash"]) or Config["UnwantedItemList"][tostring(itemID)] then
						iCounter = iCounter + 1
						DEFAULT_CHAT_FRAME:AddMessage("Destroyed: "..link,1,0,0)
						PickupContainerItem(bag, slot)
						DeleteCursorItem()
					end
				end
			end
		end			
		if (iCounter == 0) then
			print("No items to purge.")
		end	
	elseif (cmd == "add") and args ~= "" then
		if Config["UnwantedItemList"][args] then 
			print("Item is already in the list.")
		else
			local  link =  select (2,GetItemInfo(args))
			if link then 
				Config["UnwantedItemList"][args] = link
				print(args.." added to the list.")
			else
				print("Invalid item")
			end
		end
	elseif (cmd == "remove") and args ~= "" then
		if Config["UnwantedItemList"][args] then 
			Config["UnwantedItemList"][args] = nil
			print(args.." removed from the list.")
		else
			print("Item is not in the list.")
		end
	elseif (cmd == "trash") and args =="on" then
		Config["trash"] = true
		print("Trashcan will now automatically delete trash items!")

	elseif (cmd == "trash") and args =="off" then
		Config["trash"] = false
		print("Trashcan will no longer automatically delete trash items!")

	elseif (cmd == "dump") then
		for i in pairs(Config["UnwantedItemList"]) do
			print(i, Config["UnwantedItemList"][i])
		end


	elseif (cmd == "autoreport") and args =="on" then
		Config["autoreport"] = true
		print("Trashcan will report automatic deletion of items.")

	elseif (cmd == "autoreport") and args =="off" then
		Config["autoreport"] = false
		print("Trashcan will *NOT* report automatic deletion of items.")

	end



end

function DestroyJunk()

if (Config["status"] == false) then
--do nothing because the Trashcan was disabled

else
--start searching bags for gray level item(s) to purge
	local bag, slot, link, quality
	for bag = 0,4 do
		for slot = 1,GetContainerNumSlots(bag) do
			link = GetContainerItemLink(bag, slot)
			if (link) then
				_, _, quality = GetItemInfo(link)
				local itemID = GetItemInfoFromHyperlink(link)
				if (quality == 0 and Config["trash"]) or Config["UnwantedItemList"][tostring(itemID)] then
					if Config["autoreport"] then 
						DEFAULT_CHAT_FRAME:AddMessage("Destroyed: "..link,1,0,0) 
					end
					PickupContainerItem(bag, slot)
					DeleteCursorItem()
				end
			end
		end
	end
end
	TrashcanMainFrame:Hide()
end	
