-- c00lgui // Legacy Retro Edition 2026 (Persistent Rejoin + Dynamic Search Update)
local src = [==[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Variables de estado
local flying = false
local flyConnection = nil
local flyBv = nil
local flyBg = nil
local tooltipConnection = nil
local minimized = false 

-- Variables de estado: ESP
local espActive = false
local espConnections = {}

-- Variables de estado: Salto Infinito
local infJump = false
local infJumpConnection = nil

-- Variables de estado: Noclip
local noclip = false
local noclipConnection = nil

-- Variables de estado: Lighting (Fullbright / Nofog)
local fullbright = false
local fullbrightConnection = nil
local nofog = false
local nofogConnection = nil

-- Guardado de iluminación original del juego
local origAmbient = Lighting.Ambient
local origOutdoorAmbient = Lighting.OutdoorAmbient
local origBrightness = Lighting.Brightness
local origShadows = Lighting.GlobalShadows
local origFogEnd = Lighting.FogEnd

-- Variables de estado: Click TP
local clickTp = false
local clickTpConnection = nil

-- Configuración de Animaciones
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Contenedor Principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "c00lgui_Legacy"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Panel Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.AnchorPoint = Vector2.new(0.5, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.4, -120)
MainFrame.Size = UDim2.new(0, 0, 0, 0) 
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 51)
MainFrame.Active = true
MainFrame.ClipsDescendants = true 
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui

-- Barra de Título (Contenedor Superior)
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 0, 51) -- Unificado con la estética visual
TitleBar.BackgroundTransparency = 0.9
TitleBar.BorderSizePixel = 1
TitleBar.BorderColor3 = Color3.fromRGB(255, 0, 51)
TitleBar.Visible = false 
TitleBar.ZIndex = 3
TitleBar.Parent = MainFrame

-- Zona de Arrastre Segura
local DragHandle = Instance.new("TextLabel")
DragHandle.Name = "DragHandle"
DragHandle.Size = UDim2.new(1, -60, 1, 0) 
DragHandle.Position = UDim2.new(0, 0, 0, 0)
DragHandle.BackgroundTransparency = 1
DragHandle.Font = Enum.Font.Code
DragHandle.Text = "  c00lgui // v0.1_ch"
DragHandle.TextColor3 = Color3.fromRGB(255, 255, 255)
DragHandle.TextSize = 14
DragHandle.TextXAlignment = Enum.TextXAlignment.Left
DragHandle.Active = true
DragHandle.ZIndex = 4
DragHandle.Parent = TitleBar

-- Botón de Minimizar
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 28, 1, 0)
MinimizeBtn.Position = UDim2.new(1, -56, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Font = Enum.Font.Code
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 0, 51)
MinimizeBtn.TextSize = 16
MinimizeBtn.Active = true
MinimizeBtn.ZIndex = 5
MinimizeBtn.Parent = TitleBar

-- Botón de Cerrar (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 1, 0)
CloseBtn.Position = UDim2.new(1, -28, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.Code
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 0, 51)
CloseBtn.TextSize = 14
CloseBtn.Active = true
CloseBtn.ZIndex = 5
CloseBtn.Parent = TitleBar

-- Barra de Comandos (TextBox)
local CmdBar = Instance.new("TextBox")
CmdBar.Name = "CmdBar"
CmdBar.Size = UDim2.new(1, -20, 0, 30)
CmdBar.Position = UDim2.new(0, 10, 0, 40)
CmdBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
CmdBar.BorderSizePixel = 1
CmdBar.BorderColor3 = Color3.fromRGB(100, 0, 20)
CmdBar.Font = Enum.Font.Code
CmdBar.PlaceholderText = "escribe tu comando."
CmdBar.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
CmdBar.Text = ""
CmdBar.TextColor3 = Color3.fromRGB(255, 50, 50)
CmdBar.TextSize = 14
CmdBar.TextXAlignment = Enum.TextXAlignment.Left
CmdBar.ClearTextOnFocus = true
CmdBar.Visible = false 
CmdBar.ZIndex = 2
CmdBar.Parent = MainFrame

