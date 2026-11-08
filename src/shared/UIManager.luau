local UIManager = {}

local screens = {}
local currentScreen = nil
local persistantScreens = {}

function UIManager.register(name: string, gui: ScreenGui)
    screens[name] = gui
    gui.Enabled = false
end

function UIManager.registerPersistent(name: string, gui: ScreenGui)
    screens[name] = gui
    persistantScreens[name] = gui
    gui.Enabled = true
end

function UIManager.show(name: string)
    -- hide current screen first
    if currentScreen and currentScreen ~= name and not persistantScreens[currentScreen] then
        if screens[currentScreen] then
            screens[currentScreen].Enabled = false
        end
    end

    -- show new screen
    if screens[name] then
        screens[name].Enabled = true
        if not persistantScreens[name] then
            currentScreen = name
        end
    end
end

function UIManager.hide(name: string)
    if screens[name] then
        screens[name].Enabled = false
        if currentScreen == name then
            currentScreen = nil
        end
    end
end

function UIManager.getCurrent(): string?
    return currentScreen
end

function UIManager.toggle(name: string)
    if screens[name] then
        screens[name].Enabled = not screens[name].Enabled
    end
end


return UIManager