-- Débogueur Visual Studio Code tomblind.local-lua-debugger-vscode
if pcall(require, "lldebugger") then
    require("lldebugger").start()
end

-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf("no")
love.graphics.setDefaultFilter("nearest")
math.randomseed(os.time())

-- Retourne la distance entre deux points
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Renvoie l'angle entre deux vecteurs supposant la même origine.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end


local lstSprites = {}
local human = {}
local leftHeart  = 0 
local rightHeart = 0
local alert = 0

local zStates = {
    NONE = "none",
    WALK = "walk",
    PURSUIT = "pursuit",
    ATTACK = "attack",
    CHANGEDIR = "changedir"
}

local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()


--Funciton qui crée un zombie
function CreateZombie()
    local myZombie = CreateSprite(lstSprites, "zombie", "monster_", 2)
    myZombie.x = math.random(0, screenWidth)
    myZombie.y = math.random(0, screenHeight)
    myZombie.vx = 0
    myZombie.vy = 0
    myZombie.speed = math.random(5, 100)
    myZombie.states = zStates.NONE
    myZombie.range = math.random(10, 150)
    myZombie.target = nil

end

function CreateSprite(pLst, pType, pImgName, nbFrame)
    local mySprite = {
        x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        offsetX = 0,
        offsetY = 0,
        type = pType,
        image = {},
        currentFrame = 1,
        width = 0,
        height = 0
    }

    for index = 1, nbFrame do 
        local fileName = "/assets/"..pImgName..tostring(index)..".png"
        mySprite.image[index] = love.graphics.newImage(fileName)
    end

    --Valorisation des champs de nos agent sans distinmction de type
    mySprite.width = mySprite.image[1]:getWidth()
    mySprite.height = mySprite.image[1]:getHeight()
    mySprite.offsetX = mySprite.width/2
    mySprite.offsetY = mySprite.height/2

    table.insert(pLst, mySprite)

    return mySprite
end

--Machine a ëtats
function UpdateZombies(pZombie, pEntities)

    if pZombie.states == zStates.NONE then

        pZombie.states = zStates.CHANGEDIR

    elseif pZombie.states == zStates.WALK then

        local collider = false

        if pZombie.x < 0 then
            pZombie.x = 0
            collider = true
        end
    
        if pZombie.x > screenWidth - pZombie.width then
            pZombie.x = screenWidth - pZombie.height
            collider = true
            pZombie.states = zStates.CHANGEDIR
        end
    
        if pZombie.y < 0 then
            pZombie.y = 0
            collider = true
            pZombie.states = zStates.CHANGEDIR
        end
    
        if pZombie.y > screenHeight - pZombie.width then
            pZombie.y = screenHeight - pZombie.height
            collider = true
        end

        if collider then
            pZombie.states = zStates.CHANGEDIR
        end

        --Chercher un Humain
        for key, sprite in ipairs(pEntities) do
            if sprite.type == "humain" and sprite.visible == true then
                local distance = math.dist(pZombie.x, pZombie.y, sprite.x, sprite.y)
                if distance < pZombie.range then
                    pZombie.states = zStates.PURSUIT
                    pZombie.target = sprite
                end
            end
        end

    elseif pZombie.states == zStates.ATTACK then

    if math.dist(pZombie.x, pZombie.y, pZombie.target.x, pZombie.target.y) > 5  then
        pZombie.states = zStates.PURSUIT
    else
        pZombie.target.life = pZombie.target.life - 1/8
    end

    if pZombie.target.visible == false then
        pZombie.states = zStates.CHANGEDIR
    end

    elseif pZombie.states == zStates.PURSUIT then
        
        if pZombie.target == nil then

            pZombie.states = zStates.CHANGEDIR

        -- Notre humain est out of range du zombie
        elseif math.dist(pZombie.x, pZombie.y, pZombie.target.x, pZombie.target.y) > pZombie.range and pZombie.target.type == "humain" then

            pZombie.states = zStates.CHANGEDIR

        -- notre humain est a proximité de morsure du zombie
        elseif math.dist(pZombie.x, pZombie.y, pZombie.target.x, pZombie.target.y) < 5 and pZombie.target.type == "humain" then
            pZombie.states = zStates.ATTACK
            pZombie.vx = 0
            pZombie.vy = 0

        else
            --Mouvement erratique quand le zombie atteint la cible
            local destX, destY
            destX = math.random(pZombie.target.x - math.random(15, 55), pZombie.target.x + math.random(15, 65))
            destY = math.random(pZombie.target.y - math.random(15, 55), pZombie.target.y + math.random(15, 65))
    
            -- On créer un point A et B et on afin que l'entité parcours cette distance en ajoutant de la velocité 
            local angle = math.angle(pZombie.x, pZombie.y, destX, destY)
            pZombie.vx = pZombie.speed * math.cos(angle)
            pZombie.vy = pZombie.speed * math.sin(angle)

        end


    elseif pZombie.states == zStates.CHANGEDIR then

        local angle = math.angle(pZombie.x, pZombie.y, math.random(screenWidth), math.random(screenHeight))
        pZombie.vx = pZombie.speed * math.cos(angle)
        pZombie.vy = pZombie.speed * math.sin(angle)
        pZombie.states = zStates.WALK

    end