-- Contenedor de Lista de Comandos
local CmdsList = Instance.new("ScrollingFrame")
CmdsList.Name = "CmdsList"
CmdsList.Size = UDim2.new(1, -20, 1, -90)
CmdsList.Position = UDim2.new(0, 10, 0, 80)
CmdsList.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
CmdsList.BorderSizePixel = 1
CmdsList.BorderColor3 = Color3.fromRGB(40, 40, 40)
CmdsList.CanvasSize = UDim2.new(0, 0, 0, 0) -- Se auto-ajustará dinámicamente
CmdsList.ScrollBarThickness = 6
CmdsList.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 51)
CmdsList.Visible = false 
CmdsList.ZIndex = 2
CmdsList.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = CmdsList

-- Ventana Flotante de Explicación (Tooltip)
local Tooltip = Instance.new("TextLabel")
Tooltip.Name = "Tooltip"
Tooltip.Size = UDim2.new(0, 200, 0, 42)
Tooltip.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Tooltip.BorderColor3 = Color3.fromRGB(255, 0, 51)
Tooltip.BorderSizePixel = 1
Tooltip.Font = Enum.Font.SourceSansBold
Tooltip.TextColor3 = Color3.fromRGB(220, 220, 220)
Tooltip.TextSize = 13
Tooltip.TextWrapped = true
Tooltip.ZIndex = 10
Tooltip.Visible = false
Tooltip.Parent = ScreenGui

------------------------------------------------------------------------
-- MINI VENTANA: CONFIRMACIÓN DE ELIMINACIÓN
------------------------------------------------------------------------
local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Name = "ConfirmPanel"
ConfirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmFrame.Size = UDim2.new(0, 0, 0, 0)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
ConfirmFrame.BorderSizePixel = 2
ConfirmFrame.BorderColor3 = Color3.fromRGB(255, 0, 51)
ConfirmFrame.ClipsDescendants = true
ConfirmFrame.ZIndex = 20
ConfirmFrame.Visible = false
ConfirmFrame.Parent = ScreenGui

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Size = UDim2.new(1, -20, 0, 40)
ConfirmText.Position = UDim2.new(0, 10, 0, 15)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Font = Enum.Font.Code
ConfirmText.Text = "estas seguro de\neliminar el gui?"
ConfirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmText.TextSize = 14
ConfirmText.ZIndex = 21
ConfirmText.Parent = ConfirmFrame

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.new(0, 85, 0, 26)
YesBtn.Position = UDim2.new(0, 20, 1, -36)
YesBtn.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
YesBtn.BorderSizePixel = 1
YesBtn.BorderColor3 = Color3.fromRGB(255, 0, 51)
YesBtn.Font = Enum.Font.Code
YesBtn.Text = "[ SI ]"
YesBtn.TextColor3 = Color3.fromRGB(255, 51, 51)
YesBtn.TextSize = 14
YesBtn.ZIndex = 21
YesBtn.Parent = ConfirmFrame

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.new(0, 85, 0, 26)
NoBtn.Position = UDim2.new(1, -105, 1, -36)
NoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
NoBtn.BorderSizePixel = 1
NoBtn.BorderColor3 = Color3.fromRGB(80, 80, 80)
NoBtn.Font = Enum.Font.Code
NoBtn.Text = "[ NO ]"
NoBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
NoBtn.TextSize = 14
NoBtn.ZIndex = 21
NoBtn.Parent = ConfirmFrame

-- Tabla para rastrear etiquetas e indexar búsquedas rápidamente
local labelRegistry = {}

