--TODO:
--delete node DONE
--fix textbox display direction bug--
--make text go to next line when oversized DONE
--better text box DONE
-- improve text box code readability and adjustability
-- shift to open multiple nodes at once DONE
--undo/redo node deletion/placement
--better graphics
--function that organizes the nodes list in order of appearance (left to right) DONE
    --saving and loading-- DONE
    --alternate direction of text box DONE
--options/customization menu--
    --change colour of everything--
    --saving and loading files-- DONE
    --clearing timeline--
--timeline elongation functionality--

--POSTLAUNCH TODO:
--interface
    --show saving icon in top right when autosaving and/or manual saving
    --add color customization capabilities, gear icon in top left
    --better textbox, 
        --blinking selection indicator 
        --selecting different editing points of string 
        --select large parts of a string via click and drag
--save and load info for multiple stories via more data storage devilry 
--alternate node type (visual change only)
--optional character limit mode, for maximum creativity
--adjustable window size
--custom windows taskbar--

local utf8 = require("utf8")

mouse = {}
nodePreview = {}
nodes = {}
deletedNodes = {}

timelineHeight = (love.graphics.getHeight( )/2)
numNodes = 0
selectedNode = nil
previewNodes = {}
gameFont = love.graphics.newFont(12)
maxLineLength = 150
maxCharacterLength = 300 --unimportant, for now-- 
timer = 0.0
saveFile = love.filesystem.newFile("data.txt")

custom = {}
custom.nodeColor = {217/255,62/255,44/255}
custom.nodeSize = 20
custom.nodeStyle = "fill"
custom.selectedNodeStyle = "line"

custom.selectedNodeColor = {217/255,62/255,44/255}

custom.textboxBgColor = {217/255,62/255,44/255}
custom.textboxTextColor = {217/255,62/255,44/255}
custom.textboxStyle = "line"

custom.previewColor = {0,1,0}
custom.previewSize = 0

custom.backgroundColor = {235/255,219/255,195/255}

custom.autosaveFrequency = 10

function love.load()
    loadData()
    
    love.graphics.setBackgroundColor(custom.backgroundColor)
    nodePreview.x = 300
    nodePreview.y = 300

    love.keyboard.setKeyRepeat(true)

    --love.window.setMode(360, 640, {resizable = true})--
end

function love.update(dt) 
    --to track mouse for preview button--
    timer = timer + dt

    if timer > 10.0 then
        saveData()
        timer = 0.0
    end

    nodePreview.x, y = love.mouse.getPosition()
    if nodePreview.x < 50 then
        nodePreview.x = 50
    elseif nodePreview.x > love.graphics.getWidth()-50 then
        nodePreview.x = love.graphics.getWidth()-50
    end
end 

function love.draw()
    love.graphics.setLineWidth(2)
    love.graphics.setFont(gameFont)

    --draw all the nodes--
    for i, value in ipairs(nodes) do
        if nodes[i].isSelected then
            renderTextbox(nodes[i], nodes[i].textbox, custom.textboxBgColor, custom.textboxTextColor) --SHOW STRING CONTENTS OF NODE change the node.textbox value in love.update 
            
            love.graphics.setColor(custom.selectedNodeColor)
            nodes[i].color = custom.selectedNodeColor
            love.graphics.circle(custom.selectedNodeStyle, nodes[i].x, timelineHeight, custom.nodeSize)
        else
            love.graphics.setColor(custom.nodeColor)
            nodes[i].color = custom.nodeColor
            love.graphics.circle(custom.nodeStyle, nodes[i].x, timelineHeight, custom.nodeSize)
        end
        
    end

    --draw preview for node, follows cursor--
    love.graphics.setColor(custom.previewColor)
    love.graphics.circle("fill", nodePreview.x, timelineHeight, custom.previewSize)

end

function love.textinput(t)
    if selectedNode then
        if #selectedNode.text < maxCharacterLength then --# is shorthand for length of string--
            local text = selectedNode.text .. t  
            selectedNode.text = text
        end
    end  
end