end

function humanLife(entitie, posX, posY)
    -- on ajoute nos images de demi coeur
    leftHeart = love.graphics.newImage("/assets/leftHeart.png")
    rightHeart = love.graphics.newImage("/assets/rightHeart.png")

    local heartWidth = leftHeart:getWidth()
    local x = posX
    local y = posY


    -- on cheque si les pdv de l'humain son pairs ou impair
    for i = 1, entitie.life do 
        -- on cheque si le nombre de pv est impair
        local impair = i % 2 ~= 0

        --On affiche nos image en fonction du nb de pv pairs ou impairs pour l'affichage gauche ou droite
        if impair == true then
            love.graphics.draw(leftHeart, x, y, 0, 1, 1)
        else
            love.graphics.draw(rightHeart, x, y, 0, 1, 1)
        end

        -- si le nb de pv est pairs on decale la position du coeur de largeur 
        if impair == false then
            x = x + heartWidth/2
        end
    end


end

function love.load()

    alert = love.graphics.newImage("/assets/alert.png")

    human = CreateSprite(lstSprites, "humain", "player_", 4)
    human.x = screenWidth/2
    human.y = screenWidth/2
    human.life = 100
    human.visible = true

    for nZombie = 1, 10 do
        CreateZombie()
    end

     function AnimeFrame(dt)
        for key, value in ipairs(lstSprites) do 
            if value.type == "humain" then
                value.currentFrame = value.currentFrame + 10 * dt
    
                if value.currentFrame >= #value.image + 1 then
                    value.currentFrame = 1
                end
            end
        end
    end
end

function love.update(dt)

    if human.life <= 0 then
        human.visible = false

        human.life = 0
    end

    for key, value in ipairs(lstSprites) do 
        if value.type == "zombie" then
            value.currentFrame = value.currentFrame + 10 * dt

            if value.currentFrame >= #value.image + 1 then
                value.currentFrame = 1
            end
        end
           -- velocity
           value.x = value.x + value.vx * dt
           value.y = value.y + value.vy * dt
    end

    if love.keyboard.isDown("up") then
        human.y = human.y - 1
        AnimeFrame(dt)
    end
    
    if love.keyboard.isDown("down") then
        human.y = human.y + 1
        AnimeFrame(dt)
    end

    if love.keyboard.isDown("left") then
        human.x = human.x - 1
        AnimeFrame(dt)
    end

    if love.keyboard.isDown("right") then
        human.x = human.x + 1
        AnimeFrame(dt)
    end

    function love.keyreleased(key)
        if key == "up" then
            human.currentFrame = 1
        end

        if key == "down" then
            human.currentFrame = 1
        end

        if key == "left" then
            human.currentFrame = 1
        end

        if key == "right" then
            human.currentFrame = 1
        end
    end 

    for index, zombie in ipairs(lstSprites) do
        if zombie.type == "zombie" then
            UpdateZombies(zombie, lstSprites)
        end
    end
end

function love.draw()

    for index, zombie in ipairs(lstSprites) do
        if zombie.type == "zombie" then

            if zombie.states == zStates.PURSUIT then
                love.graphics.draw(alert, zombie.x, zombie.y - zombie.height * 2.5, 0, 2, 2, alert:getWidth() / 2, alert:getHeight() / 2)
            end
            
        end

    end

    for key, value in ipairs(lstSprites) do

        love.graphics.print("frame"..tostring(value.currentFrame))

        if value.type == "zombie" then
            
            love.graphics.print(tostring(value.states), value.x + 15, value.y + 15)

            love.graphics.draw(value.image[math.floor(value.currentFrame)], value.x, value.y, 0, 3, 3, value.offsetX, value.offsetY)
            -- love.graphics.print("vx "..tostring(value.vx), value.x + 30, value.y + 30)
            -- love.graphics.print("range "..tostring(value.range), value.x, value.y)
            -- love.graphics.print("target "..tostring(value.target), value.x + 45, value.y + 45)
        elseif human.visible == true then
            love.graphics.draw(value.image[math.floor(value.currentFrame)], value.x, value.y, 0, 3, 3, value.offsetX, value.offsetY)
        end

    end
    humanLife(human, 1, 25)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end