local function addCmdLabel(codeText, description, searchKeys)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 22)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = " > " .. codeText
    label.TextColor3 = Color3.fromRGB(255, 51, 51)
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Active = true
    label.ZIndex = 3
    label.Parent = CmdsList

    label.MouseEnter:Connect(function()
        if minimized or ConfirmFrame.Visible then return end 
        Tooltip.Text = description
        Tooltip.Visible = true
        
        if tooltipConnection then tooltipConnection:Disconnect() end
        tooltipConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation()
                Tooltip.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y + 15)
            end
        end)
    end)

    label.MouseLeave:Connect(function()
        Tooltip.Visible = false
        if tooltipConnection then
            tooltipConnection:Disconnect()
            tooltipConnection = nil
        end
    end)
    
    table.insert(labelRegistry, {GuiObject = label, Keys = searchKeys})
end

-- Inicialización de comandos con sus llaves de búsqueda estructuradas
addCmdLabel("speed [num];", "Modifica la velocidad de caminata de tu personaje.", {"speed"})
addCmdLabel("jump [num];", "Modifica la fuerza de salto de tu personaje.", {"jump"})
addCmdLabel("fly;", "Activa el modo de vuelo libre en cualquier dirección.", {"fly"})
addCmdLabel("unfly;", "Desactiva el modo de vuelo y restaura las físicas.", {"unfly"})
addCmdLabel("noclip;", "Desactiva las colisiones, permitiéndote atravesar paredes.", {"noclip"})
addCmdLabel("unnoclip;", "Restaura las colisiones normales de tu personaje.", {"unnoclip"})
addCmdLabel("clicktp; / ctp;", "Te teletransporta a donde hagas clic izquierdo en el mapa.", {"clicktp", "ctp"})
addCmdLabel("unclicktp; / unctp;", "Desactiva el teletransporte por clic izquierdo.", {"unclicktp", "unctp"})
addCmdLabel("fullbright;", "Elimina las sombras e ilumina todo el mapa por completo.", {"fullbright"})
addCmdLabel("nofog;", "Quita por completo toda la neblina/fog ambiental.", {"nofog"})
addCmdLabel("infjump; / infinitejump;", "Permite saltar infinitamente en el aire.", {"infjump", "infinitejump"})
addCmdLabel("uninfjump; / uninfinitejump;", "Desactiva el salto infinito.", {"uninfjump", "uninfinitejump"})
addCmdLabel("esp;", "Revela la posición, nombre y vida de los jugadores.", {"esp"})
addCmdLabel("unesp;", "Desactiva el rastreador de jugadores (ESP).", {"unesp"})
addCmdLabel("tp [jugador];", "Te teletransporta instantáneamente al jugador (búsqueda parcial).", {"tp"})
addCmdLabel("rejoin; / rj;", "Te desconecta y te vuelve a meter al mismo servidor de inmediato.", {"rejoin", "rj"})
addCmdLabel("btools;", "Crea herramientas locales clásicas de construcción en tu mochila.", {"btools"})

-- Función inteligente para actualizar el Canvas y visibilidad del buscador
local function updateScrollLayout()
    local visibleCount = 0
    for _, item in ipairs(labelRegistry) do
        if item.GuiObject.Visible then
            visibleCount = visibleCount + 1
        end
    end
    CmdsList.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 26)
end

updateScrollLayout()

------------------------------------------------------------------------
-- SISTEMA CRÍTICO: FILTRADO / AUTOCOMPLETADO EN TIEMPO REAL
------------------------------------------------------------------------
CmdBar:GetPropertyChangedSignal("Text"):Connect(function()
    local rawText = CmdBar.Text
    if rawText == "" then
        -- Si está vacío, muestra absolutamente todo
        for _, item in ipairs(labelRegistry) do
            item.GuiObject.Visible = true
        end
    else
        -- Limpieza inteligente del texto ingresado (remover espacios y ; de consulta)
        local query = string.lower(rawText)
        query = string.gsub(query, "^%s*(.-)%s*$", "%1")
        if string.sub(query, 1, 1) == ";" then query = string.sub(query, 2) end
        if string.sub(query, -1) == ";" then query = string.sub(query, 1, -2) end
        query = string.split(query, " ")[1] or "" -- Filtrar solo por la primera palabra clave del comando

        if query == "" then
            for _, item in ipairs(labelRegistry) do item.GuiObject.Visible = true end
        else
            for _, item in ipairs(labelRegistry) do
                local matchFound = false
                for _, key in ipairs(item.Keys) do
                    if string.find(key, query, 1, true) then
                        matchFound = true
                        break
                    end
                end
                item.GuiObject.Visible = matchFound
            end
        end
    end
    updateScrollLayout()
end)

