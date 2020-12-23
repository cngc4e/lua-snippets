local Class = {}
do
    Class._className = "Class"
    Class.__index = Class

    Class._init = function(self)
    end

    Class.new = function(super, ...)
        local init = super._init
        if not init then error("Not a valid Class.") end

        local instance = setmetatable({}, super)
        init(instance, ...)

        return instance
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
        Person._parent._init(self)
        self.hello = name
    end

    Person.sayBye = function(self) print("Lol bye. " .. tostring(self.hello)) end

    Person.sayHi = function(self) print("I'm " .. tostring(self.hello)) end
end

local SleepyPerson = Person:extend("SleepyPerson")
do
    SleepyPerson._init = function(self, name)
        SleepyPerson._parent._init(self, name)
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
