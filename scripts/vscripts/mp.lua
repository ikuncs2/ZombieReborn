mp = mp or {}
local mh = require("luametahook")
local ffi = require("cffi")
ffi.cdef[[
int MessageBoxA(void *w, const char *txt, const char *cap, int type);

typedef struct CCSGameRules CCSGameRules;
typedef struct CGameRulesGameSystem CGameRulesGameSystem;
typedef struct TerminateRoundParams {
    int v1;
    int v2;
    int v3;
    int v4;
} TerminateRoundParams;
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

function mp:CheckWinConditions()
    print("Call CheckWinConditions")
    self.pfnCCSGameRules__CheckWinConditions(mp:GameRules())
end

function mp:TerminateRound(delay, reason)
    print("Call TerminateRound")
    self.pfnCCSGameRules__TerminateRound(mp:GameRules(), delay, reason, 0, 0)
end

function mp:SearchSignatures()
    self:__imp_ProcessFunction("CCSGameRules__CheckWinConditions", "void (*)(CCSGameRules *this, int a2, int a3)")
    self:__imp_ProcessFunction("CCSGameRules__TerminateRound", "void (*)(CCSGameRules *this, float delay, int reason, TerminateRoundParams *a4, int a5)")
    self:__imp_ProcessFunction("CGameRulesGameSystem__GameInit", "void (*)(CGameRulesGameSystem *this)")
    g_pGameRules = self:GameRules()
end

function Hook_TerminateRound(this, delay, reason, a4, a5)
    print(string.format("Hook_TerminateRound this=%s delay=%s reason=%s", this, delay, reason))
    return mp.hooks.pfnCCSGameRules__TerminateRound(this, delay, reason, a4, a5)
end

function Hook_CheckWinConditions(this, a2, a3)
    print(string.format("Hook_CheckWinConditions this=%s %s %s", this, a2, a3))
    return mp.hooks.pfnCCSGameRules__CheckWinConditions(this, a2, a3)
end

local ffi_hook = require("ffi_hook")

function mp:InstallHooks()
    self.hooks = {}
    ffi_hook.setffi(ffi)
    self.hooks.pfnCCSGameRules__TerminateRound = ffi_hook.inline(self.pfnCCSGameRules__TerminateRound, Hook_TerminateRound)
    self.hooks.pfnCCSGameRules__CheckWinConditions = ffi_hook.inline(self.pfnCCSGameRules__CheckWinConditions, Hook_CheckWinConditions)
end

return mp