function love.keypressed(key)

    if key == "backspace" then
        if selectedNode then
            local byteoffset = utf8.offset(selectedNode.text, -1)
            if byteoffset then
                selectedNode.text = string.sub(selectedNode.text, 1, byteoffset - 1)
            end
        end
    end

    if love.keyboard.isDown("lctrl") then
        if love.keyboard.isDown("s") then
            saveData()
        end

        if love.keyboard.isDown("z") then
            if #deletedNodes > 0 then
                table.insert(nodes, table.remove(deletedNodes, #deletedNodes))
            end
        end
    end

    if key == "return" then
        selectedNode.text = selectedNode.text .. "\n"
    end
end

function love.mousepressed(x, y, button, istouch, presses)

    if button == 1 and love.keyboard.isDown("lshift") then --preview contents of multiple nodes--
        selectedNode = clickedNode(x, y, custom.nodeSize, nodes)
        if selectedNode then
            changeTextboxPosition(nodes, selectedNode)
            selectedNode.isSelected = true
        else
            closeNodes()
        end

    elseif button == 1 then --either make new node, or click existing node--
        
        if nodes and selectedNode == nil then --attempt to select nearest clicked node--
            selectedNode = clickedNode(x,y,custom.nodeSize, nodes)
        end

        if selectedNode == nil and (clickedNode(x,y,custom.nodeSize, nodes) == nil) then --a node hasn't been clicked, make new node at spot-- 
            --check if in range of other nodes--
            newNode(nodes, nodePreview.x, timelineHeight, "", {0, 1, 1}, false, false)
        elseif distanceBetween(x, y, selectedNode.x, selectedNode.y) < custom.nodeSize then --if node clicked, open a node--
            if not selectedNode.isSelected then --the node u clicked hasnt been clicked yet, so open that and close all other nodes--
                closeNodes()
                selectedNode.isSelected = true --open selected node and change graphic--
            else --the node u clicked has been clicked before, so close it (and save contents, which is not implemented)--
                selectedNode.isSelected = false 
            end
        else
            closeNodes()
            selectedNode = nil 
        end

    elseif button == 2 then 
        if nodes then
            for i, value in ipairs(nodes) do --if a node is right clicked, delete it--
                if distanceBetween(x, y, nodes[i].x, nodes[i].y) < custom.nodeSize then
                    if nodes[i] == selectedNode then --deselect
                        selectedNode = nil
                    end
                    deleteNode(nodes, nodes[i]) --delete node
                    break
                end
            end
        end  
        end
end

function renderTextbox(theNode, direction, backgroundColor, textColor) --textcolor parameter in the works
    love.graphics.setColor(backgroundColor)
    if direction then
        --love.graphics.rectangle("fill", theNode.x - maxLineLength/2 - 5, theNode.y - gameFont:getHeight() - 35 - 5, maxLineLength + 10, gameFont:getHeight() + 10, 4, 4)

        local width, lines = gameFont:getWrap(theNode.text, maxLineLength)
        local verticalOffset = #lines * gameFont:getHeight()

        if verticalOffset < gameFont:getHeight() then
            verticalOffset = gameFont:getHeight()
        end

        love.graphics.rectangle(custom.textboxStyle, theNode.x - maxLineLength/2 - 5, theNode.y - verticalOffset - 35 - 5, maxLineLength + 10, verticalOffset + 10, 4, 4)
        love.graphics.printf({textColor, theNode.text}, theNode.x - maxLineLength/2, theNode.y - verticalOffset - 35, maxLineLength, "left")

    elseif not direction then
        --love.graphics.rectangle("fill", theNode.x - maxLineLength/2 - 5, theNode.y + gameFont:getHeight() + 10 + 5, maxLineLength + 10, gameFont:getHeight() + 10, 4, 4)

        local width, lines = gameFont:getWrap(theNode.text, maxLineLength)
        local verticalOffset = #lines * gameFont:getHeight()

        if verticalOffset < gameFont:getHeight() then
            verticalOffset = gameFont:getHeight()
        end

        love.graphics.rectangle(custom.textboxStyle, theNode.x - maxLineLength/2 - 5, theNode.y + gameFont:getHeight() + 10 + 5, maxLineLength + 10, verticalOffset + 10, 4, 4)
        love.graphics.printf({textColor, theNode.text}, theNode.x - maxLineLength/2, theNode.y  + 35, maxLineLength, "left")

    end
end

function changeTextboxPosition(nodeList, node)
    local nodeIndex = findNodeIndex(nodeList, node)
    if nodeIndex then
        local leftNode = nil
        local theNode = nodeList[nodeIndex]
        local rightNode = nil

        for i=nodeIndex+1, #nodeList do
            if nodeList[i].isSelected then
                rightNode = nodeList[i]
                break
            end
        end

        for i=nodeIndex-1, 1, -1 do
            if nodeList[i].isSelected then
                leftNode = nodeList[i]
                break
            end
        end

        --if leftside node or rightside node enroaches on territory then...
        if leftNode and leftNode.textbox and leftNode.isSelected and (theNode.x - leftNode.x <= (maxLineLength+10)) then
            node.textbox = false
        elseif rightNode and rightNode.textbox and rightNode.isSelected and (rightNode.x - theNode.x <= (maxLineLength+10)) then
            node.textbox = false
        end
    end
end

function printNodes(nodes)
    print("printing nodes---------")
    for i, value in ipairs(nodes) do
        print(nodes[i].x)
    end
    print("done printing nodes-------")
end

counter = 1

function quicksortNodes(nodeList, first, last) --only called when creating new nodes--
    counter = counter + 1
    if first < last then
        local placeholder = partition(nodeList, first, last)

        quicksortNodes(nodeList, first, placeholder-1)
        quicksortNodes(nodeList, placeholder+1, last)

        return nodeList
    end
end

function partition(nodeList, first, last)
    
    local pivot = nodeList[last].x
    local i = first-1

    for j=first, last-1 do
        if nodeList[j].x < pivot then --if current element is less than pivot, move to the left side of the divide
            i = i + 1
            swap(nodeList, i, j)
        end
    end
    swap(nodeList, i+1, last) --move pivot to the middle of divide
    return(i+1) --new location of pivot
end

function swap(nodeList, a, b)
    local placeholder = nodeList[a]

    nodeList[a] = nodeList[b]
    nodeList[b] = placeholder
end

function clickedNode(mousex, mousey, nodeRadius, nodeList)
    for i, value in ipairs(nodeList) do
        if distanceBetween(mousex, mousey, nodeList[i].x, nodeList[i].y) < nodeRadius then
            return nodeList[i]
        end
    end
    return nil
end

function newNode (nodeList, x, y, text, color, isHovered, isSelected) 
    deletedNodes = {}

    local node = {}
    node.x = x
    node.y = y
    node.text = text
    node.color = {0, 1, 1}
    node.isHovered = false
    node.isSelected = false
    node.textbox = true --true is render up, false is render down--

    if #nodeList < 1 then --special case when node is first in list--
        table.insert(nodeList, node)
    elseif nodeList[#nodeList].x > x then --node isn't placed at the end--
        table.insert(nodeList, node)
        quicksortNodes(nodes, 1, #nodes)
    else --node is placed at the end--
        table.insert(nodeList, node)
    end

    return node
end

function findNodeIndex(nodeList, node)
    for i, value in ipairs(nodeList) do
        if nodeList[i] == node then  
            return i
        end
    end
end

function closeNodes()
    for i, value in ipairs(nodes) do
        nodes[i].isSelected = false
        nodes[i].textbox = true
    end
end

function deleteNode (nodeList, x) --deletes the specified node--
    if x then
        for i, value in ipairs(nodes) do
            if (nodes[i] == x) then
                local removedNode = table.remove(nodeList, i)
                removedNode.isSelected = false
                table.insert(deletedNodes, removedNode)
                break
            end
        end
    end
end

function loadNode(nodeList, x, text) --for loading--
    local node = {}
    node.x = x
    node.y = timelineHeight
    node.text = text
    node.color = custom.nodeColor
    node.isHovered = false
    node.isSelected = false
    node.textbox = true

    table.insert(nodeList, node)
end

function loadData() 
    saveFile:open("r")
    chunk, errormsg = love.filesystem.load( "data.txt" )()
    saveFile:close()
   
end

function saveData()
    saveFile:open("w")

    print("saving game")

    local data = ""
    for i, value in ipairs(nodes) do
        data = data .. "loadNode(" .. "nodes,".. nodes[i].x .. ",'" .. nodes[i].text .. "')" 
    end
    success, message = love.filesystem.write( "data.txt", data)

    if success then
        print("game save complete")
    else
        print("game save failed " .. message)
    end
    saveFile:close()
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end