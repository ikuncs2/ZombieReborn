
-- Task system : a new timer based task
-- Quick start:
--  1. Call f() after 2 secs
--      GlobalTask:Wait(2, function(succ) if succ then f() end)
--  2. Spawn a timer to call f() after 2 secs and wait for it, while it can be removed somewhere
--      local timer = GlobalTask:CreateTimer(2)
--      GlobalTask:WaitTimer(timer, function(succ) if succ then f() end)
--      GlobalTask:RemoveTimer(timer)
--  3. Call f(), g(), h() with 2 secs interval
--      GlobalTask:Spawn(function(yield)
--          GlobalTask:Wait(2, yield)
--          f()
--          GlobalTask:Wait(2, yield)
--          g()
--          GlobalTask:Wait(2, yield)
--          h()
--      end, detached)
--  3. Call f() with 2 secs interval for 10 times
--      GlobalTask:Spawn(function(yield)
--          for i = 1, 10 do
--              GlobalTask:Wait(2, yield)
--              f()
--          end
--      end, detached)
--  4. Call f() with 2 secs interval until f() returns false
--      GlobalTask:Spawn(function(yield)
--          repeat
--              GlobalTask:Wait(2, yield)
--          until f() end
--      end, detached)
--  5. 

-- Detail:
-- Initiator is the async function we called (like Wait()) with format like:
--      function initiator(task, args, completion_token) => initfn_result
--  initfn_result differs from what completion_token is provided
-- Completion token specifies how this async operation is handled. It can be one of :
--  1. detached -> ignore result, like an empty function, with void initfn_result
--  2. function(succ, arg) ... end -> simple old-school callback function or closure
--      succ == true implies the operation is succeed, arg is the result we got
--      succ == false implies the operation is failed, arg is the exception string thrown
--  3. yield -> use coroutine in Spawn()
--      initfn_result = arg if success
--      throw exception (therefore no initfn_result) if failed ( can be handled by pcall or xpcall )


Task = Task or {}
local TASK_THINK_INTERVAL = 0.01

function Task.New(name, interval) 
    local task = {}
    setmetatable(task, Task)
    return task:Init(name, interval)
end

function Task:Constructor(name, interval)
    local ent = SpawnEntityFromTableSynchronous("info_target", { targetname = name or ""})
    ent:SetThink("Poll", self, "timers", interval or TASK_THINK_INTERVAL)

    self.completion_handler_list = {}
    self.timer_list = {}
    self.ent = ent
    return self
end

function Task:Destroy()
    self.ent:RemoveSelf()
    self.ent = nil
    self:Reset()
    self.completion_handler_list = nil
    self.timer_list = nil
end

local function print_error(e)
    print("Lua Task error: " .. e .. "\n" .. debug.traceback())
end

local function empty_function()
end

local function identity_function(...)
    local args = {...}
    return function() return table.unpack(args) end
end

local function default_completion_handler(e, ...)
    if e then
        print_error(e)
    end
end

local function yield_rethrow()
    local args = { coroutine.yield() }
    local e = table.remove(args, 1)
    if e then
        return error(e)
    end
    return table.unpack(args)
end

yield_current = {
    MakeCompletionHandler = function() 
        local co = coroutine.running()
        return function(succ, ...) 
            return coroutine.resume(co, succ, ...)
        end 
    end,
    MakeInitFnResult = function() 
        return yield_rethrow()
    end,
}
detached = {
    MakeCompletionHandler = identity_function(default_completion_handler),
    MakeInitFnResult = empty_function,
}

function Task:MakeInitFnResult(completion_token)
    if type(completion_token) == "function" then
        return nil
    end
    if type(completion_token) == "table" then
        return completion_token:MakeInitFnResult()
    end
    -- default as detached
    return nil
end

function Task:MakeCompletionHandler(completion_token)
    if type(completion_token) == "function" then
        return completion_token
    end
    if type(completion_token) == "table" then
        return completion_token:MakeCompletionHandler()
    end
    -- default as detached
    return default_completion_handler
end

function Task:Post(completion_token)
    local completion_handler = self:MakeCompletionHandler(completion_token)
    table.insert(self.completion_handler_list, completion_handler)
    return self:MakeInitFnResult(completion_token)
end

function Task:ExecuteAll(...)
    local executed = 0
    local completion_handler_list = self.completion_handler_list
    self.completion_handler_list = {}
    
    for i, completion_handler in ipairs(completion_handler_list) do
        local err, result = xpcall(completion_handler, debug.traceback, ...)
        executed = executed + 1
    end
    return executed
end

function Task:CheckTimer()
    local now = Now()
    while self.timer_list[1] and self.timer_list[1].expire_time > now do
        local timer_record = table.remove(self.timer_list, 1)
        for _, completion_handler in ipairs(timer_record.completion_handler_list) do
            table.insert(self.completion_handler_list, completion_handler)
        end
        timer_record.completion_handler_list = nil
    end
end

function Task:Poll()
    self:CheckTimer()
    return self:ExecuteAll(true)
end

function Task:Reset()
    while next(self.completion_handler_list) do
        self:ExecuteAll(self, false, "task cancelled")
    end
    self.completion_handler_list = {}
end

function Task:Spawn(coroutine_main_fn, completion_token)
    local completion_handler = self:MakeCompletionHandler(completion_token)
    local co = coroutine.create(function(succ, yield)
        local result_list = { xpcall(coroutine_main_fn, debug.traceback, yield) }
        local succ = table.remove(result_list, 1)
        if not succ then
            return self:Post(function(succ) return completion_handler(false, table.unpack(result_list)) end)
        else
            return self:Post(function(succ) return completion_handler(true, table.unpack(result_list)) end)
        end
    end)
    local yield = {
        MakeCompletionHandler = function() return function(succ, ...) 
            --log("resume in completion_handler") 
            return coroutine.resume(co, succ, ...)
        end end,
        MakeInitFnResult = function() 
            --log("resume in completion_handler") 
            return yield_rethrow()
        end,
    }
    self:Post(function(succ) 
        return coroutine.resume(co, succ, yield)
    end)
    return self:MakeInitFnResult(completion_token)
end

function Task:CreateTimer(duration)
    local expire_time = Time() + duration
    local timer_record = {
        expire_time = expire_time,
    }
    return timer_record
end

function Task:WaitTimer(timer_record, completion_token)
    local completion_handler = self:MakeCompletionHandler(completion_token)

    -- if timer is already waiting, add another completion token
    for i, v in ipairs(self.timer_list) do
        if timer_record == v then
            timer_record.completion_handler_list = completion_token
            return self:MakeInitFnResult(completion_token)
        end
    end
    -- otherwise add it to list
    timer_record.completion_handler_list = { completion_handler }
    table.insert(self.timer_list, timer_record)
    table.sort(self.timer_list, function(a, b) return a.expire_time < b.expire_time end)
    return self:MakeInitFnResult(completion_token)
end

function Task:RemoveTimer(timer_record)
    local iter = nil
    for i, v in ipairs(self.timer_list) do
        if timer_record == v then
            iter = i
            break
        end
    end
    table.remove(self.timer_list, iter)
end

function Task:Wait(duration, completion_token)
    return self:WaitTimer(self:CreateTimer(duration), completion_token)
end

GlobalTask = GlobalTask or Task.New("task_global", TASK_THINK_INTERVAL)