local Class = {}
do
    Class.className = "Class"
    Class._class = Class
    Class.__index = Class

    Class._init = function(self)
    end

    Class.new = function(super, ...)
        local init = super._init
        if not init then error("Not a valid Class.") end
        if super._isInstance then error("Expected Class, got Instance.") end

        local instance = setmetatable({ _isInstance = true }, super)
        init(instance, ...)

        return instance
    end

    Class.extend = function(base, name)
        if base._isInstance then error("Expected Class, got Instance.") end
        local super = setmetatable({ className = name, _parent = base }, base)
        super._class = super
        super.__index = super
        return super
    end

    Class.isSubClass = function(self, class)
        -- Check if it's a valid Class
        if type(class) ~= "table" or not class._init then return false end

        local c = self._class
        while c do
            if c == class then return true end
            c = c._parent
        end

        return false
    end
end

--return Class

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
        print("Zzzzzzzzz, I'll let them talk to you: " .. tostring(self._parent.className))
        self:sayBye()
    end
end

local mike = Person:new("Mike")
mike:sayHi()

local dand = SleepyPerson:new("Dandruff")
dand:sayHi()

-- Should fail
--mike:extend("Big Mike")
--dand:new("Big Dandruff"):sayHi()

mike._class:extend("Big Mike"):new("Mickey Mouse"):sayHi()
dand._class:new("Big Dandruff"):sayHi()

local check_subclass = function(base, cmp)
    local nnot = base:isSubClass(cmp) and "" or " NOT"
    local nhello = base.hello and (" (%s)"):format(base.hello) or ""
    local ncmp = cmp._isInstance and ("Instance of %s"):format(cmp.className) or cmp.className
    print(("%s%s is%s a subclass of %s"):format(base.className, nhello, nnot, ncmp))
end

check_subclass(mike, mike._class:new("test mike"))
check_subclass(mike, mike._class)
check_subclass(mike, SleepyPerson)
check_subclass(dand, SleepyPerson)
check_subclass(dand, Class)
