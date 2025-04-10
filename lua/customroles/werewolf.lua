local hook = hook
local player = player
local table = table
local math = math

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local TableEmpty = table.Empty
local MathRandom = math.random
local MathMax = math.max

local SetMDL = FindMetaTable("Entity").SetModel

local ROLE = {}

ROLE.nameraw = "werewolf"
ROLE.name = "Werewolf"
ROLE.nameplural = "Werewolves"
ROLE.nameext = "a Werewolf"
ROLE.nameshort = "wwf"

ROLE.desc = [[You are {role}! You are weak during the day but transform into a powerful beast at night!
Try to kill everyone and be the last one standing!]]

ROLE.shortdesc = "Weak during the day and strong at night. They win if they are the last player alive."

ROLE.team = ROLE_TEAM_INDEPENDENT

ROLE.canseejesters = true
ROLE.canseemia = true

ROLE.isactive = function(ply)
    return ply:IsActive() and WEREWOLF.isNight
end

ROLE.onroleassigned = function(ply)
    if not timer.Exists("TTTWerewolfTimeChange") then
        WEREWOLF.ChangeTime(true, true, false)
    end
end

ROLE.convars = {
    {
        cvar = "ttt_werewolf_is_monster",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_night_visibility_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Only Werewolves", "Everyone if a Werewolf is alive", "Everyone if a Werewolf is in the round", "Everyone regardless of whether a Werewolf exists"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_timer_visibility_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"No one", "Only Werewolves", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_fog_visibility_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"No one", "Non-Werewolves", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_drop_weapons",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_transform_model",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_hide_id",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_vision_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Never", "While transformed", "Always"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_show_target_icon",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Never", "While transformed", "Always"},
        isNumeric = true
    },
    {
        cvar = "ttt_werewolf_bloodthirst_tint",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_night_tint",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_day_length_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_day_length_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_night_length_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_night_length_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_day_damage_penalty",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_werewolf_night_damage_reduction",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_werewolf_night_speed_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_werewolf_night_sprint_recovery",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_werewolf_leap_enabled",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_werewolf_attack_damage",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_werewolf_attack_delay",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 1
    }
}

ROLE.translations = {
    ["english"] = {
        ["ev_win_werewolf"] = "The beastly {role} has won the round!",
        ["win_werewolf"] = "The {role} has slaughtered you all!",
        ["werewolf_timer_night"] = "Night falls in: {time}",
        ["werewolf_timer_day"] = "The sun rises in: {time}",
        ["wwf_claws_help_pri"] = "Press {primaryfire} to attack.",
        ["wwf_claws_help_sec"] = "Press {secondaryfire} to leap."
    }
}

RegisterRole(ROLE)

local werewolf_is_monster = CreateConVar("ttt_werewolf_is_monster", 0, FCVAR_REPLICATED, "Whether Werewolves should be treated as members of the monster team")
local werewolf_night_visibility_mode = CreateConVar("ttt_werewolf_night_visibility_mode", 1, FCVAR_REPLICATED, "Which players know when it is night", 0, 3)
local werewolf_timer_visibility_mode = CreateConVar("ttt_werewolf_timer_visibility_mode", 1, FCVAR_REPLICATED, "Which players see a timer showing when it will change to/from night", 0, 2)
local werewolf_fog_visibility_mode = CreateConVar("ttt_werewolf_fog_visibility_mode", 2, FCVAR_REPLICATED, "Which players see fog/darkness during the night", 0, 2)
local werewolf_hide_id = CreateConVar("ttt_werewolf_hide_id", 1, FCVAR_REPLICATED, "Whether Werewolves' target ID (Name, health, karma etc.) should be hidden from other players' HUDs while transformed")
local werewolf_vision_mode = CreateConVar("ttt_werewolf_vision_mode", 1, FCVAR_REPLICATED, "Whether Werewolves see a visible aura around other players, visible through walls", 0, 2)
local werewolf_show_target_icon = CreateConVar("ttt_werewolf_show_target_icon", 1, FCVAR_REPLICATED, "Whether Werewolves see an icon over other players' heads showing who to kill", 0, 2)
local werewolf_bloodthirst_tint = CreateConVar("ttt_werewolf_bloodthirst_tint", 1, FCVAR_REPLICATED, "Whether Werewolves' screens should go red while transformed")
local werewolf_night_tint = CreateConVar("ttt_werewolf_night_tint", 1, FCVAR_REPLICATED, "Whether players' screens should be tinted during the night")
local werewolf_day_length_min = CreateConVar("ttt_werewolf_day_length_min", 75, FCVAR_REPLICATED, "The minimum length of the day phase in seconds", 1, 300)
local werewolf_day_length_max = CreateConVar("ttt_werewolf_day_length_max", 105, FCVAR_REPLICATED, "The maximum length of the day phase in seconds", 1, 300)
local werewolf_night_length_min = CreateConVar("ttt_werewolf_night_length_min", 20, FCVAR_REPLICATED, "The minimum length of the night phase in seconds", 1, 300)
local werewolf_night_length_max = CreateConVar("ttt_werewolf_night_length_max", 40, FCVAR_REPLICATED, "The maximum length of the night phase in seconds", 1, 300)
local werewolf_day_damage_penalty = CreateConVar("ttt_werewolf_day_damage_penalty", 0.5, FCVAR_REPLICATED, "Damage penalty applied to damage dealt by Werewolves during the day", 0, 1)
local werewolf_night_damage_reduction = CreateConVar("ttt_werewolf_night_damage_reduction", 1, FCVAR_REPLICATED, "Damage reduction applied to damage dealt to Werewolves during the night", 0, 1)
local werewolf_night_speed_mult = CreateConVar("ttt_werewolf_night_speed_mult", 1.3, FCVAR_REPLICATED, "The multiplier to use on Werewolves' movement speed during the night", 1, 2)
local werewolf_night_sprint_recovery = CreateConVar("ttt_werewolf_night_sprint_recovery", 0.15, FCVAR_REPLICATED, "The amount of stamina Werewolves recover per tick at night", 0, 1)


