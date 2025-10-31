local HeaderScythe = {}

-- Constants

local MATCH_COMMENT = "//[%/ %w_%;%*%:%.%,%=%+%-%(%)%[%]%{%}]*"
local MATCH_COMMENT_MULTILINE = "/%*[%/%s%w_%;%*%:%.%,%=%+%-%(%)%[%]%{%}]*%*/"

local MATCH_INCLUDE = "#include%s+[%<%\"%\'][^%<%>%\"%\']+[%>%\"%\']"
local MATCH_DEFINE = "#define%s+[%w_]+[%s]*[%w_%*%\\%|]*"
local MATCH_MACRO_LABEL = "#define%s+([%w_]+)"
local MATCH_MACRO_VALUE = "#define%s+[%w_]+[%s]*([%w_%*%\\%|]*)"

local MATCH_TYPEDEF = "typedef%s*[%w_%*]+[%*%s]+[%w_%*%,%s]+;"
local MATCH_CONST = "static%s+const%s*[%w_*]+%s+[%w_*]+%s*=%s*[%w%\"%\'%(%)%|%\\%\n]+;"
local MATCH_ENUM = "typedef%s+enum%s+[%w_]*%s*%{[%w_%s%,]*%}%s*[%w_%, %*]+;"
local MATCH_FUNC = "[%w_%*]+%s+[%w_]+%([%w_%*%,%s]*%);"
local MATCH_STRUCT = "typedef%s+struct%s+[%w_]+%s*%{[%w_%*%;%s%{%}]+%}%s*[%w_%,%s%*]*;"
local MATCH_UNION = "typedef%s+union%s+[%w_]+%s*%{[%w_%*%;%s%{%}]+%}%s*[%w_%,%s%*]*;"

local TK_TYPEDEF = 0x1
local TK_CONST = 0x2
local TK_ENUM = 0x4
local TK_FUNC = 0x8
local TK_STRUCT = 0x10
local TK_DEFINE = 0x20
local TK_INCLUDE = 0x40

-- Functions

---@type fun(input: string, macros: {[1]: string, [2]: string, [3]: integer}[]): string
local function macroProcess(input, macros)
    for i, macro in next, macros do
        if input:find("[^%w_]+" .. macro[1] .. "[^%w_]+") then
            input = input:gsub(macro[1], macro[2])
        end
    end
    return input
end

-- HeaderScythe Functions

---@type fun(content: string): {[1]: string, [2]: string, [3]: integer}[]
function HeaderScythe.scythe(content)
    local tokens = {}

    -- pre process

    local preProcessedContent = content

    -- clean comments

    preProcessedContent = preProcessedContent:gsub(MATCH_COMMENT, "")
    preProcessedContent = preProcessedContent:gsub(MATCH_COMMENT_MULTILINE, "")

    -- defines

    local macros = {}

    for define in preProcessedContent:gmatch(MATCH_DEFINE) do
        local macroStart, macroEnd = preProcessedContent:find(define, 0, true)
        local macroName = define:match(MATCH_MACRO_LABEL) or ""
        local macroValue = define:match(MATCH_MACRO_VALUE) or ""
        table.insert(macros, {macroName, macroValue, macroStart})
        table.insert(tokens, {TK_DEFINE, define, macroStart})

        if macroStart and macroEnd then
            preProcessedContent = preProcessedContent:sub(0, macroStart - 1) .. preProcessedContent:sub(macroEnd + 1)
        end
    end

    table.sort(macros, function(a, b)
        return a[3] < b[3]
    end)

    preProcessedContent = macroProcess(preProcessedContent, macros)

    -- tokenization

    for typedef in preProcessedContent:gmatch(MATCH_TYPEDEF) do
        local start = preProcessedContent:find(typedef, 0, true)
        table.insert(tokens, {TK_TYPEDEF, typedef, start})
    end

    for const in preProcessedContent:gmatch(MATCH_CONST) do
        local start = preProcessedContent:find(const, 0, true)
        table.insert(tokens, {TK_CONST, const, start})
    end

    for enum in preProcessedContent:gmatch(MATCH_ENUM) do
        local start = preProcessedContent:find(enum, 0, true)
        table.insert(tokens, {TK_ENUM, enum, start})
    end

    for func in preProcessedContent:gmatch(MATCH_FUNC) do
        local start = preProcessedContent:find(func, 0, true)
        table.insert(tokens, {TK_FUNC, func, start})
    end

    for struct in preProcessedContent:gmatch(MATCH_STRUCT) do
        local start = preProcessedContent:find(struct, 0, true)
        table.insert(tokens, {TK_STRUCT, struct, start})
    end

    for union in preProcessedContent:gmatch(MATCH_UNION) do
        local start = preProcessedContent:find(union, 0, true)
        table.insert(tokens, {TK_STRUCT, union, start})
    end

    for include in preProcessedContent:gmatch(MATCH_INCLUDE) do
        local start = preProcessedContent:find(include, 0, true)
        table.insert(tokens, {TK_INCLUDE, include, start})
    end

    table.sort(tokens, function(a, b)
        return a[3] < b[3]
    end)

    return tokens
end

return HeaderScythe