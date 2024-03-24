local Number = {
    new = function(number)
        local self = {}
        self.number = number

        self.dot_value = function()
            local formatted = self.number
            while true do  
                formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
                if (k==0) then
                    break
                end
            end
            return formatted
        end
        
        self.round = function (val, decimal)
            if (decimal) then
                return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
            else
                return math.floor(val+0.5)
            end
        end

        self.format = function(decimal, prefix, neg_prefix)
            local str_amount, formatted, famount, remain

            decimal = decimal or 2  -- default 2 decimal places
            neg_prefix = neg_prefix or "-" -- default negative sign

            famount = math.abs(self.round(self.number,decimal))
            famount = math.floor(famount)
            remain = self.round(math.abs(self.number) - famount, decimal)

            -- dot to separate the thousands
            formatted = self.dot_value()

            -- attach the decimal portion
            if (decimal > 0) then
                remain = string.sub(tostring(remain),3)
                formatted = formatted .. "." .. remain ..
                string.rep("0", decimal - string.len(remain))
            end

            -- attach prefix string e.g '$'
            formatted = (prefix or "") .. formatted

            -- if value is negative then format accordingly
            if (self.number < 0) then
                if (neg_prefix=="()") then
                    formatted = "("..formatted ..")"
                else
                    formatted = neg_prefix .. formatted
                end
            end

            return formatted
        end

        return self
    end
}

return Number