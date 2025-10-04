local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "monk"
ROLE.name = "Monk"
ROLE.nameplural = "Monks"
ROLE.nameext = "a Monk"
ROLE.nameshort = "mon"
ROLE.team = ROLE_TEAM_INNOCENT

ROLE.desc = [[You are {role}! When you die you will become a ghost with powerful
abilities including the ability to speak with the living.]]
ROLE.shortdesc = "Becomes a ghost who can speak with the living and use powerful abilities when they die."

ROLE.selectionpredicate = function()
    if not ROLE_SOULBOUND then return false end
    if not GetConVar("ttt_missionary_prevent_monk"):GetBool() then return true end

    for _, p in PlayerIterator() do
        if p:IsMissionary() then
            return false
        end
    end
    return true
end

ROLE.translations = {
    ["english"] = {
        ["ev_monk_died"] = "The {monk} ({ply}) died and became a ghost"
    }
}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_MonkKilled")

    ----------------
    -- MONK DEATH --
    ----------------

    local ghostwhisperer_max_abilities = GetConVar("ttt_ghostwhisperer_max_abilities")

    AddHook("PlayerDeath", "Monk_PlayerDeath", function(victim, inflictor, attacker)
        if not IsPlayer(victim) then return end
        if not victim:IsMonk() then return end
        if victim:IsRoleAbilityDisabled() then return end

        local ragdoll = victim.server_ragdoll or victim:GetRagdollEntity()
        if ragdoll then
            ragdoll:Dissolve()
        end

        local message = "You have died but you can still talk with the living"
        if ghostwhisperer_max_abilities:GetInt() > 0 then
            message = message .. " and can now buy abilities"
        end
        message = message .. "!"
        victim:QueueMessage(MSG_PRINTBOTH, message)

        victim:SetProperty("TTTIsGhosting", true, victim)

        net.Start("TTT_MonkKilled")
        net.WriteString(victim:Nick())
        net.Broadcast()
    end)

    AddHook("TTTCanRespawnAsRole", "Monk_TTTCanRespawnAsRole", function(ply, role)
        if not IsPlayer(ply) then return end
        if not ply:IsMonk() then return end
        -- Let them change roles if they aren't going to dissolve
        if ply:IsRoleAbilityDisabled() then return end

        return false
    end)

    AddHook("TTTDeathNotifyOverride", "Monk_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
        if GetRoundState() ~= ROUND_ACTIVE then return end
        if not IsValid(inflictor) or not IsValid(attacker) then return end
        if not attacker:IsPlayer() then return end
        if victim == attacker then return end
        if not victim:IsMonk() then return end

        return reason, killerName, ROLE_NONE
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("Initialize", "Monk_Initialize", function()
        EVENT_MONKDIED = GenerateNewEventID(ROLE_MONK)
    end)
end

if CLIENT then
    ------------
    -- EVENTS --
    ------------

    AddHook("TTTSyncEventIDs", "Monk_TTTSyncEventIDs", function()
        EVENT_MONKDIED = EVENTS_BY_ROLE[ROLE_MONK]
        local ghost_icon = Material("icon16/status_offline.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_MONKDIED, {
            text = function(e)
                return PT("ev_monk_died", {ply = e.ply, monk = ROLE_STRINGS[ROLE_MONK]})
            end,
            icon = function(e)
                return ghost_icon, "Ghosted"
            end})
    end)

    net.Receive("TTT_MonkKilled", function(len)
        local monkname = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_MONKDIED,
            ply = monkname
        })
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Monk_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_MONK then return end

        local T = LANG.GetTranslation
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]

        local html = "The " .. ROLE_STRINGS[ROLE_MONK] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. T("innocent") .. " team</span> who becomes more powerful after they die."

        html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_MONK] .. " dies their body will disappear and they gain access to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>special abilities</span> they can use while spectating, including the ability to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>talk to the living</span> through in game chat.</span>"

        return html
    end)
end

AddHook("TTTRoleSpawnsArtificially", "Monk_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_MONK and util.CanRoleSpawn(ROLE_MISSIONARY) then
        return true
    end
end)