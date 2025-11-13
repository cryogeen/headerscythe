-- MIT License
-- 
-- Copyright (c) 2025 cryogeen
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local HeaderScythe = {}

-- Constants

local MATCH_COMMENT = "//[\32-\255]*"
local MATCH_COMMENT_MULTILINE = "/%*[\32-\255]*%*/"

local MATCH_INCLUDE = "#include%s+[%<%\"%\'][^%<%>%\"%\']+[%>%\"%\']"

local MATCH_TYPEDEF = "typedef%s*[%w_%*]+[%*%s]+[%w_%*%,%s]+;"
local MATCH_CONST = "static%s+const%s*[%w_*]+%s+[%w_*]+%s*=%s*[%w_%p\n\32]+;"
local MATCH_ENUM = "typedef%s+enum%s+[%w_]+%s*%b{}%s*[%*%w_%,\32\n]*;"
local MATCH_FUNC = "[%w_%*]+%s+[%w_]+%b();"
local MATCH_STRUCT = "typedef%s+struct%s+[%w_]*%s*%b{}[\32]*[%w_%,\32%*]*;"
local MATCH_UNION = MATCH_STRUCT:gsub("struct", "union")

local TK_TYPEDEF = 0x1
local TK_CONST = 0x2
local TK_ENUM = 0x4
local TK_FUNC = 0x8
local TK_STRUCT = 0x10
local TK_INCLUDE = 0x20

-- Functions

---@type fun(content: string, input: string): integer?
local function findLineFromString(content, input)
    local line = 1
    local index = content:find(input, 0, true)
    if not index then return end

    local subContent = content:sub(0, index)
    for _ in subContent:gmatch("\n") do
        line = line + 1
    end

    return line
end

-- HeaderScythe Functions

---@type fun(content: string): {token: integer, string: string, start: integer, line: integer}[]
function HeaderScythe.scythe(content)
    ---@type {token: integer, string: string, start: integer, line: integer}[]
    local tokens = {}

    -- pre process

    local preProcessedContent = content

    -- clean comments

    preProcessedContent = preProcessedContent:gsub(MATCH_COMMENT, "")
    preProcessedContent = preProcessedContent:gsub(MATCH_COMMENT_MULTILINE, "")

    -- tokenization

    for typedef in preProcessedContent:gmatch(MATCH_TYPEDEF) do
        local start = preProcessedContent:find(typedef, 0, true)
        local line = findLineFromString(preProcessedContent, typedef)
        table.insert(tokens, {
            token = TK_TYPEDEF,
            string = typedef,
            start = start,
            line = line
        })
    end

    for const in preProcessedContent:gmatch(MATCH_CONST) do
        local start = preProcessedContent:find(const, 0, true)
        local line = findLineFromString(preProcessedContent, const)
        table.insert(tokens, {
            token = TK_CONST,
            string = const,
            start = start,
            line = line
        })
    end

    for enum in preProcessedContent:gmatch(MATCH_ENUM) do
        local start = preProcessedContent:find(enum, 0, true)
        local line = findLineFromString(preProcessedContent, enum)
        table.insert(tokens, {
            token = TK_ENUM,
            string = enum,
            start = start,
            line = line
        })
    end

    for func in preProcessedContent:gmatch(MATCH_FUNC) do
        local start = preProcessedContent:find(func, 0, true)
        local line = findLineFromString(preProcessedContent, func)
        table.insert(tokens, {
            token = TK_FUNC,
            string = func,
            start = start,
            line = line
        })
    end

    for struct in preProcessedContent:gmatch(MATCH_STRUCT) do
        local start = preProcessedContent:find(struct, 0, true)
        local line = findLineFromString(preProcessedContent, struct)
        table.insert(tokens, {
            token = TK_STRUCT,
            string = struct,
            start = start,
            line = line
        })
    end

    for union in preProcessedContent:gmatch(MATCH_UNION) do
        local start = preProcessedContent:find(union, 0, true)
        local line = findLineFromString(preProcessedContent, union)
        table.insert(tokens, {
            token = TK_STRUCT,
            string = union,
            start = start,
            line = line
        })
    end

    for include in preProcessedContent:gmatch(MATCH_INCLUDE) do
        local start = preProcessedContent:find(include, 0, true)
        local line = findLineFromString(preProcessedContent, include)
        table.insert(tokens, {
            token = TK_INCLUDE,
            string = include,
            start = start,
            line = line
        })
    end

    table.sort(tokens, function(a, b)
        return a.start < b.start
    end)

    return tokens
end

return HeaderScythe