local Glow = Instance.new("Frame")
Glow.Size = UDim2.new(1, 0, 0, 2)
Glow.Position = UDim2.new(0, 0, 1, 0)
Glow.BackgroundColor3 = Color3.fromRGB(255, 0, 51)
Glow.BorderSizePixel = 0
Glow.ZIndex = 2
Glow.Parent = MainFrame

------------------------------------------------------------------------
-- LÓGICA: Minimizar Ventana con Animación (TweenService)
------------------------------------------------------------------------
MinimizeBtn.Activated:Connect(function()
    if ConfirmFrame.Visible then return end
    minimized = not minimized
    
    if minimized then
        MinimizeBtn.Text = "+"
        Tooltip.Visible = false
        
        MainFrame.ClipsDescendants = true
        local minimizeTween = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 320, 0, 28)})
        minimizeTween:Play()
        
        minimizeTween.Completed:Connect(function()
            if minimized then
                CmdBar.Visible = false
                CmdsList.Visible = false
            end
        end)
    else
        MinimizeBtn.Text = "-"
        CmdBar.Visible = true
        CmdsList.Visible = true
        
        local restoreTween = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 320, 0, 240)})
        restoreTween:Play()
    end
end)

------------------------------------------------------------------------
-- LÓGICA: Arrastrar Ventana vinculada al DragHandle Seguro
------------------------------------------------------------------------
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

DragHandle.InputBegan:Connect(function(input)
    if ConfirmFrame.Visible then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

DragHandle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

------------------------------------------------------------------------
-- FUNCIONES AUXILIARES: Limpieza de Estados Remotos
------------------------------------------------------------------------
local function stopFlying(humanoid)
    flying = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyBv then flyBv:Destroy(); flyBv = nil end
    if flyBg then flyBg:Destroy(); flyBg = nil end
    if humanoid then humanoid.PlatformStand = false end
end

local function stopNoclip()
    noclip = false
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
end

local function stopFullbright()
    fullbright = false
    if fullbrightConnection then fullbrightConnection:Disconnect(); fullbrightConnection = nil end
    Lighting.Ambient = origAmbient
    Lighting.OutdoorAmbient = origOutdoorAmbient
    Lighting.Brightness = origBrightness
    Lighting.GlobalShadows = origShadows
end

local function stopNofog()
    nofog = false
    if nofogConnection then nofogConnection:Disconnect(); nofogConnection = nil end
    Lighting.FogEnd = origFogEnd
end

local function stopClickTp()
    clickTp = false
    if clickTpConnection then clickTpConnection:Disconnect(); clickTpConnection = nil end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    stopFlying(hum)
    stopNoclip()
    stopClickTp()
end)

CmdBar.Focused:Connect(function()
    CmdBar.PlaceholderText = "escribe tu comando."
end)

