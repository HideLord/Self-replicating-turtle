turtleInfo = {dir = 0}
movementHistory = {}

 --[=[
    Constants used to indicate movement or direction.   
 ]=]
FORWARD = 0
BACKWARD = 1
UPWARD = 2
DOWNWARD = 3

TURN_RIGHT = 1
TURN_LEFT = 3 -- 3 to avoid negative numbers

 --[=[
    required is the number of blocks the trip is going to take.
    Checks if there is enough fuel and refuels if needed.
 ]=]
function checkForFuel(required)
    assert(type(required) == "number", "Expected number.")

    required = required or 640
    if turtle.getFuelLevel() < required then
        for i = 1, 16 do
            local item = turtle.getItemDetail(i)

            if item and item.name == "minecraft:coal" then
                turtle.select(i)
                while turtle.getItemCount(i) > 0 and 
                      turtle.getFuelLevel() < required do turtle.refuel(1) end
                if turtle.getFuelLevel() >= required then
                    return true
                end
            end

        end
        return false
    else
        return true
    end
end

 -- Wrapper functions to track movement history.
function forward(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "forward: Expected number.")

    for i=1, numMoves do
        turtle.forward(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = FORWARD})
    end
end

function backward(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "backward: Expected number.")
    
    for i=1, numMoves do
        turtle.back(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = BACKWARD})
    end
end

function upward(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "upward: Expected number.")

    for i=1, numMoves do
        turtle.up(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = UPWARD})
    end
end

function downward(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "downward: Expected number.")

    for i=1, numMoves do
        turtle.down(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = DOWNWARD})
    end
end

function turnLeft(times)
    times = times or 1
    assert(type(times) == "number", "turnLeft: Expected number.")

    times = times % 4
    if(times > 2) then
        turnRight(times-2)
    else
        for i=1, times do
            turtle.turnLeft()
            turtleInfo.dir = turtleInfo.dir + TURN_LEFT
            if turtleInfo.dir >= 4 then turtleInfo.dir = turtleInfo.dir - 4 end
        end
    end
end

function turnRight(times)
    times = times or 1
    assert(type(times) == "number", "turnRight: Expected number.")

    times = times % 4
    if(times > 2) then
        turnLeft(times-2)
    else
        for i=1, times do
            turtle.turnRight()
            turtleInfo.dir = turtleInfo.dir + TURN_RIGHT
            if turtleInfo.dir >= 4 then turtleInfo.dir = turtleInfo.dir - 4 end
        end
    end
end

function digAndMove(movement)
    assert(type(movement) == "number", "digAndMove: Expected number.")

    if movement == FORWARD then
        turtle.dig()
        forward()
    elseif movement == UPWARD then
        turtle.digUp()
        upward()
    else 
        turtle.digDown()
        downward()
    end
end

function matchDirection(wantedDirection)
    assert(type(wantedDirection) == "number", "matchDirection: Expected number.")

    local dif = wantedDirection - turtleInfo.dir
    
    if dif < 0 then turnLeft(-dif)
    else turnRight(dif) end
end

 -- Retrace the turtle's last numMoves moves or as much as possible. 
