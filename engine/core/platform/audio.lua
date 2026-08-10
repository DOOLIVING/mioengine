local ffi = require("ffi")
local Platform = require("engine.core.platform.platform")
local stb = Platform.try_load("stb_image")

local al_lib = nil
if Platform.os == "Windows" then
    al_lib = Platform.try_load("OpenAL32", "openal32")
elseif Platform.os == "OSX" then
    local ok
    ok, al_lib = pcall(ffi.load, "/System/Library/Frameworks/OpenAL.framework/Versions/A/OpenAL")
    if not ok then al_lib = Platform.try_load("openal") end
else
    al_lib = Platform.try_load("openal")
end

local M = {}
M.__index = M

if al_lib then
    ffi.cdef[[
    typedef int ALenum;
    typedef int ALint;
    typedef unsigned int ALuint;
    typedef float ALfloat;
    typedef void ALvoid;
    typedef unsigned char ALbyte;

    ALuint alGenSources(ALint n, ALuint* sources);
    void alDeleteSources(ALint n, ALuint* sources);
    void alSourcei(ALuint source, ALenum param, ALint value);
    void alSourcef(ALuint source, ALenum param, ALfloat value);
    void alSourcePlay(ALuint source);
    void alSourceStop(ALuint source);
    void alSourcePause(ALuint source);
    ALenum alGetError(void);

    ALuint alGenBuffers(ALint n, ALuint* buffers);
    void alDeleteBuffers(ALint n, ALuint* buffers);
    void alBufferData(ALuint buffer, ALenum format, const ALvoid* data, ALint size, ALint freq);

    void* alcOpenDevice(const char* devicename);
    void* alcCreateContext(void* device, const int* attrlist);
    int alcMakeContextCurrent(void* context);
    void alcDestroyContext(void* context);
    int alcCloseDevice(void* device);

    typedef struct { unsigned short format; unsigned int channels; unsigned int samplerate; unsigned int byterate; unsigned short blockalign; unsigned short bitspersample; unsigned short extra; } WAVEFORMATEX;

    typedef unsigned int (__cdecl *mio_read_func)(void*, unsigned int, unsigned int, void*);
    typedef unsigned int (__cdecl *mio_tell_func)(void*, void*);
    ]]

    local AL_FORMAT_MONO16 = 0x1101
    local AL_FORMAT_STEREO16 = 0x1103
    local AL_PLAYING = 0x1012
    local AL_STOPPED = 0x1014
    local AL_LOOPING = 0x1007
    local AL_GAIN = 0x100A
    local AL_PITCH = 0x1003
    local AL_POSITION = 0x1004
    local AL_BUFFER = 0x1009
    local AL_SOURCE_STATE = 0x1010

    local device = al_lib.alcOpenDevice(nil)
    if device then
        local context = al_lib.alcCreateContext(device, nil)
        al_lib.alcMakeContextCurrent(context)
        M.al = al_lib
        M.device = device
        M.context = context
        M.AL_FORMAT_MONO16 = AL_FORMAT_MONO16
        M.AL_FORMAT_STEREO16 = AL_FORMAT_STEREO16
        M.AL_LOOPING = AL_LOOPING
        M.AL_GAIN = AL_GAIN
        M.AL_PITCH = AL_PITCH
        M.AL_POSITION = AL_POSITION
        M.AL_BUFFER = AL_BUFFER
        M.AL_SOURCE_STATE = AL_SOURCE_STATE
        M.AL_PLAYING = AL_PLAYING
        M.AL_STOPPED = AL_STOPPED
        M.enabled = true
    else
        print("[Audio] WARNING: failed to open audio device")
        M.enabled = false
    end
else
    M.enabled = false
end

function M.new()
    print("[Audio] enabled:", M.enabled)
    return setmetatable({
        sources = {},
        buffers = {},
        enabled = M.enabled,
    }, M)
end

