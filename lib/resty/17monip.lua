-- Copyright (C) 2014 Monkey Zhang (timebug)

local bit = require "bit"

local lshift = bit.lshift
local insert = table.insert
local str_byte = string.byte
local str_gsub = string.gsub
local ngx_match = ngx.re.match


local _M = { _VERSION = "0.01" }

local mt = { __index = _M }

--[[
    The 17mon dat file format in bytes:

        -----------
        | 4 bytes |                     <- offset number
        -----------------
        | 256 * 4 bytes |               <- first ip number index
        -----------------------
        | offset - 1028 bytes |         <- ip index
        -----------------------
        |    data  storage    |
        -----------------------
]]--


local IP_FORMAT_ERR = "invalid ip format"
local DB_FORMAT_ERR = "invalid db format"


local function _decode(raw)
    local t = {}
    str_gsub(raw, "([^\t]+)", function (s)
                 return insert(t, s)
    end)
    return t
end


local function _uint32(a, b, c, d)
    if not a or not b or not c or not d then
        return nil
    end

    local u = lshift(a, 24) + lshift(b, 16) + lshift(c, 8) + d
    if u < 0 then
        u = u + math.pow(2, 32)
    end
    return u
end


local function _getdata(opts)
    if not opts then
        opts = {}
    end
    if opts.data then
        return opts.data
    end

    if not opts.datfile then
        opts.datfile = "17monipdb.dat"
    end

    local file, err = io.open(opts.datfile, "rb")
    if not file then
        return nil, err
    end

    local data, err = file:read("*all")
    if not data then
        file:close()
        return nil, err
    end

    file:close()
    return data
end


local function _parsedata(data)
    local offset = _uint32(str_byte(data, 1, 4))
    if not offset then
        return
    end
    local index_buffer = data:sub(5, offset)
    return offset, index_buffer
end


function _M.new(self, opts)
    local data, err = _getdata(opts)
    if not data then
        return nil, err
    end

    local offset, index_buffer = _parsedata(data)
    if not offset then
        return nil, DB_FORMAT_ERR
    end

    return setmetatable({
        data = data,
        offset = offset,
        index_buffer = index_buffer,
    }, mt)
end


function _M.update(self, opts)
    local data, err = _getdata(opts)
    if not data then
        return nil, err
    end

    self.data = data
    self.offset, self.index_buffer = _parsedata(self.data)
    if not self.offset then
        return nil, DB_FORMAT_ERR
    end

    return 1
end


function _M.query(self, ip)
    local data = self.data
    if not data then
        return nil, "not initialized"
    end

    local regex = "^([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)$"
    local m, err = ngx_match(ip, regex, "jo")
    if not m then
        if err then
            return nil, err
        end
        return nil, IP_FORMAT_ERR
    end

    local offset = self.offset
    local index_buffer = self.index_buffer

    local ip_uint32 = _uint32(m[1], m[2], m[3], m[4])
    local ip_offset = m[1] * 4

    local index_offset = -1
    local index_length = -1
    local maxlen = offset - 1028

    if ip_offset + 4 > offset - 4 then
        return nil, DB_FORMAT_ERR
    end

    local start = _uint32(index_buffer:byte(ip_offset + 4),
                          index_buffer:byte(ip_offset + 3),
                          index_buffer:byte(ip_offset + 2),
                          index_buffer:byte(ip_offset + 1))

    local cur_uint32 = 0
    for i=start * 8 + 1025, maxlen, 8 do
        cur_uint32 = _uint32(str_byte(index_buffer, i, i + 4))
        if not cur_uint32 then
            return nil, DB_FORMAT_ERR
        end
        if ip_uint32 <= cur_uint32 then
            index_offset = _uint32(0, index_buffer:byte(i + 6),
                                   index_buffer:byte(i + 5),
                                   index_buffer:byte(i + 4))
            index_length = index_buffer:byte(i + 7)
            break
        end
    end

    if index_offset == -1 or index_length == -1 then
        return nil -- not found
    end

    local data_offset = offset + index_offset - 1024
    local raw = data:sub(data_offset, data_offset + index_length)

    return _decode(raw)
end


return _M
