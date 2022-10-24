gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

-- util.no_globals()

local isConfiguring = false
local distance = 100
local threshold = 22

local active = false
local video_one
local video_two
local playlist, video

local font = resource.load_font("robotomono.ttf")

util.data_mapper{
    state = function(state)
        distance = tonumber(state) -- comes in as string!!!
    end,
    configure = function(configure)
        isConfiguring = configure == "1"
    end,
}

util.json_watch("config.json", function(config)
    playlist = {}

    pp(config)
    for _, item in ipairs(config.playlist) do
        if item.duration > 0 then
            local format = item.file.metadata and item.file.metadata.format
            local duration = item.duration
            playlist[#playlist+1] = {
                duration = duration,
                format = format,
                asset_name = item.file.asset_name,
                type = item.file.type,
            }
        end
    end
    print("new playlist")
    pp(playlist)

    video_one = resource.open_file(playlist[1].asset_name)
    video_two = resource.open_file(playlist[2].asset_name)

    if video and video:state() == "paused" then
        video:dispose()
        video = nil
    end
end)

function node.render()
    gl.clear(0, 0, 0, 0)
    pp("distance: " .. distance)

    if distance < threshold and active == false then
        active = true
        video:dispose()
        video = nil
        video = resource.load_video{
            file = video_two:copy(),
            paused = true,
            audio = true,
            raw = true,
        }
        video:start()
    end

    if not video then
        active = false
        video = resource.load_video{
            file = video_one:copy(),
            paused = true,
            audio = true,
            raw = true,
        }
        video:start()
    end

    if video then
        local state, w, h = video:state()
        if state == "loaded" then
            local x1, y1, x2, y2 = util.scale_into(NATIVE_WIDTH, NATIVE_HEIGHT, w, h)
            video:place(x1, y1, x2, y2):layer(-1)
        elseif state == "finished" or state == "error" then
            video:dispose()
            video = nil
        end
    end

    if isConfiguring then
        font:write(200, 200, "# CONFIGURATION MODE", 200, 1, 1, 1, 1)
        font:write(200, 500, ("THRESHOLD: " .. threshold), 160, 1, 1, 1, 1)
        font:write(200, 700, ("READING: " .. distance), 160, 1, 1, 1, 1)
    end
end