------------------------------------------------------------------------
-- NÚCLEO LÓGICO AVANZADO: SISTEMA ESP
------------------------------------------------------------------------
local function applyESP(player, character)
    if not character then return end
    if character:FindFirstChild("c00l_ESP") then return end 
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "c00l_ESP"
    highlight.FillColor = Color3.fromRGB(255, 0, 51) 
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    local head = character:WaitForChild("Head", 5) or character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if head and humanoid then
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "c00l_ESP_Tag"
        bbg.Size = UDim2.new(0, 300, 0, 40) 
        bbg.StudsOffset = Vector3.new(0, 3.5, 0) 
        bbg.AlwaysOnTop = true
        bbg.Parent = head
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Code
        label.TextSize = 18 
        label.TextColor3 = Color3.fromRGB(255, 51, 51)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextXAlignment = Enum.TextXAlignment.Center 
        label.TextYAlignment = Enum.TextYAlignment.Center 
        label.Parent = bbg
        
        local function updateTag()
            if humanoid and label and bbg then
                local currentHp = math.floor(humanoid.Health)
                local maxHp = math.floor(humanoid.MaxHealth)
                label.Text = player.Name .. " [" .. currentHp .. "/" .. maxHp .. " HP]"
            end
        end
        
        updateTag()
        
        local hpConnection = humanoid.HealthChanged:Connect(updateTag)
        table.insert(espConnections, hpConnection)
    end
end

local function startESP()
    if espActive then return end
    espActive = true
    
    local function listenToPlayer(player)
        if player == LocalPlayer then return end
        if player.Character then applyESP(player, player.Character) end
        
        local charConnection = player.CharacterAdded:Connect(function(char)
            if espActive then applyESP(player, char) end
        end)
        table.insert(espConnections, charConnection)
    end
    
    for _, player in ipairs(Players:GetPlayers()) do listenToPlayer(player) end
    local playerAddedConnection = Players.PlayerAdded:Connect(listenToPlayer)
    table.insert(espConnections, playerAddedConnection)
end

local function stopESP()
    espActive = false
    for _, connection in ipairs(espConnections) do connection:Disconnect() end
    espConnections = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("c00l_ESP")
            if highlight then highlight:Destroy() end
            
            local head = player.Character:FindFirstChild("Head")
            if head then
                local bbg = head:FindFirstChild("c00l_ESP_Tag")
                if bbg then bbg:Destroy() end
            end
        end
    end
end

------------------------------------------------------------------------
-- FLUJO DE CIERRE Y MINI VENTANA DE CONFIRMACIÓN
------------------------------------------------------------------------
CloseBtn.Activated:Connect(function()
    if ConfirmFrame.Visible then return end
    Tooltip.Visible = false
    ConfirmFrame.Size = UDim2.new(0, 0, 0, 0)
    ConfirmFrame.Visible = true
    
    TweenService:Create(ConfirmFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 230, 0, 110)
    }):Play()
end)

NoBtn.Activated:Connect(function()
    local closeConfirm = TweenService:Create(ConfirmFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    })
    closeConfirm:Play()
    closeConfirm.Completed:Connect(function()
        ConfirmFrame.Visible = false
    end)
end)

YesBtn.Activated:Connect(function()
    ConfirmFrame.Visible = false
    CloseBtn.Active = false
    MinimizeBtn.Active = false
    CmdBar.Visible = false
    CmdsList.Visible = false
    
    local closePhase1 = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 320, 0, 2)
    })
    
    local closePhase2 = TweenService:Create(MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 2)
    })
    
    closePhase1.Completed:Connect(function()
        TitleBar.Visible = false
        closePhase2:Play()
    end)
    
    closePhase2.Completed:Connect(function()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        stopFlying(humanoid)
        stopNoclip()
        stopFullbright()
        stopNofog()
        stopClickTp()
        
        infJump = false
        if infJumpConnection then
            infJumpConnection:Disconnect()
            infJumpConnection = nil
        end
        
        stopESP()
        
        if tooltipConnection then
            tooltipConnection:Disconnect()
            tooltipConnection = nil
        end
        
        ScreenGui:Destroy()
    end)
    
    closePhase1:Play()
end)

