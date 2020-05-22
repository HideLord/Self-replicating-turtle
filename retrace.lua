turtleInfo = {dir = 0}
movementHistory = {}

 --[=[
    Constants used to indicate movement or direction.   
 ]=]
FORWARD = 0;
BACKWARD = 1;
UPWARD = 2;
DOWNWARD = 3;

TURN_RIGHT = 1;
TURN_LEFT = 3; -- 3 to avoid negative numbers

 --[=[
    required is the number of blocks the trip is going to take.
    Checks if there is enough fuel and refuels if needed.
 ]=]
function checkForFuel(required)
    required = required or 640
    if turtle.getFuelLevel() < required then
        for i = 1, 16 do
            item = turtle.getItemDetail(i);

            if item and item.name == "minecraft:coal" then
                turtle.select(i);
                while turtle.getItemCount(i) > 0 and 
                      turtle.getFuelLevel() < required do turtle.refuel(1); end
                if turtle.getFuelLevel() >= required then
                    return true;
                end
            end

        end
        return false;
    else
        return true;
    end
end

 -- Wrapper functions to track movement history.
function forward(numMoves)
    numMoves = numMoves or 1;
    for i=1, numMoves do
        turtle.forward(1);
        table.insert(movementHistory,{dir = turtleInfo.dir, move = FORWARD});
    end
end

function backward(numMoves)
    numMoves = numMoves or 1;
    for i=1, numMoves do
        turtle.back(1);
        table.insert(movementHistory,{dir = turtleInfo.dir, move = BACKWARD});
    end
end

function upward(numMoves)
    numMoves = numMoves or 1;
    for i=1, numMoves do
        turtle.up(1);
        table.insert(movementHistory,{dir = turtleInfo.dir, move = UPWARD});
    end
end

function downward(numMoves)
    numMoves = numMoves or 1;
    for i=1, numMoves do
        turtle.down(1);
        table.insert(movementHistory,{dir = turtleInfo.dir, move = DOWNWARD});
    end
end

function turnLeft(times)
    times = times or 1;
    times = times % 4;
    if(times > 2) then
        turnRight(times-2);
    else
        for i=1, times do
            turtle.turnLeft();
            turtleInfo.dir = turtleInfo.dir + TURN_LEFT;
            if turtleInfo.dir >= 4 then turtleInfo.dir = turtleInfo.dir - 4; end
        end
    end
end

function turnRight(times)
    times = times or 1;
    times = times % 4;
    if(times > 2) then
        turnLeft(times-2);
    else
        for i=1, times do
            turtle.turnRight();
            turtleInfo.dir = turtleInfo.dir + TURN_RIGHT;
            if turtleInfo.dir >= 4 then turtleInfo.dir = turtleInfo.dir - 4; end
        end
    end
end

 -- Simple tunnel 1x1. Checks for trip to and back fuel.
function tunnelForward(blocks)
    if not checkForFuel(blocks * 2) then return false; end
    for i = 1, blocks do
        turtle.dig();
        forward();
    end
    return true;
end

function matchDirection(wantedDirection)
    if wantedDirection > turtleInfo.dir + 2 then
        turtle.turnLeft();
        turtle.turnLeft();
    elseif wantedDirection + 2 < turtleInfo.dir then
        turtle.turnRight();
        turtle.turnRight();
    elseif wantedDirection == turtleInfo.dir+1 then
        turtle.turnRight();
    else
        turtle.turnLeft();
    end
    turtleInfo.dir = wantedDirection;
end

 -- Retrace the turtle's last numMoves moves or as much as possible. 
function retrace(numMoves)
    numMoves = numMoves or 1;
    if numMoves > #movementHistory then
        numMoves = #movementHistory
    end
    
    if not checkForFuel(numMoves) then
      return false;
    end

    for i=1, numMoves do
        currMove = movementHistory[#movementHistory]; 

        if currMove.dir ~= turtleInfo.dir then 
            matchDirection(currMove.dir);
        end

        if currMove.move == FORWARD then
            turtle.back(1);
        elseif currMove.move == BACKWARD then
            turtle.forward(1);
        elseif currMove.move == UPWARD then
            turtle.down(1);
        else
            turtle.up(1);
        end
        table.remove(movementHistory);
    end
    return true;
end

tunnelForward(5);
turnRight();
tunnelForward(5);
turnLeft(3);
tunnelForward(5);
retrace(123123);
