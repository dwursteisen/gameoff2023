local Pill = {
    x = 0,
    y = 0,
    frames_start = 0,
    frames = {1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
    frame = 0,
    t = 0,
    type = "pill",
    active = true
}

local Key = {
    x = 0,
    y = 0,
    frames_start = 18,
    frames = {1.5, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
    frame = 0,
    t = 0,
    type = "key",
    active = true,
    track = false
}

local Door = {
    x = 0,
    y = 0,
    frames_start = 27,
    frames = {0.1},
    frame = 0,
    t = 0,
    type = "door",
    active = true,
    state = 0,
    dt = 0,

    animation = {
        idle = {0.1},
        opening = {0.1, 0.1, 0.1, 0.1, 0.1},
        open = {0.1}
    },

    animation_start = {
        idle = 28,
        opening = 29,
        open = 33
    }
}

local SmallDoor = {
    x = 0,
    y = 0,
    frames_start = 44,
    frames = {1},
    frame = 0,
    t = 0,
    type = "small_door",
    active = true,
    state = 0,
    dt = 0
}

local Player = {
    -- position
    x = 0,
    y = 0,
    -- direction
    dx = 0,
    dy = 0,
    -- velocity
    vy = 0, -- used for jumping only
    -- animations
    frames_start = 34,
    frames = {1, 0.1, 0.1, 0.1},
    frame = 0,
    t = 0,
    type = "player",
    active = true,
    animation = {
        idle = {1, 0.1, 0.1, 0.1},
        walking = {0.1, 0.1, 0.1, 0.1},
        falling = {0.1},
        idle_small = {1}
    },

    animation_start = {
        idle = 34,
        walking = 39,
        falling = 43,
        idle_small = 43
    },
    -- player data
    pill = 0,
    state = 1, -- 0 == small ; 1 = tall
    ground = true,
    key = 0,
    dt = 0,
    small_door = false
}

local Explosion = {
    -- position
    x = 0,
    y = 0,
    -- animations
    frames_start = 9,
    frames = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
    frame = 0,
    t = 0,
    type = "explosion",
    active = false
}

function _init()
    pills = {}
    key = {}
    animated = {}
    doors = {}
    touchable = {}
    track = {}
    small_doors = {}
    explosion = new(Explosion)

    table.insert(animated, explosion)

    --
    local p = map.entities["Pill"]
    if p then
        for k, v in pairs(p) do
            local p = new(Pill, v)
            table.insert(pills, p)
            table.insert(animated, p)
            table.insert(touchable, p)
        end
    end

    for k, v in pairs(map.entities["Key"]) do
        local p = new(Key, v)
        table.insert(key, p)
        table.insert(animated, p)
        table.insert(touchable, p)
    end

    for k, v in pairs(map.entities["Door"]) do
        local p = new(Door, v)
        table.insert(doors, p)
        table.insert(animated, p)
        table.insert(touchable, p)
    end

    p = map.entities["SmallDoor"]
    if p then

        for k, v in pairs(p) do
            local p = new(SmallDoor, v)

            table.insert(small_doors, p)
            table.insert(animated, p)
            table.insert(touchable, p)
        end
    end

    for k, v in pairs(map.entities["Spawn"]) do
        player = new(Player, v)
        if (v.customFields.small) then
            player.state = 0
        end
        switch_player()
        table.insert(animated, player)
    end
end

function switch_player()
    if player.state == 0 then
        player.frames = player.animation.idle_small
        player.frames_start = player.animation_start.idle_small
    else
        player.frames = player.animation.idle
        player.frames_start = player.animation_start.idle
    end
    player.frame = 0
end

function _update()
    -- animate all animatable
    for k, v in rpairs(animated) do
        v.t = v.t + tiny.dt
        if v.t > v.frames[v.frame + 1] then
            v.t = 0
            v.frame = (v.frame + 1) % (#v.frames)
        end
    end

    move_player()
    state_player()
    touch_player()
    track_player()
    next_level()

end

function next_level()
    for d in all(doors) do
        if (d.frame >= 4 and d.state == 1) then
            d.frames_start = d.animation_start.open
            d.frames = d.animation.open
            d.frame = 0
            d.state = 2
        elseif (d.state == 2) then
            if (d.dt >= 3) then
                map.level(map.level() + 1)
                _init()
            else
                d.dt = d.dt + tiny.dt
            end
        end
    end
end
--[[
  Change/manage the state of the player regarding if its tall
  or small.

  It will trigger events on entities that match its status.

  ie: use mechanism that react when the state is chaging.
]] -- 
function state_player()
    if player.pill > 0 and ctrl.pressed(keys.enter) then
        player.pill = player.pill - 1
        player.state = (player.state + 1) % 2
        explosion.x = player.x
        explosion.y = player.y
        explosion.active = true
        explosion.frame = 0
    end
    if (explosion.frame >= 8) then
        explosion.active = false
    end

    switch_player()
end
--[[
 Move entities to track the player.
 This function will be used mostly to keys to track the player
]] --
function track_player()
    -- object can track only big player
    if player.state == 0 then
        return
    end

    local x = 0
    local y = player.y

    if player.dy > 0 then -- going down
        y = player.y - 16
    elseif player.dy < 0 then -- going up
        y = player.y + 16
    end

    if player.dx > 0 then -- going right
        x = player.x - 16
    elseif player.dx < 0 then -- going left
        x = player.x + 16
    end

    for index, t in rpairs(track) do
        t.x = juice.linear(t.x, x, 0.05)
        t.y = juice.linear(t.y, y, 0.05)

    end
end
--[[
   Check if the player is touching any touchable entities
   The entity will be removed from the table
   and, regarding the kind of entity, 
   will update something, somewhere!
]] --
function touch_player()
    player_hitbox = {
        x = player.x + 2,
        y = player.y,
        width = 12,
        height = 16
    }
    local collide_small_door = false

    for index, t in rpairs(touchable) do
        if t.active and math.roverlap(player_hitbox, {
            x = t.x + 2,
            y = t.y + 4,
            width = 12,
            height = 12
        }) then
            -- Hit between the player and the entity
            if (t.type == "key" and t.track == false and player.state == 1) then
                -- the key will track the player
                table.insert(track, t)
                t.track = true
                player.key = player.key + 1
            elseif (t.type == "pill") then
                t.active = false
                player.pill = player.pill + 1
            elseif (t.type == "door" and player.key > 0 and t.state == 0) then
                -- opening door
                t.frames_start = t.animation_start.opening
                t.frames = t.animation.opening
                t.frame = 0
                t.state = 1
            elseif (t.type == "small_door" and player.small_door == false and player.state == 0) then
                player.small_door = true
                collide_small_door = true
                local target = t.customFields.target.entityIid
                for s in all(small_doors) do
                    if s.iid == target then
                        player.x = s.x
                        player.y = s.y
                        --
                    end
                end
            elseif (t.type == "small_door") then
                collide_small_door = true
            end
        end
    end

    if (collide_small_door == false) then
        player.small_door = false
    end

end
--[[
  Check the control and create a projection of the next move
  Update the projection regarding if the move is allowed or not.
  A move will be refused because of an obstacle. 
]] --
function move_player()
    -- update player move
    local next_move = {
        x = 0,
        y = 1.5
    }
    if (ctrl.pressing(keys.left)) then
        next_move.x = -1
        player.dx = -1
        player.flip = true
    elseif ctrl.pressing(keys.right) then
        next_move.x = 1
        player.dx = 1
        player.flip = false
    end

    -- horizontal check
    local next_cell = map.to(player.x + next_move.x + 4, player.y + 4)

    local flag = map.flag(next_cell)

    if flag == 1 then
        next_move.x = 0
    end

    next_cell = map.to(player.x + next_move.x + 16, player.y + 4)

    flag = map.flag(next_cell)

    if flag == 1 then
        next_move.x = 0
    end

    player.x = player.x + next_move.x

    -- vertical check
    -- TODO: jump only if small ?
    if ctrl.pressed(keys.up) then
        player.dy = -1
        if player.ground then
            player.vy = -20
            player.ground = false
        end
    else
        player.dy = 1
    end

    next_move.y = next_move.y + player.vy

    player.vy = math.max(player.vy - 1, 0)

    next_cell = map.to(player.x + 16, player.y + 16 * player.dy + next_move.y)

    flag = map.flag(next_cell)

    if flag ~= 0 then
        next_move.y = 0
        player.dy = 0
        player.ground = true

        -- player.y = map.from(next_cell).y + 1
    end

    player.y = player.y + next_move.y
end

function _draw()
    gfx.cls()

    map.draw()

    for k, v in rpairs(animated) do
        if v.active then
            spr.draw(v.frames_start + v.frame, v.x, v.y, v.flip)
        end
    end

    print("Pills: " .. player.pill, 18, 18)

    for d in all(doors) do
        if (d.state == 2) then
            shape.rectf(0, 0, juice.powIn4(0, 256, d.dt / 3), 256, 1)
        end
    end
end