function retrace(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "retrace: Expected number.")

    if numMoves > #movementHistory then
        numMoves = #movementHistory
    end
    
    if not checkForFuel(numMoves) then
      return false
    end

    for i=1, numMoves do
        local currMove = movementHistory[#movementHistory] 

        if currMove.dir ~= turtleInfo.dir then 
            matchDirection(currMove.dir)
        end

        if currMove.move == FORWARD then
            turtle.back(1)
        elseif currMove.move == BACKWARD then
            turtle.forward(1)
        elseif currMove.move == UPWARD then
            turtle.down(1)
        elseif currMove.move == DOWNWARD then
            turtle.up(1)
        else
            assert(false, "retrace: Unknown direction.")
        end
        table.remove(movementHistory)
    end
    return true
end

-- Returns the first found slot which contains the item searched.
function findItem(itemName)
    assert(type(itemName) == "string", "Expected string.")
    for i=1,16 do
        local itemInfo = turtle.getItemDetail(i)
        if itemInfo and itemInfo.name == itemName then
            return i
        end
    end
    return nil
end

function findItemAndSelect(itemName)
    local slotId = findItem(itemName)
    if(slotId) then
        turtle.select(slotId)
        return true
    end
    return false
end

--[=[Requires a starting block to be infront for the turtle. Uses dfs to mine the vein.
     Returns to start. If it does not have enough fuel it will not finish the vein]=]

BASIC_SCAN = 1      -- Just around, above and below
ADDITIONAL_SCAN = 2 -- Around, above, below and the two additional blocks making a line with the current one
function digVein(blockNames, scanLevel)
    assert(type(blockNames) == "table", "digVein: Expected table of strings.")

    scanLevel = scanLevel or BASIC_SCAN
    assert(type(scanLevel) == "number", "digVein: Expected scanLevel to be a number")

    local checked = {} -- The already checked blocks.
    local startingDir = turtleInfo.dir -- Used to track the coordinates

    -- Uses startingDir to calculate the coordinates after the next move. Also eww. Rework this.
    local function getCoord(x,y,z,movement)
        if movement == UPWARD then
            return {x,y+1,z}
        elseif movement == DOWNWARD then
            return {x,y-1,z}
        elseif movement == FORWARD then
            if turtleInfo.dir == startingDir then
                return {x+1,y,z}
            end
            if turtleInfo.dir == (startingDir + 1)%4 then
                return {x,y,z+1}
            end
            if turtleInfo.dir == (startingDir + 2)%4 then
                return {x-1,y,z}
            end
            if turtleInfo.dir == (startingDir + 3)%4 then
                return {x,y,z-1}
            end
        elseif movement == BACKWARD then
            if turtleInfo.dir == startingDir then
                return {x-1,y,z}
            end
            if turtleInfo.dir == (startingDir + 1)%4 then
                return {x,y,z-1}
            end
            if turtleInfo.dir == (startingDir + 2)%4 then
                return {x+1,y,z}
            end
            if turtleInfo.dir == (startingDir + 3)%4 then
                return {x,y,z+1}
            end
        else
            assert(false==true, "digVein::getCoord: Unknown direction")
        end
    end

    local function getKey(x,y,z)
        return tostring(x)..","..tostring(y)..","..tostring(z)
    end

    local function dfs(depth, x, y, z, innerScanLevel)
        checked[getKey(x,y,z)] = true
        local function dfsHelper(movement, hasBlockInfo, info, force)
            if (hasBlockInfo and blockNames[info.name]) or force then
                newCoord = getCoord(x,y,z,movement)
                if checked[getKey(newCoord[1],newCoord[2],newCoord[3])] then
                    return nil
                end
                if not checkForFuel(depth+2) then
                    return nil
                end
                digAndMove(movement)
                if not (hasBlockInfo and blockNames[info.name]) then
                    dfs(depth+1,newCoord[1],newCoord[2],newCoord[3], BASIC_SCAN)
                else
                    dfs(depth+1,newCoord[1],newCoord[2],newCoord[3], scanLevel)
                end
            end
        end

        dfsHelper(FORWARD,turtle.inspect())
        dfsHelper(UPWARD,turtle.inspectUp())
        dfsHelper(DOWNWARD,turtle.inspectDown())
        for i=1, 3 do
            turnLeft()
             -- we force the 1st and 3rd steps if additional scan is on
            local hasBlockInfo,info = turtle.inspect()
            dfsHelper(FORWARD, hasBlockInfo, info, innerScanLevel == ADDITIONAL_SCAN and (i==1 or i==3))
        end
        

        retrace()
    end

    dfs(0,0,0,0,scanLevel)
end

function treeFarm()
    local function findSaplingAndSelect()
        if(findItemAndSelect("minecraft:sapling")) then return true end
        if(findItemAndSelect("minecraft:birchSapling")) then return true end
        if(findItemAndSelect("minecraft:spruceSapling")) then return true end
        return false
    end
    local function plantSapling()
        if not findSaplingAndSelect() then return false end
        turtle.placeDown()
    end
    local function waitForLog()
        while true do
            local blockInfo = turtle.inspect()
            if string.find(blockInfo.name,"log") or string.find(blockInfo.name,"Log") then break end
            os.sleep(1)
        end
    end
end

digVein({["minecraft:log"]=true,["ThermalFoundation:Ore"]=true}, ADDITIONAL_SCAN)