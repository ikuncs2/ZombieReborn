mp = mp or {}
local mh = require("luametahook")
local ffi = require("cffi")
ffi.cdef[[
int MessageBoxA(void *w, const char *txt, const char *cap, int type);

typedef struct CCSGameRules CCSGameRules;
typedef struct CGameRulesGameSystem CGameRulesGameSystem;
]]

local sig = require("signatures")

function mp:__imp_ProcessFunction(name, type)
    local addr = mh.SearchPattern("server.dll", sig[name])
    if not addr then
        ffi.C.MessageBoxA(nil, "Signature not found for "..name, "Warning", 0)
    end
    self["pfn"..name] = ffi.cast(type, addr)
    print("Found "..name.." at " .. tostring(self["pfn"..name]))
end

function mp:GameRules()
    local pfnGameInit = ffi.cast("uint8_t *", mh.SearchPattern("server.dll", sig.CGameRulesGameSystem__GameInit))
    print("Found CGameRulesGameSystem::GameInit at " .. tostring(pfnGameInit))
    local offset = ffi.cast("int *", pfnGameInit + 0x14)[0] + 0x18
    local pGameRules = ffi.cast("CCSGameRules *", pfnGameInit + offset)
    print("Found g_pGameRules at " .. tostring(pGameRules))
    return pGameRules
end

function mp:CheckWinConditions(delay, reason)
    print("Call CheckWinConditions")
    self.pfnCCSGameRules__CheckWinConditions(mp:GameRules())
end

function mp:TerminateRound(delay, reason)
    print("Call TerminateRound")
    self.pfnCCSGameRules__TerminateRound(mp:GameRules(), delay, reason)
end

function mp:SearchSignatures()
    self:__imp_ProcessFunction("CCSGameRules__CheckWinConditions", "void (*)(CCSGameRules *this)")
    self:__imp_ProcessFunction("CCSGameRules__TerminateRound", "void (*)(CCSGameRules *this, float delay, int reason)")
    self:__imp_ProcessFunction("CGameRulesGameSystem__GameInit", "void (*)(CGameRulesGameSystem *this)")
    g_pGameRules = self:GameRules()
end

return mp