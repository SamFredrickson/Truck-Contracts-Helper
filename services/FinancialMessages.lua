local FinancialMessages = {}

local rules = {
    { code = "tbooster", category = "Бусты", expense = true },
    { code = "fine", category = "Штрафы с камер", expense = true },
    { code = "income", routeIncome = true, category = "Неизвестный источник" },
    { code = "family-income", category = "Семейный бонус" },
    { code = "quest-income", category = "Семейный бонус" },
    { code = "refilled-at-gas-station", category = "Заправка на станции", expense = true, requiresTruck = true },
    { code = "repair-accepted", category = "Починка механиком", expense = true, requiresTruck = true },
    { code = "repair-kit-acquired", category = "Рем. комплекты", expense = true, requiresTruck = true },
    { code = "gasoline-canister-acquired", category = "Канистры", expense = true, requiresTruck = true },
    { code = "refill-accepted", category = "Заправка механиком", expense = true, requiresTruck = true },
}

function FinancialMessages.handle(text, source, messages, getDrivenTruck, record)
    for _, rule in ipairs(rules) do
        local first, second = messages.match(text, rule.code)
        local captured = first
        if rule.routeIncome then captured = second end
        local amount = tonumber(captured)
        if amount and (not rule.requiresTruck or getDrivenTruck()) then
            local category = rule.routeIncome and source or rule.category
            record(rule.expense and -amount or amount, category)
        end
    end
end

return FinancialMessages
