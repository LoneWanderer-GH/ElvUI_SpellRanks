local E, L, V, P, G                           = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local ElvUI_Classic_CastBarSpellRanks         = E:NewModule('ElvUI_Classic_CastBarSpellRanks', 'AceConsole-3.0', 'AceTimer-3.0')
local EP                                      = LibStub("LibElvUIPlugin-1.0")
local addonName, addonTable                   = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2

local UF                                      = E:GetModule('UnitFrames')

--@debug@
local addon_version                           = "DEV_VERSION"
--@end-debug@

--[===[@non-debug@
local addon_version                   = "@project-version@"
--@end-non-debug@]===]

local ORANGEY, LIGHTRED                       = '|cffFF4500', '|cffff6060'

--
local version, build, date, build_toc_version = GetBuildInfo()
local major_version                           = floor(build_toc_version / 10000)

--@version-classic@
local MAX_SUPPORTED_VERSION                   = 19999
--@end-version-classic@

--@version-bcc@
local MAX_SUPPORTED_VERSION                   = 20502
--@end-version-bcc@

local MAX_MAJOR_VERSION                       = floor(MAX_SUPPORTED_VERSION / 10000)

P["ElvUI_Classic_CastBarSpellRanks"]          = {
    ["showRank"] = true,
}

E:RegisterModule(ElvUI_Classic_CastBarSpellRanks:GetName())

--@debug@
function ElvUI_Classic_CastBarSpellRanks:logger(message)
    local s = format("|cff1784d1%s|r |cff00b3ff%s|cffff7d0a%s|r %s", "ElvUI", "Spell", "Rank", message)
    if DLAPI then
        DLAPI.DebugLog(addonName, s)
    else
        self:Print(s)
    end
end
--@end-debug@

function ElvUI_Classic_CastBarSpellRanks:Update()
    --@debug@
    self:logger('Update')
    --@end-debug@
    if self.player_cast_bar then
        self.player_cast_bar.showRank = E.db.ElvUI_Classic_CastBarSpellRanks.showRank
    end
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
    plugin:logger(format('custom UF:PostCastStart - spell rank is %s', (tostring(spellRank) or "none")))
    --@end-debug@
    if self.showRank then
        --[===[@non-debug@
        local spellRank = GetSpellSubtext(self.spellID)
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
    if build_toc_version > MAX_SUPPORTED_VERSION or (major_version < MAX_MAJOR_VERSION) then
        print(format("!!! %sBEWARE %s!!!!", LIGHTRED, "|r"))
        local addon_name_and_version_str = format("%s%s v%s", ORANGEY, addonName, addon_version)
        local build_str                  = format("%sbuild|r %s", ORANGEY, build)
        local date_str                   = format("%sdate|r %s", ORANGEY, date)
        local version_nb_str             = format("%sversion number|r %s", ORANGEY, build_toc_version)
        print(format("%s hasn't been updated to support WoW v |r%s - %s - %s - %s",
                     addon_name_and_version_str, version, build_str, date_str, version_nb_str
        ))
        print(format("%sPlease file any bugs you find @ |rhttps://github.com/LoneWanderer-GH/%s/issues", ORANGEY, addonName))
        print(format("%sPlease be precise and provide as much intel as needed (PTR realm, release, beta etc.)", ORANGEY))
        print(format("%sMax supported version is |r%s", ORANGEY, MAX_SUPPORTED_VERSION))
        return false
    end
    return true
end


function ElvUI_Classic_CastBarSpellRanks:do_patch()
    --@debug@
    self:logger('do_patch')
    --@end-debug@

    if not self.patch_done then
        --@debug@
        self:logger('Finding player frame and castbar')
        --@end-debug@


        local player_unit_frame = UF.player
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
        self:logger('Do the patch')
        --@end-debug@

        self.player_cast_bar.PostCastStart = CustomPostCastStart

        --@debug@
        self:logger('Patching UF:PostCastStart --> DONE')
        --@end-debug@

        self.patch_done = true

        --@debug@
        self:logger('initialize rank display to false by default')
        --@end-debug@

        self.player_cast_bar.showRank = E.db.ElvUI_Classic_CastBarSpellRanks.showRank
        self:Print("Patch done")
    end
end

function ElvUI_Classic_CastBarSpellRanks:Initialize()
    --@debug@
    self:logger('Initialize')
    --@end-debug@

    local check = self:VersionCheck()
    if check then
        if not E.db.ElvUI_Classic_CastBarSpellRanks then
            E.db.ElvUI_Classic_CastBarSpellRanks = {}
        end

        EP:RegisterPlugin(addonName, self.InsertOptions)
        self:Update()

        self:ScheduleTimer(self.do_patch, 8, self)

    else
    end
end

