local E, L, V, P, G                   = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local ElvUI_Classic_CastBarSpellRanks = E:NewModule('ElvUI_Classic_CastBarSpellRanks', 'AceConsole-3.0');
local EP                              = LibStub("LibElvUIPlugin-1.0")
local addonName, addonTable           = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2

local UF                              = E:GetModule('UnitFrames');

--@debug@
local addon_version                   = "DEV_VERSION"
--@non-debug@

--[===[@debug
local addon_version                   = "@project-version@"
--@end-non-debug@]===]

local ORANGEY, LIGHTRED               = '|cffFF4500', '|cffff6060'
local build_toc_version               = select(4, GetBuildInfo())
-- version numbering is X.XX.XX shorten in param 4 as XXXXX
local MAX_SUPPORTED_CLASSIC_VERSION   = 19999
local IS_CLASSIC                      = (build_toc_version <= MAX_SUPPORTED_CLASSIC_VERSION)

P["ElvUI_Classic_CastBarSpellRanks"]  = {
    --["DebugMode"] = true,
    ["showRank"] = true,
}

E:RegisterModule(ElvUI_Classic_CastBarSpellRanks:GetName())

function ElvUI_Classic_CastBarSpellRanks:logger(message)
    local s = format("|cff1784d1%s|r |cff00b3ff%s|cffff7d0a%s|r %s", "ElvUI", "Spell", "Rank", message)
    if DLAPI then
        DLAPI.DebugLog(addonName, s)
    else
        self:Print(s)
    end
end

function ElvUI_Classic_CastBarSpellRanks:Update()
    --@debug@
    self:logger('Update')
    --@end-debug@
    self.player_cast_bar.showRank = E.db.ElvUI_Classic_CastBarSpellRanks.showRank
end

function ElvUI_Classic_CastBarSpellRanks:InsertOptions()
    --@debug@
    ElvUI_Classic_CastBarSpellRanks:logger("InsertOptions") -- using self triggers an error
    --@end-debug@
    E.Options.args.ElvUI_Classic_CastBarSpellRanks = {
        order       = 1000,
        type        = "group",
        name        = "|cff00b3ffSpell|r |cff00ffdaRank",
        childGroups = "tab",
        args        = {
            name      = {
                order = 1,
                type  = "header",
                name  = "Spell Rank in cast bar options",
            },
            desc      = {
                order = 2,
                type  = "description",
                name  = "",
            },
            credits   = {
                order     = 3,
                type      = "group",
                name      = "Credits",
                guiInline = true,
                args      = {
                    tukui = {
                        order    = 1,
                        type     = "description",
                        fontSize = "medium",
                        name     = format("|cff9482c9LoneWanderer-GH|r"),
                    },
                },
            },
            ShowRanks = {
                order = 4,
                type  = "toggle",
                name  = "Show spell ranks",
                get   = function(info)
                    return E.db.ElvUI_Classic_CastBarSpellRanks.showRank
                end,
                set   = function(info, value)
                    E.db.ElvUI_Classic_CastBarSpellRanks.showRank = value
                    ElvUI_Classic_CastBarSpellRanks:Update()
                end,
            }
        },
    }
end

local function CustomPostCastStart(self, unit)
    --@debug@
    local plugin = self.ElvUI_Classic_CastBarSpellRanks
    plugin:logger('custom UF:PostCastStart')
    local spellRank = GetSpellSubtext(self.spellID)
    plugin:logger(format('custom UF:PostCastStart - spell rank is %s', spellRank))
    --@end-debug@
    if self.showRank then
        --[===[@non-debug@
        --local spellRank = GetSpellSubtext(self.spellID)
        --@end-non-debug@]===]
        if spellRank and spellRank ~= "" then
            --@debug@
            plugin:logger("Changing spellname")
            --@end-debug@
            self.Text:SetText(format("%s [%s]", self.Text:GetText(), spellRank))
            -- changing also spellName since it is weirdly used by base ElvUI in conjunction with the showtarget option
            self.spellName = format("%s [%s]", self.spellName, spellRank)
        end
    end
    self:prev_post_cast_start(unit)
end

function ElvUI_Classic_CastBarSpellRanks:VersionCheck()
    if not IS_CLASSIC then
        local version, build, date, tocversion = GetBuildInfo()
        self:logger(format("!!! %sBEWARE %s!!!!", LIGHTRED, "|r"))

        self:logger(format("%s%s v%s hasn't been updated to support WoW v |r%s - %sbuild|r %s- %sdate|r %s - %sversion number|r %s", ORANGEY, addonName, addon_version, version, ORANGEY, build, ORANGEY, date, ORANGEY, tocversion))
        self:logger(format("%sPlease file any bugs you find @ https://github.com/LoneWanderer-GH/%s/issues", ORANGEY, addonName))
        self:logger(format("%sPlease be precise and provide as much intel as needed (PTR realm, release, beta etc.)", ORANGEY))
        if build_toc_version > MAX_SUPPORTED_CLASSIC_VERSION then
            self:logger(format("%sAssuming unsupported version is classic (%d)", LIGHTRED, MAX_SUPPORTED_CLASSIC_VERSION))
            IS_CLASSIC = true
        end
    end
end

function ElvUI_Classic_CastBarSpellRanks:Initialize()
    --@debug@
    self:logger('Initialize')
    --@end-debug@

    if IS_CLASSIC then
        if not E.db.ElvUI_Classic_CastBarSpellRanks then
            E.db.ElvUI_Classic_CastBarSpellRanks = {}
        end

        --@debug@
        self:logger('Finding player frame and castbar')
        --@end-debug@

        local player_unit_frame = UF["player"]
        self.player_cast_bar    = player_unit_frame.Castbar --castBar

        --@debug@
        self:logger('Saving previous UF:PostCastStart')
        --@end-debug@
        self.player_cast_bar.prev_post_cast_start = self.player_cast_bar.PostCastStart

        --@debug@
        self:logger('Patching UF:PostCastStart')
        --@end-debug@
        self.player_cast_bar.ElvUI_Classic_CastBarSpellRanks = self

        --@debug@
        self:logger('initialize rank display to false by default')
        --@end-debug@
        self.player_cast_bar.showRank = false

        --@debug@
        self:logger('Do the patch')
        --@end-debug@

        self.player_cast_bar.PostCastStart = CustomPostCastStart

        --@debug@
        self:logger('Patching UF:PostCastStart --> DONE')
        --@end-debug@

        EP:RegisterPlugin(addonName, self.InsertOptions)
        self:Update()
    else

    end
end

