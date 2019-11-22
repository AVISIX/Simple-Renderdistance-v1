--[[
    Copyright © Sixmax(STEAM_0:0:104139026) 2019

    Author: Sixmax / STEAM_0:0:104139026
]]

timer.Remove("refreshprophider") -- Cleanup trash
timer.Remove("unhideprops")


local distance = 2500
local refresh_interval = 1
local delay = 0.01


CreateClientConVar("prophider_proprender_delay", "0.01", true, false)
local proprenderConvar = GetConVar("prophider_proprender_delay")

CreateClientConVar("prophider_enabled","1", true, false)
local enabledConvar =  GetConVar("prophider_enabled")

CreateClientConVar("prophider_refresh_interval","1", true, false)
local refreshConvar =  GetConVar("prophider_refresh_interval")

CreateClientConVar("prophider_trigger_range","2500", true, false)
local distanceConvar =  GetConVar("prophider_trigger_range")



local hiddenProps = {} -- Save all the hidden props in here, so we can reset them incase the user wants to disable the hider


local originalRender = RenderOverride -- Save the original RenderOverride function
local function resetPropRender(prop)
    if prop.RenderOverride != originalRender then   
        prop:DrawShadow(true) 

        prop.RenderOverride = originalRender -- Override the function with good shit so it does render ;)

        table.RemoveByValue(hiddenProps, prop)
    end     
end


local resettingHidden = false
local unhidecounter = 0
local function resetHiddenProps()
    if not (#hiddenProps <= 0) then 
        if resettingHidden == false then 
            timer.Remove("unhideprops")

            unhidecounter = #hiddenProps
            
            timer.Create("unhideprops", delay, 0, function()          
                if unhidecounter > 0 then   

                    resetPropRender(hiddenProps[unhidecounter])
                    unhidecounter = unhidecounter - 1
                end

                if unhidecounter <= 0 or #hiddenProps <= 0 then   

                    timer.Remove("unhideprops")
                    hiddenProps = {}
                    resettingHidden = false

                end
            end)

            resettingHidden = true
        end
    else
        if timer.Exists("unhideprops") == true then
            timer.Remove("unhideprops")
        end 
    end
end

local renderQueue = {}

local function renderQueueRunner()
    if #renderQueue > 0 then
        resetPropRender(renderQueue[1])    
        table.remove(renderQueue, 1)  
    end
end

timer.Create("prophider_renderqueue", delay, 0, renderQueueRunner)

local function refreshProphider()     
    local isEnabled  = enabledConvar:GetBool() 
    local curRefresh = refreshConvar:GetInt()
    local curRange   = distanceConvar:GetInt()
    local curDelay   = proprenderConvar:GetFloat()

    local props = ents.GetAll()

    if isEnabled == true then 
        for _, prop in pairs(props) do 
            if (prop:IsValid() or isentity(prop) or IsEntity(prop) or prop:IsSolid())
             && prop:IsWeapon()   == false
             && prop:IsPlayer()   == false
             && prop:IsWorld()    == false 
             && prop:IsScripted() == false 
             && prop:IsNPC()      == false 
             then
                local proppv = prop:GetPos()
                local playerpv = LocalPlayer():GetPos()

                if proppv:Distance(playerpv) > distance then

                    if table.HasValue(hiddenProps, prop) == false then 
                        prop:DrawShadow(false) 
                        prop.RenderOverride = function() end -- Override the function with bullshit so it doasnt render

                        table.insert(hiddenProps, prop)
                    end

                else
                    if delay > 0 then 
                        if table.HasValue(renderQueue, prop) == false then
                            table.insert(renderQueue, prop)
                        end
                    else
                        resetPropRender(prop)
                    end
                end
            end
        end 
    else
        resetHiddenProps()
    end

    if curRefresh != refresh_interval then
        refresh_interval = curRefresh

        timer.Remove("refreshprophider")
        timer.Create("refreshprophider", refresh_interval, 0, refreshProphider)

    --    print("Prophider refreshrate changed to: " .. refresh_interval)
    end

    if distance != curRange then
        distance = curRange

        timer.Remove("refreshprophider")
        timer.Create("refreshprophider", refresh_interval, 0, refreshProphider)
        
      --  print("Prophider trigger distance changed to: " .. distance)
    end

    if delay != curDelay then 
        delay = curDelay

        timer.Remove("refreshprophider")
        timer.Create("refreshprophider", refresh_interval, 0, refreshProphider)

        timer.Remove("prophider_renderqueue")
        timer.Create("prophider_renderqueue", delay, 0, renderQueueRunner)

    --    print("Prophider render delay changed.")
    end
end 

timer.Create("refreshprophider", refresh_interval, 0, refreshProphider)