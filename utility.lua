--[[	Authour: .................................. LUA_Writer
		Available on 	Github: ................... https://github.com/Cats-AreCute/Roblox_MakeupDescription
						Roblox DevForum: .......... https://devforum.roblox.com/t/makeup-for-humanoiddescription/4576661
		version: ..................................	1.0.0
		Last updated: ............................. 4/15/2026 12:53AM (GMT+8)
--]]
--###############################################################################################################
-- Installation
local RunService						=	game:GetService('RunService')
local InsertService						=	game:GetService('InsertService')
-- Library
local ProvideDebugResponses				=	true	--? For debugging purposes (default: false)
local makeupNetwork						=	script.Parent.makeup
local MakeupDescriptionContents = {
	"FaceMakeup",
	"EyeMakeup",
	"LipMakeup",
	"EyebrowAccessory",
	"EyelashAccessory"
}
--###############################################################################################################
local MakeupEditor = {}

----------------------------------------------------------------------------------------------------------------
--// __init_CLIENT()
--> Initiates the script for the client version. 
--! The script is recommended to be ran from StarterPlayerScripts instead of StarterGui/PlayerGui
function MakeupEditor.__init_CLIENT()
	local actions = {
		['remove'] = function(obj)
			if typeof(obj) == 'table' then
				for _,v in pairs(obj) do
					v:Destroy()
				end
			else
				obj:Destroy()
			end
		end,
	}
	makeupNetwork.OnClientEvent:Connect(function(actionName, ...)
		if actions[actionName] then
			actions[actionName](unpack({...}))
		end
	end)
end

--// __init_SERVER()
--> Initiates the script for the server version. 
--! The script must be ran from a server script.
function MakeupEditor.__init_SERVER()
	local actions = {
		['add'] = function(id, isSecret)
			MakeupEditor:AddMakeup(id, isSecret)
		end,
		['view'] = function(player, ...)
			MakeupEditor:ApplyHumanoidMakeupDescription(player, ...)
		end,
	}
	makeupNetwork.OnServerEvent:Connect(function(player, actionName, ...)
		if actions[actionName] then
			actions[actionName](player, unpack({...}))
		end
	end)
end

----------------------------------------------------------------------------------------------------------------
--// :AddMakeup()
--> Adds the make up.
function MakeupEditor:AddMakeup(...)
	local isServer = RunService:IsServer()
	local args = {...}
	if isServer then --* SERVER
		local client : Player, id : number, IsSecret : boolean
		if typeof(args[1]) == 'Instance' and args[1]:IsA('Player') then
			client, id, IsSecret = unpack(args)
		else
			id, IsSecret = unpack(args)
		end
		 --* Arguments
		--? IsSecret means the the makeup loaded can only be seen by that player.
		
		if ProvideDebugResponses then
			print(`[Makeup Description] Makeup ID: {id}`)
		end
		
		local success, LoadedMakeup = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if success then
			LoadedMakeup.Parent = workspace
			
			--// Secret
			--> Allows the user to make the makeup only visible to themself.
			--! No security is guaranteed.
			print(IsSecret, client)
			if IsSecret and client then
				local RemoveFrom = game.Players:GetPlayers()
				table.remove(RemoveFrom, table.find(RemoveFrom, client))
				for _, hideTo in pairs(RemoveFrom) do
					makeupNetwork:FireClient(hideTo, 'remove', {LoadedMakeup, LoadedMakeup:GetChildren()[1]})
				end
				
				makeupNetwork:FireClient(client, 'add', LoadedMakeup)
			end
			
			local callback = {}
			
			function callback:Attach(Character : Model | Humanoid)
				Character = if Character:IsA('Humanoid') then Character:FindFirstAncestorWhichIsA('Model') else Character
				MakeupEditor:AttachMakeupToCharacter(LoadedMakeup, Character)
			end
			
			return callback
		else
			warn('[MakeupService ERROR] Ensure that you have input the correct id of the makeup. Error received:', LoadedMakeup, 'for the asset id: ',id)
			return false
		end
	else --* CLIENT
		local id : number = unpack(args)

		makeupNetwork:FireServer('add', id, true)
	end
end

----------------------------------------------------------------------------------------------------------------
--// :AttachMakeupToCharacter()
--> Attaches the makeup to the character.
function MakeupEditor:AttachMakeupToCharacter(makeup : Accessory | Decal, character : Model)
	if makeup:IsA('Model') then
		makeup = makeup:FindFirstChildWhichIsA('Accessory') or makeup:FindFirstChildWhichIsA('Decal')
	end
	
	if makeup:IsA('Accessory') then
		makeup.Parent = character
	elseif makeup:IsA('Decal') then
		makeup.Parent = character:FindFirstChild('Head')
	end
end