------------------------------------------------------------------------
-- PROCESADOR DE COMANDOS CRÍTICO
------------------------------------------------------------------------
local VALID_COMMANDS = {
    ["speed"] = true, ["jump"] = true, ["fly"] = true, ["unfly"] = true, 
    ["esp"] = true, ["unesp"] = true,
    ["infinitejump"] = true, ["infjump"] = true, ["uninfinitejump"] = true, ["uninfjump"] = true,
    ["tp"] = true, ["rejoin"] = true, ["rj"] = true, ["btools"] = true,
    ["noclip"] = true, ["unnoclip"] = true,
    ["fullbright"] = true, ["unfullbright"] = true, ["nofog"] = true, ["unnofog"] = true,
    ["clicktp"] = true, ["ctp"] = true, ["unclicktp"] = true, ["unctp"] = true
}

CmdBar.FocusLost:Connect(function(enterPressed)
    if not enterPressed or CmdBar.Text == "" or ConfirmFrame.Visible then return end
    
    local cleanedRaw = string.gsub(CmdBar.Text, "^%s*(.-)%s*$", "%1")
    local input = string.lower(cleanedRaw)
    
    local commandFound = false
    local errorMessage = "comando inexistente." 

    local hasSemicolon = false
    local cleanCommandString = input
    
    if string.sub(input, 1, 1) == ";" then
        hasSemicolon = true
        cleanCommandString = string.sub(input, 2)
    elseif string.sub(input, -1) == ";" then
        hasSemicolon = true
        cleanCommandString = string.sub(input, 1, -2)
    end
    
    cleanCommandString = string.gsub(cleanCommandString, "^%s*(.-)%s*$", "%1")
    local args = string.split(cleanCommandString, " ")
    local cmd = args[1]
    
    local isValidRejoin = (cmd == "rejoin" or cmd == "rj")
    local isOtherCommand = (not isValidRejoin) and VALID_COMMANDS[cmd]

    if isOtherCommand or isValidRejoin then
        if hasSemicolon then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and hrp then
                if cmd == "speed" then
                    local amount = tonumber(args[2])
                    if amount then
                        commandFound = true
                        humanoid.WalkSpeed = amount
                    end
                elseif cmd == "jump" then
                    local amount = tonumber(args[2])
                    if amount then
                        commandFound = true
                        humanoid.JumpPower = amount
                        humanoid.UseJumpPower = true
                    end
                elseif cmd == "btools" then
                    commandFound = true
                    for i = 1, 3 do
                        local tool = Instance.new("HopperBin")
                        tool.BinType = i
                        tool.Parent = LocalPlayer:FindFirstChildOfClass("Backpack")
                    end
                elseif cmd == "rejoin" or cmd == "rj" then
                    commandFound = true
                    local queue = queue_on_teleport or (syn and syn.queue_on_teleport)
                    if queue and getgenv().c00l_raw then
                        queue(getgenv().c00l_raw)
                    end
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                
                elseif cmd == "esp" then
                    commandFound = true
                    startESP()
                    
                elseif cmd == "unesp" then
                    commandFound = true
                    stopESP()

                elseif cmd == "fullbright" then
                    commandFound = true
                    if not fullbright then
                        fullbright = true
                        fullbrightConnection = RunService.RenderStepped:Connect(function()
                            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                            Lighting.Brightness = 2
                            Lighting.GlobalShadows = false
                        end)
                    end

                elseif cmd == "unfullbright" then
                    commandFound = true
                    stopFullbright()

                elseif cmd == "nofog" then
                    commandFound = true
                    if not nofog then
                        nofog = true
                        nofogConnection = RunService.RenderStepped:Connect(function()
                            Lighting.FogEnd = 9e9
                        end)
                    end

                elseif cmd == "unnofog" then
                    commandFound = true
                    stopNofog()

                elseif cmd == "clicktp" or cmd == "ctp" then
                    commandFound = true
                    if not clickTp then
                        clickTp = true
                        clickTpConnection = Mouse.Button1Down:Connect(function()
                            local char = LocalPlayer.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            if root and Mouse.Hit then
                                root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
                            end
                        end)
                    end

                elseif cmd == "unclicktp" or cmd == "unctp" then
                    commandFound = true
                    stopClickTp()

                elseif cmd == "noclip" then
                    commandFound = true
                    if not noclip then
                        noclip = true
                        noclipConnection = RunService.Stepped:Connect(function()
                            if noclip and character then
                                for _, part in ipairs(character:GetDescendants()) do
                                    if part:IsA("BasePart") and part.CanCollide then
                                        part.CanCollide = false
                                    end
                                end
                            else
                                stopNoclip()
                            end
                        end)
                    end

                elseif cmd == "unnoclip" then
                    commandFound = true
                    stopNoclip()

                elseif cmd == "infinitejump" or cmd == "infjump" then
                    commandFound = true
                    if not infJump then
                        infJump = true
                        infJumpConnection = UserInputService.JumpRequest:Connect(function()
                            if infJump and LocalPlayer.Character then
                                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                                if hum then
                                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                                end
                            end
                        end)
                    end

                elseif cmd == "uninfinitejump" or cmd == "uninfjump" then
                    commandFound = true
                    infJump = false
                    if infJumpConnection then
                        infJumpConnection:Disconnect()
                        infJumpConnection = nil
                    end

                elseif cmd == "fly" then
                    commandFound = true
                    if not flying then
                        flying = true
                        humanoid.PlatformStand = true
                        
                        flyBv = Instance.new("BodyVelocity")
                        flyBv.MaxForce = Vector3.new(4e5, 4e5, 4e5)
                        flyBv.Velocity = Vector3.new(0, 0, 0)
                        flyBv.Parent = hrp

                        flyBg = Instance.new("BodyGyro")
                        flyBg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
                        flyBg.CFrame = hrp.CFrame
                        flyBg.Parent = hrp
                        
                        flyConnection = RunService.RenderStepped:Connect(function()
                            if not flying or not hrp or not hrp.Parent or not humanoid then
                                stopFlying(humanoid)
                                return
                            end
                            
                            flyBg.CFrame = Camera.CFrame
                            local direction = Vector3.new(0, 0, 0)
                            
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
                            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end
                            
                            if direction.Magnitude > 0 then
                                flyBv.Velocity = direction.Unit * 50
                            else
                                flyBv.Velocity = Vector3.new(0, 0, 0)
                            end
                        end)
                    end
                    
                elseif cmd == "unfly" then
                    commandFound = true
                    stopFlying(humanoid)

                elseif cmd == "tp" then
                    local targetName = args[2]
                    if targetName then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and string.sub(string.lower(p.Name), 1, string.len(targetName)) == targetName then
                                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                    commandFound = true
                                    hrp.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        else
            errorMessage = "requiere ; para su función."
        end
    else
        errorMessage = "comando inexistente."
    end
    
    if commandFound then
        CmdBar.BorderColor3 = Color3.fromRGB(0, 255, 100)
        CmdBar.PlaceholderText = "escribe tu comando."
    else
        CmdBar.BorderColor3 = Color3.fromRGB(255, 0, 0)
        CmdBar.PlaceholderText = errorMessage
    end
    
    task.delay(0.4, function() CmdBar.BorderColor3 = Color3.fromRGB(100, 0, 20) end)
    CmdBar.Text = ""
end)

------------------------------------------------------------------------
-- SINTONIZACIÓN SMART: DETECTAR VISIBILIDAD REAL DE LA PANTALLA
------------------------------------------------------------------------
local startupPhase1 = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 320, 0, 2)
})

local startupPhase2 = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 320, 0, 240)
})

startupPhase1.Completed:Connect(function()
    TitleBar.Visible = true
    CmdBar.Visible = true
    CmdsList.Visible = true
    startupPhase2:Play()
end)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(1.2)

MainFrame.Size = UDim2.new(0, 0, 0, 2) 
startupPhase1:Play()
]==]

-- Compilador y Estructurador de Auto-Inyección Infinita
getgenv().c00l_raw = "getgenv().c00l_raw = [==[" .. src .. "]==]\n" .. src
loadstring(src)()