function M:load_wav(name, path)
    if not self.enabled then print("[Audio] load_wav: disabled"); return nil end
    if self.buffers[name] then return self.buffers[name] end

    print("[Audio] loading wav: " .. tostring(name) .. " from " .. tostring(path))
    local f = io.open(path, "rb")
    if not f then error("Cannot open audio: " .. path) end
    local data = f:read("*a")
    f:close()

    if #data < 44 then error("WAV file too small: " .. path) end
    if data:sub(1, 4) ~= "RIFF" then error("Not a valid WAV file: " .. path) end
    if data:sub(9, 12) ~= "WAVE" then error("Not a valid WAV file: " .. path) end

    local pos = 13
    local num_channels = 0
    local sample_rate = 0
    local bits_per_sample = 0
    local pcm_data = nil

    while pos < #data - 8 do
        local chunk_id = data:sub(pos, pos + 3)
        local chunk_size = string.byte(data, pos+4) + string.byte(data, pos+5) * 256 +
                           string.byte(data, pos+6) * 65536 + string.byte(data, pos+7) * 16777216
        pos = pos + 8

        if chunk_id == "fmt " then
            local format_tag = string.byte(data, pos) + string.byte(data, pos+1) * 256
            num_channels = string.byte(data, pos+2) + string.byte(data, pos+3) * 256
            sample_rate = string.byte(data, pos+4) + string.byte(data, pos+5) * 256 +
                          string.byte(data, pos+6) * 65536 + string.byte(data, pos+7) * 16777216
            bits_per_sample = string.byte(data, pos+14) + string.byte(data, pos+15) * 256
        elseif chunk_id == "data" then
            pcm_data = data:sub(pos, pos + chunk_size - 1)
        end

        pos = pos + chunk_size
        if chunk_size % 2 == 1 then pos = pos + 1 end
    end

    if not pcm_data then error("No data chunk in WAV: " .. path) end

    local fmt = M.AL_FORMAT_MONO16
    if num_channels == 2 then fmt = M.AL_FORMAT_STEREO16 end

    local buf = ffi.new("uint32_t[1]")
    M.al.alGenBuffers(1, buf)
    M.al.alBufferData(buf[0], fmt, pcm_data, #pcm_data, sample_rate)

    self.buffers[name] = buf[0]
    return buf[0]
end

function M:play(name, params)
    if not self.enabled then
        print("[Audio] play: audio disabled!")
        return nil
    end
    params = params or {}
    local buffer = self.buffers[name]
    if not buffer then
        print("[Audio] play: no buffer for '" .. tostring(name) .. "'")
        return nil
    end

    print("[Audio] playing: " .. tostring(name) .. " loop=" .. tostring(params.loop))
    local src = ffi.new("uint32_t[1]")
    M.al.alGenSources(1, src)
    M.al.alSourcei(src[0], M.AL_BUFFER, buffer)

    if params.loop then
        M.al.alSourcei(src[0], M.AL_LOOPING, 1)
    end
    if params.gain then
        M.al.alSourcef(src[0], M.AL_GAIN, params.gain)
    end
    if params.pitch then
        M.al.alSourcef(src[0], M.AL_PITCH, params.pitch)
    end

    M.al.alSourcePlay(src[0])

    local source = { id = src[0], name = name }
    self.sources[#self.sources+1] = source
    return source
end

function M:stop(source)
    if not self.enabled or not source then return end
    M.al.alSourceStop(source.id)
end

function M:stop_all()
    if not self.enabled then return end
    for _, src in ipairs(self.sources) do
        M.al.alSourceStop(src.id)
    end
end

function M:delete()
    if not self.enabled then return end
    for _, src in ipairs(self.sources) do
        M.al.alDeleteSources(1, ffi.new("uint32_t[1]", src.id))
    end
    for _, buf in pairs(self.buffers) do
        M.al.alDeleteBuffers(1, ffi.new("uint32_t[1]", buf))
    end
end

return M