----------------------------------------------------------------------------------------------------------------
--// :ApplyHumanoidMakeupDescription()
--> Applies the makeup description to the humanoid.
function MakeupEditor:ApplyHumanoidMakeupDescription(...)
	--? Arguments Setup
	local args = {...}
	if ProvideDebugResponses then
		print(`[Makeup Description]`, args)
	end
	
	local client, humanoid : Humanoid, description : HumanoidDescription | {}, isSecret : boolean
	if RunService:IsServer() then --* SERVER
		--? Inputs the data
		if typeof(args[1]) == 'Instance' and args[1]:IsA('Player') then
			client, humanoid, description, isSecret = unpack(args)
		else
			humanoid, description = unpack(args)
		end
	else --* CLIENT
		humanoid, description,isSecret = unpack(args)
	end

	--? Sanity Check
	assert(humanoid, `[Makeup Description] Humanoid was not provided.`)
	assert(description, `[Makeup Description] Humanoid Description was not provided.`)

	--? Apply the description
	local HumanoidDescriptionIsComplete = MakeupEditor:IsContentComplete(description, true)
	
	if RunService:IsServer() then
		for _, indexName in pairs(MakeupDescriptionContents) do
			if client then --? Received from a client
				local indexValue = description[indexName]
				
				if indexValue then
					local NEW_MAKEUP = MakeupEditor:AddMakeup(client, indexValue, isSecret)
					if NEW_MAKEUP then
						NEW_MAKEUP:Attach(humanoid)
					end
				end
			else --? Received from the server (binded / server-server)
				local indexValue = description:GetAttribute(indexName)
				if ProvideDebugResponses then
					print(`[Makeup Description] {indexName} = {indexValue}`)
				end
				local NEW_MAKEUP = MakeupEditor:AddMakeup(indexValue)
				if NEW_MAKEUP then
					NEW_MAKEUP:Attach(humanoid)
				end
			end
		end
	elseif RunService:IsClient() then
		local COMPILED_DESCRIPTION = {}
		for _, indexName in pairs(MakeupDescriptionContents) do
			local indexValue = description:GetAttribute(indexName)
			COMPILED_DESCRIPTION[indexName] = indexValue
		end
		
		makeupNetwork:FireServer('view', humanoid, COMPILED_DESCRIPTION, isSecret)
	end
end

----------------------------------------------------------------------------------------------------------------
--// :Setup_MakeupDescription_ToHumanoidDescription()
--> Create attributes for the humanoid description allowing the feature of makeups.
function MakeupEditor:Setup_MakeupDescription_ToHumanoidDescription(description : HumanoidDescription)
	assert(description and description:IsA('HumanoidDescription'), `[Makeup Description] Unavailable or invalid humanoid description.`)

	for _, indexName in pairs(MakeupDescriptionContents) do
		description:SetAttribute(indexName, 0)
	end
end
--? ALIASES
MakeupEditor.InitiateMakeupDescription 	= function(...) MakeupEditor:Setup_MakeupDescription_ToHumanoidDescription(unpack({...})) end
MakeupEditor.NewMakeupDescription 		= function(...) MakeupEditor:Setup_MakeupDescription_ToHumanoidDescription(unpack({...})) end
MakeupEditor.new 						= function(...) MakeupEditor:Setup_MakeupDescription_ToHumanoidDescription(unpack({...})) end

----------------------------------------------------------------------------------------------------------------
--// :IsContentComplete()
--> Checks if the content of the HumanoidDescription for the Makeup is complete.
function MakeupEditor:IsContentComplete(description : HumanoidDescription, autoResolve : boolean)
	--? Sanity Check
	assert(description, `[Makeup Description] Humanoid description does not exist.`)
	if typeof(description) == 'Instance' then
		assert(description:IsA('HumanoidDescription'), `[Makeup Description] Unavailable or invalid humanoid description. The classname received is: {description.ClassName}`)
	elseif typeof(description) == 'table' then
		-- ignore
	else
		if ProvideDebugResponses then
			print(`[Makeup Description] The provided instance or variable type ({typeof(description)}) is not accepted.`)
		end
		return --> Others are blacklsited
	end
	
	
	--?
	local TableDescription = false
	if typeof(description) == 'table' then
		TableDescription = {}
	end
	
	local DebugResponse = 0

	for _, indexName in pairs(MakeupDescriptionContents) do
		local indexValue
		if TableDescription then
			indexValue = description[indexName]
		else
			indexValue = description:GetAttribute(indexName)
		end
		if not indexValue then
			if autoResolve then
				if TableDescription then
					description[indexName] = 0
				else
					description:SetAttribute(indexName, 0) 
				end
				DebugResponse += 1
			else
				if TableDescription then
					return description --? (Client-Server)
				else
					return false --? (Server-Server)
				end
			end
		end
	end

	if ProvideDebugResponses then
		print(`[Makeup Description] added {DebugResponse} attributes to the HumanoidDescription.`)
	end
	
	if TableDescription then
		return description --? (Client-Server)
	else
		return true --? (Server-Server)
	end
end

return MakeupEditor
