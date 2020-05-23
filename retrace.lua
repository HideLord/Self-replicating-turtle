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
    assert(type(numMoves) == "number", "Expected number.")

    for i=1, numMoves do
        turtle.forward(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = FORWARD})
    end
end

function backward(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "Expected number.")
    
    for i=1, numMoves do
        turtle.back(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = BACKWARD})
    end
end

function upward(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "Expected number.")

    for i=1, numMoves do
        turtle.up(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = UPWARD})
    end
end

function downward(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "Expected number.")

    for i=1, numMoves do
        turtle.down(1)
        table.insert(movementHistory,{dir = turtleInfo.dir, move = DOWNWARD})
    end
end

function turnLeft(times)
    times = times or 1
    assert(type(times) == "number", "Expected number.")

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
    assert(type(times) == "number", "Expected number.")

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
    assert(type(movement) == "number", "Expected number.")

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
    assert(type(wantedDirection) == "number", "Expected number.")

    local dif = wantedDirection - turtleInfo.dir
    
    if dif < 0 then turnLeft(-dif)
    else turnRight(dif) end
end

 -- Retrace the turtle's last numMoves moves or as much as possible. 
function retrace(numMoves)
    numMoves = numMoves or 1
    assert(type(numMoves) == "number", "Expected number.")

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
        else
            turtle.up(1)
        end
        table.remove(movementHistory)
    end
    return true
end

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

--[=[Requires a log to be infront for the turtle. Uses dfs to mine the tree.
     Returns to start. If it does not have enough fuel it will not finish the tree.
     complete(bool) signifies whether to search surrounding blocks for logs.
     Much more expensive and slow, but chops more complex trees]=]
function chopTree(logType, complete)
    assert(type(logType) == "string", "Expected string.")

    local checked = {} -- The already checked blocks.
    local startingDir = turtleInfo.dir -- Used to track the coordinates

    -- Uses startingDir to calculate the coordinates after the next move. Also eww. Rework this.
    local function getCoord(x,y,z,movement)
        if movement == UPWARD then
            return {x=x,y=y+1,z=z}
        elseif movement == DOWNWARD then
            return {x=x,y=y-1,z=z}
        elseif movement == FORWARD then
            if turtleInfo.dir == startingDir then
                return {x=x+1,y=y,z=z}
            end
            if turtleInfo.dir == (startingDir + 1)%4 then
                return {x=x,y=y,z=z+1}
            end
            if turtleInfo.dir == (startingDir + 2)%4 then
                return {x=x-1,y=y,z=z}
            end
            if turtleInfo.dir == (startingDir + 3)%4 then
                return {x=x,y=y,z=z-1}
            end
        elseif movement == BACKWARD then
            if turtleInfo.dir == startingDir then
                return {x=x-1,y=y,z=z}
            end
            if turtleInfo.dir == (startingDir + 1)%4 then
                return {x=x,y=y,z=z-1}
            end
            if turtleInfo.dir == (startingDir + 2)%4 then
                return {x=x+1,y=y,z=z}
            end
            if turtleInfo.dir == (startingDir + 3)%4 then
                return {x=x,y=y,z=z+1}
            end
        else
            assert(false==true, "chopTree::getCoord: Unknown direction")
        end
    end

    local function dfs(depth, x, y, z)
        checked[{x,y,z}] = true
        
        local function dfsHelper(movement, hasBlockInfo, info)
            if hasBlockInfo and string.find(info.name,logType) then
                digAndMove(movement)
                newCoord = getCoord(x,y,z,movement)
                dfs(depth+1,newCoord.x,newCoord.y,newCoord.z)
            end
        end
        
        dfsHelper(FORWARD,turtle.inspect())
        for i=1, 3 do
            turnLeft()
            dfsHelper(FORWARD,turtle.inspect())
        end
        dfsHelper(UPWARD,turtle.inspectUp())
        dfsHelper(DOWNWARD,turtle.inspectDown())

        retrace()
    end

    dfs(0,0,0,0)
    matchDirection(startingDir)
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

chopTree("log", false)