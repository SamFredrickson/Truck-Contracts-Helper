local Race = {
    new = function(contract, startedAt, finishedAt)
        local self = {}
        
        self.contract = contract
        self.startedAt = startedAt
        self.finishedAt = finishedAt

        self.getContract = function()
            return string.format(
                "{32CD32}%s {FFFFFF}-> {F2545B}%s",
                contract.source,
                contract.destination
            )
        end

        return self
    end
}
return Race