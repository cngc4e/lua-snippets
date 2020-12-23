local Class = {}
do
    Class._className = "Class"
    Class.__index = Class

    Class._init = function()
        return {}
    end

    Class.new = function(parent, ...)
        local init = parent._init
        if not init then error("Not a valid Class.") end
        return setmetatable(init(parent, ...), parent)
    end

    Class.extend = function(base, name)
        local super = setmetatable({ _className = name, _parent = base }, base)
        super.__index = super
        return super
    end
end

local Person = Class:extend("Person")
do
    Person._init = function(self, name)
        local data = self._parent:_init()
        data.hello = name
        return data
    end

    Person.sayBye = function(self) print("Lol bye. " .. tostring(self.hello)) end

    Person.sayHi = function(self) print("I'm " .. tostring(self.hello)) end
end

local SleepyPerson = Person:extend("SleepyPerson")
do
    SleepyPerson._init = function(self, name)
        local data = self._parent:_init()
        data.hello = name
        return data
    end

    SleepyPerson.sayHi = function(self)
        print("Zzzzzzzzz, I'll let them talk to you: " .. tostring(self._parent._className))
        self:sayBye()
    end
end

local mike = Person:new("Mike")
mike:sayHi()

local dand = SleepyPerson:new("Dandruff")
dand:sayHi()