WEREWOLF_NIGHT_ONLY_SHOW_WEREWOLVES = 0
WEREWOLF_NIGHT_SHOW_IF_HAS_WEREWOLF = 1
WEREWOLF_NIGHT_SHOW_IF_HAD_WEREWOLF = 2
WEREWOLF_NIGHT_ALWAYS_SHOW = 3

WEREWOLF_TIMER_NONE = 0
WEREWOLF_TIMER_WEREWOLVES = 1
WEREWOLF_TIMER_ALL = 2

WEREWOLF_FOG_NONE = 0
WEREWOLF_FOG_NONWEREWOLVES = 1
WEREWOLF_FOG_ALL = 2

WEREWOLF_VISION_NEVER = 0
WEREWOLF_VISION_TRANSFORMED = 1
WEREWOLF_VISION_ALWAYS = 2

WEREWOLF = {
    isNight = false,
    nightTime = 0
}

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_WerewolfSetNight")

    local werewolf_drop_weapons = CreateConVar("ttt_werewolf_drop_weapons", 0, FCVAR_NONE, "Whether Werewolves should drop their weapons on the ground when transforming")
    local werewolf_transform_model = CreateConVar("ttt_werewolf_transform_model", 1, FCVAR_NONE, "Whether the Werewolves' player models should change to a Werewolf while transformed")

    --------------------
    -- TRANSFORMATION --
    --------------------

    local oldPlayerModels = {}

    local transformSounds = {
        "wwf/transform1.wav",
        "wwf/transform2.wav",
        "wwf/transform3.wav"
    }

    local function TransformWerewolf(ply)
        if ply:IsRoleAbilityDisabled() then return end

        local drop_weapons = werewolf_drop_weapons:GetBool()
        if drop_weapons then
            for _, wep in pairs(ply:GetWeapons()) do
                local class = WEPS.GetClass(wep)
                if class ~= "weapon_zm_improvised" and class ~= "weapon_wwf_claws" and wep.AllowDrop then
                    ply:DropWeapon(wep)
                end
            end
        end
        ply:Give("weapon_wwf_claws")
        ply:SelectWeapon("weapon_wwf_claws")
        ply:DoAnimationEvent(ACT_GMOD_GESTURE_TAUNT_ZOMBIE)
        ply:EmitSound(transformSounds[MathRandom(1, #transformSounds)])

        local transform_model = werewolf_transform_model:GetBool()
        if transform_model and util.IsValidModel("models/player/captainPawn/fenrir.mdl") then
            oldPlayerModels[ply:SteamID64()] = ply:GetModel()
            SetMDL(ply, "models/player/captainPawn/fenrir.mdl")
            ply:SetupHands()
        end
    end

    ------------------------
    -- DAY/NIGHT TRACKING --
    ------------------------

    WEREWOLF.ChangeTime = function(forceDay, hideMessages, blockTimers)
        local min, max
        if WEREWOLF.isNight or forceDay then
            min = werewolf_day_length_min:GetInt()
            max = werewolf_day_length_max:GetInt()
            WEREWOLF.isNight = false
        else
            min = werewolf_night_length_min:GetInt()
            max = werewolf_night_length_max:GetInt()
            WEREWOLF.isNight = true
        end

        if max < min then
            max = min
        end
        local length = MathRandom(min, max)
        if blockTimers then
            length = 0
            WEREWOLF.nightTime = 0
        else
            WEREWOLF.nightTime = CurTime() + length
        end

        net.Start("TTT_WerewolfSetNight")
        net.WriteBool(WEREWOLF.isNight)
        net.WriteUInt(length, 10)
        net.Broadcast()

        local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
        for _, v in PlayerIterator() do
            if not hideMessages then
                if v:IsActiveWerewolf() or night_visibility_mode >= WEREWOLF_NIGHT_SHOW_IF_HAS_WEREWOLF then
                    if WEREWOLF.isNight then
                        v:QueueMessage(MSG_PRINTTALK, "Night falls...")
                    else
                        v:QueueMessage(MSG_PRINTTALK, "The sun rises...")
                    end
                end
            end

            if v:IsActiveWerewolf() then
                if WEREWOLF.isNight then
                    TransformWerewolf(v)
                else
                    v:StripWeapon("weapon_wwf_claws")
                    if oldPlayerModels[v:SteamID64()] then
                        SetMDL(v, oldPlayerModels[v:SteamID64()])
                        v:SetupHands()
                    end
                end
            end
        end

        if not WEREWOLF.isNight then
            TableEmpty(oldPlayerModels)
        end

        if not blockTimers then
            timer.Create("TTTWerewolfTimeChange", length, 1, function()
                WEREWOLF.ChangeTime()
            end)
        end
    end

    AddHook("TTTBeginRound", "Werewolf_TTTBeginRound", function()
        local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
        if night_visibility_mode == WEREWOLF_NIGHT_ALWAYS_SHOW and util.CanRoleSpawn(ROLE_WEREWOLF) and not timer.Exists("TTTWerewolfTimeChange") then
            WEREWOLF.ChangeTime(true, true, false)
        end
    end)

    AddHook("PlayerSpawn", "Werewolf_PlayerSpawn", function(ply)
        if ply:IsWerewolf() and not timer.Exists("TTTWerewolfTimeChange") then
            WEREWOLF.ChangeTime(true, true, false)
        end
    end)

    -----------------------
    -- DAMAGE REDUCTIONS --
    -----------------------

    AddHook("EntityTakeDamage", "Werewolf_EntityTakeDamage", function(ent, dmginfo)
        if GetRoundState() < ROUND_ACTIVE then return end

        if WEREWOLF.isNight then
            if not ent:IsPlayer() or not ent:IsWerewolf() then return end
            if ent:IsRoleAbilityDisabled() then return end

            local reduction = werewolf_night_damage_reduction:GetFloat()
            dmginfo:ScaleDamage(1 - reduction)
        else
            local att = dmginfo:GetAttacker()
            if not IsPlayer(att) or not att:IsWerewolf() then return end

            local penalty = werewolf_day_damage_penalty:GetFloat()
            dmginfo:ScaleDamage(1 - penalty)
        end
    end)

    AddHook("TTTDrawHitMarker", "Werewolf_TTTDrawHitMarker", function(victim, dmginfo)
        if not WEREWOLF.isNight then return end

        local reduction = werewolf_night_damage_reduction:GetFloat()
        if reduction < 1 then return end

        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) or not IsPlayer(victim) then return end

        if victim:IsWerewolf() and not victim:IsRoleAbilityDisabled() then
            return true, false, true, false
        end
    end)

    AddHook("OnPlayerHitGround", "Werewolf_OnPlayerHitGround", function(ply, in_water, on_floater, speed)
        if WEREWOLF.isNight and ply:IsWerewolf() and not ply:IsRoleAbilityDisabled() and GetRoundState() >= ROUND_ACTIVE then
            return true
        end
    end)

    ----------------------------
    -- ACTIVE WEREWOLF CHECKS --
    ----------------------------

    local function CheckForActiveWerewolf()
        if not timer.Exists("TTTWerewolfTimeChange") then return end

        local werewolf = player.GetLivingRole(ROLE_WEREWOLF)
        if werewolf then return end

        local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
        if night_visibility_mode == WEREWOLF_NIGHT_SHOW_IF_HAS_WEREWOLF then
            timer.Remove("TTTWerewolfTimeChange")
            if WEREWOLF.isNight then
                WEREWOLF.ChangeTime(true, false, true)
            end
        end
    end

    AddHook("PlayerDeath", "Werewolf_PlayerDeath", function(victim, infl, attacker)
        CheckForActiveWerewolf()
    end)

    AddHook("PlayerDisconnected", "Werewolf_PlayerDisconnected", function(ply)
        CheckForActiveWerewolf()
    end)

    AddHook("TTTPlayerRoleChanged", "Werewolf_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        CheckForActiveWerewolf()

        if not WEREWOLF.isNight then return end

        if newRole == ROLE_WEREWOLF and oldRole ~= ROLE_WEREWOLF then
            TransformWerewolf(ply)
        elseif oldRole == ROLE_WEREWOLF and newRole ~= ROLE_WEREWOLF then
            ply:StripWeapon("weapon_wwf_claws")
            if oldPlayerModels[ply:SteamID64()] then
                SetMDL(ply, oldPlayerModels[ply:SteamID64()])
                ply:SetupHands()
            end
        end
    end)

    ---------------------
    -- DISABLE WEAPONS --
    ---------------------

    AddHook("PlayerCanPickupWeapon", "Werewolf_PlayerCanPickupWeapon", function(ply, wep)
        if not IsValid(wep) or not IsValid(ply) then return end
        if ply:IsSpec() then return false end

        if WEREWOLF.isNight and ply:IsWerewolf() and WEPS.GetClass(wep) ~= "weapon_wwf_claws" then return false end
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("Initialize", "Werewolf_Initialize", function()
        WIN_WEREWOLF = GenerateNewWinID(ROLE_WEREWOLF)
    end)

    AddHook("TTTCheckForWin", "Werewolf_CheckForWin", function()
        if not INDEPENDENT_ROLES[ROLE_WEREWOLF] then return end

        local werewolf_alive = false
        local other_alive = false
        for _, v in PlayerIterator() do
            if v:Alive() and v:IsTerror() then
                if v:IsWerewolf() then
                    werewolf_alive = true
                elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                    other_alive = true
                end
            end
        end

        if werewolf_alive and not other_alive then
            return WIN_WEREWOLF
        elseif werewolf_alive then
            return WIN_NONE
        end
    end)

    AddHook("TTTPrintResultMessage", "Werewolf_PrintResultMessage", function(type)
        if type == WIN_WEREWOLF then
            LANG.Msg("win_werewolf", { role = ROLE_STRINGS[ROLE_WEREWOLF] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_WEREWOLF] .. " wins.\n")
            return true
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTEndRound", "RemoveHypnotisedHide", function()
        for _, v in PlayerIterator() do
            if oldPlayerModels[v:SteamID64()] then
                SetMDL(v, oldPlayerModels[v:SteamID64()])
                v:SetupHands()
            end
        end
        TableEmpty(oldPlayerModels)

        timer.Remove("TTTWerewolfTimeChange")
        WEREWOLF.ChangeTime(true, true, true)
    end)

    AddHook("TTTPrepareRound", "Werewolf_TTTPrepareRound", function()
        timer.Remove("TTTWerewolfTimeChange")
        WEREWOLF.ChangeTime(true, true, true)
    end)
end

if CLIENT then
    local client
    ------------------------
    -- DAY/NIGHT TRACKING --
    ------------------------

    net.Receive("TTT_WerewolfSetNight", function()
        WEREWOLF.isNight = net.ReadBool()

        local length = net.ReadUInt(10)
        if length == 0 then
            WEREWOLF.nightTime = 0
        else
            WEREWOLF.nightTime = CurTime() + length
        end
    end)

    ---------------
    -- NIGHT FOG --
    ---------------

    local nightIntensity = 0

    AddHook("SetupWorldFog", "Werewolf_SetupWorldFog", function()
        if not IsPlayer(client) then
            client = LocalPlayer()
        end

        if not WEREWOLF.isNight and nightIntensity == 0 then return end

        if WEREWOLF.isNight and nightIntensity < 1 then
            nightIntensity = nightIntensity + 0.01
            if nightIntensity > 1 then nightIntensity = 1 end
        elseif not WEREWOLF.isNight and nightIntensity > 0 then
            nightIntensity = nightIntensity - 0.01
            if nightIntensity < 0 then nightIntensity = 0 end
        end

        local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
        if not client:IsActiveWerewolf() and night_visibility_mode == WEREWOLF_NIGHT_ONLY_SHOW_WEREWOLVES then return end

        local fog_visibility_mode = werewolf_fog_visibility_mode:GetInt()
        if fog_visibility_mode == WEREWOLF_FOG_NONE then return end
        if client:IsActiveWerewolf() and fog_visibility_mode == WEREWOLF_FOG_NONWEREWOLVES then return end

        local werewolfScale = 1
        if client:IsActiveWerewolf() then werewolfScale = 2 end

        render.FogMode(MATERIAL_FOG_LINEAR)
        render.FogMaxDensity(nightIntensity)
        render.FogColor(0, 0, 0)
        render.FogStart((50 + ((1 - nightIntensity) * 1000)) * werewolfScale)
        render.FogEnd((600 + ((1 - nightIntensity) * 1000)) * werewolfScale)
        return true
    end)

    AddHook("SetupSkyboxFog", "Werewolf_SetupSkyboxFog", function(scale)
        if not IsPlayer(client) then
            client = LocalPlayer()
        end

        if not WEREWOLF.isNight and nightIntensity == 0 then return end

        local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
        if not client:IsActiveWerewolf() and night_visibility_mode == WEREWOLF_NIGHT_ONLY_SHOW_WEREWOLVES then return end

        local fog_visibility_mode = werewolf_fog_visibility_mode:GetInt()
        if fog_visibility_mode == WEREWOLF_FOG_NONE then return end
        if client:IsActiveWerewolf() and fog_visibility_mode == WEREWOLF_FOG_NONWEREWOLVES then return end

        local werewolfScale = 1
        if client:IsActiveWerewolf() then werewolfScale = 2 end

        render.FogMode(MATERIAL_FOG_LINEAR)
        render.FogMaxDensity(nightIntensity)
        render.FogColor(0, 0, 0)
        render.FogStart((50 + ((1 - nightIntensity) * 1000)) * werewolfScale * scale)
        render.FogEnd((600 + ((1 - nightIntensity) * 1000)) * werewolfScale * scale)
        return true
    end)

    ------------------
    -- SCREEN TINTS --
    ------------------

    AddHook("RenderScreenspaceEffects", "Werewolf_RenderScreenspaceEffects", function()
        if not WEREWOLF.isNight and nightIntensity == 0 then return end

        if not IsPlayer(client) then
            client = LocalPlayer()
        end
        local bloodthirst_tint = werewolf_bloodthirst_tint:GetBool()
        if client:IsActiveWerewolf() and bloodthirst_tint then
            DrawColorModify({
                ["$pp_colour_addr"] = 0,
                ["$pp_colour_addg"] = 0,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 1 - (nightIntensity * 0.7),
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })

            DrawColorModify({
                ["$pp_colour_addr"] = 0,
                ["$pp_colour_addg"] = nightIntensity * -0.5,
                ["$pp_colour_addb"] = nightIntensity * -0.5,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 1,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })
        else
            local night_tint = werewolf_night_tint:GetBool()
            if not night_tint then return end

            local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
            if not client:IsActiveWerewolf() and night_visibility_mode == WEREWOLF_NIGHT_ONLY_SHOW_WEREWOLVES then return end

            DrawColorModify({
                ["$pp_colour_addr"] = 0,
                ["$pp_colour_addg"] = 0,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 1 - (nightIntensity * 0.2),
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })

            DrawColorModify({
                ["$pp_colour_addr"] = nightIntensity * -0.5,
                ["$pp_colour_addg"] = nightIntensity * -0.2,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 1,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })
        end
    end)

    ---------------
    -- TARGET ID --
    ---------------

    AddHook("TTTTargetIDPlayerTargetIcon", "Werewolf_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
        local show_target_icon = werewolf_show_target_icon:GetInt()
        if cli:IsActiveWerewolf() and (show_target_icon == WEREWOLF_VISION_ALWAYS or (show_target_icon == WEREWOLF_VISION_TRANSFORMED and WEREWOLF.isNight)) and not showJester and not cli:IsSameTeam(ply) then
            return "kill", true, ROLE_COLORS_SPRITE[ROLE_WEREWOLF], "down"
        end
    end)

    AddHook("TTTTargetIDPlayerBlockIcon", "Werewolf_TTTTargetIDPlayerBlockIcon", function(ply, cli)
        if not ply:IsPlayer() or not cli:IsPlayer() then return end
        if not WEREWOLF.isNight then return end

        local hide_id = werewolf_hide_id:GetBool()
        if not hide_id then return end

        if ply:IsActiveWerewolf() then return true end
    end)

    AddHook("TTTTargetIDPlayerBlockInfo", "Werewolf_TTTTargetIDPlayerBlockInfo", function(ply, cli)
        if not ply:IsPlayer() or not cli:IsPlayer() then return end
        if not WEREWOLF.isNight then return end

        local hide_id = werewolf_hide_id:GetBool()
        if not hide_id then return end

        if ply:IsActiveWerewolf() then return true end
    end)

    ------------------
    -- HIGHLIGHTING --
    ------------------

    local werewolf_can_see_jesters = GetConVar("ttt_werewolf_can_see_jesters")
    local jesters_visible_to_monsters = GetConVar("ttt_jesters_visible_to_monsters")

    local werewolf_vision = false
    local vision_enabled = false
    local can_see_jesters_independent = false
    local can_see_jesters_monster = false

    local function EnableWerewolfHighlights()
        AddHook("PreDrawHalos", "Werewolf_Highlight_PreDrawHalos", function()
            local allies
            local can_see_jesters
            if INDEPENDENT_ROLES[ROLE_WEREWOLF] then
                allies = {ROLE_WEREWOLF}
                can_see_jesters = can_see_jesters_independent
            else
                allies = GetTeamRoles(MONSTER_ROLES)
                can_see_jesters = can_see_jesters_monster
            end
            OnPlayerHighlightEnabled(client, allies, can_see_jesters, false, false)
        end)
    end

    AddHook("TTTUpdateRoleState", "Werewolf_Highlight_TTTUpdateRoleState", function()
        if not IsPlayer(client) then
            client = LocalPlayer()
        end

        local vision_mode = werewolf_vision_mode:GetInt()
        werewolf_vision = vision_mode >= WEREWOLF_VISION_TRANSFORMED
        can_see_jesters_independent = werewolf_can_see_jesters:GetBool()
        can_see_jesters_monster = jesters_visible_to_monsters:GetBool()

        if vision_enabled then
            RemoveHook("PreDrawHalos", "Werewolf_Highlight_PreDrawHalos")
            vision_enabled = false
        end
    end)

    AddHook("Think", "Werewolf_Highlight_Think", function()
        if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

        if werewolf_vision and client:IsWerewolf() and not client:IsRoleAbilityDisabled() then
            local vision_mode = werewolf_vision_mode:GetInt()
            if not vision_enabled and (vision_mode == WEREWOLF_VISION_ALWAYS or WEREWOLF.isNight) then
                EnableWerewolfHighlights()
                vision_enabled = true
            elseif vision_enabled and vision_mode ~= WEREWOLF_VISION_ALWAYS and not WEREWOLF.isNight then
                vision_enabled = false
            end
        else
            vision_enabled = false
        end

        if werewolf_vision and not vision_enabled then
            RemoveHook("PreDrawHalos", "Werewolf_Highlight_PreDrawHalos")
        end
    end)

    ROLE_IS_TARGET_HIGHLIGHTED[ROLE_WEREWOLF] = function(ply, target)
        if not ply:IsWerewolf() then return end
        return werewolf_vision
    end

    ---------------------
    -- DAY/NIGHT TIMER --
    ---------------------

    local hide_role = GetConVar("ttt_hide_role")

    AddHook("TTTHUDInfoPaint", "Werewolf_TTTHUDInfoPaint", function(ply, label_left, label_top, active_labels)
        if WEREWOLF.nightTime == 0 then return end

        local timer_visibility_mode = werewolf_timer_visibility_mode:GetInt()
        if timer_visibility_mode == WEREWOLF_TIMER_NONE then return end
        if timer_visibility_mode == WEREWOLF_TIMER_WEREWOLVES and (not ply:IsWerewolf() or hide_role:GetBool()) then return end

        local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
        if night_visibility_mode == WEREWOLF_NIGHT_ONLY_SHOW_WEREWOLVES and (not ply:IsWerewolf() or hide_role:GetBool()) then return end

        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = MathMax(0, WEREWOLF.nightTime - CurTime())
        local translation = "werewolf_timer_night"
        if WEREWOLF.isNight then
            translation = "werewolf_timer_day"
        end
        local text = LANG.GetParamTranslation(translation, { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        TableInsert(active_labels, "werewolf")
    end)

    ----------------
    -- WIN EVENTS --
    ----------------

    AddHook("TTTSyncWinIDs", "Werewolf_TTTWinIDsSynced", function()
        WIN_WEREWOLF = WINS_BY_ROLE[ROLE_WEREWOLF]
    end)

    AddHook("TTTEventFinishText", "Werewolf_EventFinishText", function(e)
        if e.win == WIN_WEREWOLF then
            return LANG.GetParamTranslation("ev_win_werewolf", { role = string.lower(ROLE_STRINGS[ROLE_WEREWOLF]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "Werewolf_EventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_WEREWOLF then
            return win_string, ROLE_STRINGS[ROLE_WEREWOLF]
        end
    end)

    AddHook("TTTScoringWinTitle", "Werewolf_ScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_WEREWOLF then
            return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_WEREWOLF]) }, c = ROLE_COLORS[ROLE_WEREWOLF] }
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Werewolf_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_WEREWOLF then
            local roleTeam = player.GetRoleTeam(ROLE_WEREWOLF, true)
            local _, roleTeamColor = GetRoleTeamInfo(roleTeam, true)

            -- Introduction
            local html = "The " .. ROLE_STRINGS[ROLE_WEREWOLF] .. " is "
            if roleTeam == ROLE_TEAM_INDEPENDENT then
                html = html .. "an <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>independent</span> role"
            else
                html = html .. "a member of the <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>monster team</span>"
            end
            html = html .. " who is weak during the day but transforms into a powerful monster at night."

            if roleTeam == ROLE_TEAM_INDEPENDENT then
                html = html .. " They win if they are the <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>last player standing</span>."
            end

            -- Night Visibility
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_WEREWOLF] .. " adds <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>day</span> and <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>night</span> phases to the game which "
            local night_visibility_mode = werewolf_night_visibility_mode:GetInt()
            if night_visibility_mode == WEREWOLF_NIGHT_ONLY_SHOW_WEREWOLVES then
                html = html .. "are only visible to " .. ROLE_STRINGS_PLURAL[ROLE_WEREWOLF] .. ".</span>"
            elseif night_visibility_mode == WEREWOLF_NIGHT_SHOW_IF_HAS_WEREWOLF then
                html = html .. "are visible to all players if " .. ROLE_STRINGS_EXT[ROLE_WEREWOLF] .. " is alive.</span>"
            elseif night_visibility_mode == WEREWOLF_NIGHT_SHOW_IF_HAD_WEREWOLF then
                html = html .. "are visible to all players if " .. ROLE_STRINGS_EXT[ROLE_WEREWOLF] .. " is in the round.</span>"
            else
                html = html .. "are visible to all players.</span>"
            end

            -- Day and Night Length
            html = html .. "<span style='display: block; margin-top: 10px;'>Rounds start during the <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>day phase</span> which lasts "
            local day_length_min = werewolf_day_length_min:GetInt()
            local day_length_max = werewolf_day_length_max:GetInt()
            if day_length_min == day_length_max then
                html = html .. day_length_min
            elseif day_length_min < day_length_max then
                html = html .. "between " .. day_length_min .. " and " .. day_length_max
            else
                html = html .. "between " .. day_length_max .. " and " .. day_length_min
            end
            html = html .. " seconds. After which the <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>night phase</span> begins which lasts "
            local night_length_min = werewolf_night_length_min:GetInt()
            local night_length_max = werewolf_night_length_max:GetInt()
            if night_length_min == night_length_max then
                html = html .. night_length_min
            elseif night_length_min < night_length_max then
                html = html .. "between " .. night_length_min .. " and " .. night_length_max
            else
                html = html .. "between " .. night_length_max .. " and " .. night_length_min
            end
            html = html .. " seconds. Day and night will continue to alternate throughout the round."
            local timer_visibility_mode = werewolf_timer_visibility_mode:GetInt()
            if timer_visibility_mode ~= WEREWOLF_TIMER_NONE then
                if timer_visibility_mode == WEREWOLF_TIMER_WEREWOLVES or night_visibility_mode == WEREWOLF_NIGHT_ONLY_SHOW_WEREWOLVES then
                    html = html .. " " .. ROLE_STRINGS_PLURAL[ROLE_WEREWOLF]
                else
                    html = html .. " Players"
                end
                html = html .. " can see a timer showing how long until nightfall/sunrise."
            end
            html = html .. "</span>"

            -- Highlighting and Target Icons
            local vision_mode = werewolf_vision_mode:GetInt()
            local show_target_icon = werewolf_show_target_icon:GetInt()
            if vision_mode == WEREWOLF_VISION_ALWAYS then
                html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>blood lust</span> helps them see their targets through walls by highlighting their enemies"
                if show_target_icon == WEREWOLF_VISION_ALWAYS then
                    html = html .. " and marking them with an icon"
                end
                html = html .. ".</span>"
            elseif show_target_icon == WEREWOLF_VISION_ALWAYS then
                html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>blood lust</span> helps them see their targets through walls by marking their enemies with an icon.</span>"
            end

            local day_damage_penalty = werewolf_day_damage_penalty:GetFloat()
            if day_damage_penalty > 0 then
                html = html .. "<span style='display: block; margin-top: 10px;'>During the day " .. ROLE_STRINGS_PLURAL[ROLE_WEREWOLF] .. " deal <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>reduced damage</span>. "
            else
                html = html .. "<span style='display: block; margin-top: 10px;'>"
            end

            -- Day and Night Effects
            html = html .. "At night " .. ROLE_STRINGS_PLURAL[ROLE_WEREWOLF] .. " <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>transform</span> and gain a powerful melee attack, but they are unable to use any other weapons."
            local additionalBuffs = {}
            local night_damage_reduction = werewolf_night_damage_reduction:GetFloat()
            if night_damage_reduction >= 1 then
                TableInsert(additionalBuffs, "they are <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>invulnerable</span>")
            elseif night_damage_reduction > 0 then
                TableInsert(additionalBuffs, "they take <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>reduced damage</span>")
            end
            local night_speed_mult = werewolf_night_speed_mult:GetFloat()
            local night_sprint_recovery = werewolf_night_sprint_recovery:GetFloat()
            local default_sprint_recovery = GetConVar("ttt_sprint_regenerate_traitor"):GetFloat()
            if night_speed_mult > 1 or night_sprint_recovery > default_sprint_recovery then
                TableInsert(additionalBuffs, "they can <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>move faster</span>")
            end
            local leap_enabled = GetConVar("ttt_werewolf_leap_enabled"):GetBool()
            if leap_enabled then
                TableInsert(additionalBuffs, "they can <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>leap into the air</span>")
            end
            local hide_id = werewolf_hide_id:GetBool()
            if hide_id then
                TableInsert(additionalBuffs, "their name is <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>hidden</span> from other players")
            end
            if (vision_mode == WEREWOLF_VISION_TRANSFORMED or show_target_icon == WEREWOLF_VISION_TRANSFORMED) and vision_mode ~= WEREWOLF_VISION_ALWAYS and show_target_icon ~= WEREWOLF_VISION_ALWAYS then
                TableInsert(additionalBuffs, "they can <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>see other players though walls</span>")
            end
            if #additionalBuffs > 0 then
                html = html .. " In addition, " .. util.FormattedList(additionalBuffs)
            end
            html = html .. "</span>"

            return html
        end
    end)
end

-----------------------------
-- SPEED AND STAMINA BUFFS --
-----------------------------

AddHook("TTTSpeedMultiplier", "Werewolf_TTTSpeedMultiplier", function(ply, mults)
    if WEREWOLF.isNight and IsPlayer(ply) and ply:IsActiveWerewolf() then
        TableInsert(mults, werewolf_night_speed_mult:GetFloat())
    end
end)

AddHook("TTTSprintStaminaRecovery", "Werewolf_TTTSprintStaminaRecovery", function(ply, recovery)
    if WEREWOLF.isNight and IsPlayer(ply) and ply:IsActiveWerewolf() then
        return werewolf_night_sprint_recovery:GetFloat()
    end
end)

-------------------------
-- MONSTER TEAM OPTION --
-------------------------

AddHook("TTTUpdateRoleState", "Werewolf_TTTUpdateRoleState", function()
    local is_monster = werewolf_is_monster:GetBool()
    MONSTER_ROLES[ROLE_WEREWOLF] = is_monster
    INDEPENDENT_ROLES[ROLE_WEREWOLF] = not is_monster
end)
