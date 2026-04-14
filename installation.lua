local HttpService 		= game:GetService('HttpService')
local URL 				= 'https://raw.githubusercontent.com/Cats-AreCute/Roblox_MakeupDescription/refs/heads/main/utility.lua'
local HTTPEnabled 		= HttpService.HttpEnabled

--? Input
local Scripts 			= game.ReplicatedStorage:FindFirstChild('Scripts')
if not Scripts then
	Scripts = Instance.new('Folder', game.ReplicatedStorage)
	Scripts.Name = 'Scripts'
end

local MakeupDescription = Instance.new('Folder', Scripts)
MakeupDescription.Name = 'MakeupDescription'
local Network = Instance.new('RemoteEvent',MakeupDescription)
Network.Name = 'makeup'

--? Input the utility module
local Utils = Instance.new('ModuleScript', MakeupDescription)
Utils.Name = 'utils'
if HTTPEnabled then
	Utils.Source = HttpService:GetAsync(URL)
else
	Utils.Source = `--!!! Open {URL}, copy and paste the script.`
end

--? Input the Console
local ServerConsole = Instance.new('Script', game.ServerScriptService)
ServerConsole.Name = 'MakeupDescription (SERVER)'
ServerConsole.Source = [[local MakeupEditorModule = require(game.ReplicatedStorage.Scripts.MakeupDescription.utils)
MakeupEditorModule.__init_SERVER()]]
local ClientConsole = Instance.new('LocalScript', game.StarterPlayer.StarterPlayerScripts)
ClientConsole.Name = 'MakeupDescription (LOCAL)'
ClientConsole.Source = [[local MakeupEditorModule = require(game.ReplicatedStorage.Scripts.MakeupDescription.utils)
MakeupEditorModule.__init_CLIENT()]]
