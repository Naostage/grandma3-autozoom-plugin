export let IMPORTED_MACROS = [
    {
        name: "AZ ENABLE",
        commands: [
            'Lua "AZ:Enable()"'
        ]
    },
    {
        name: "AZ DISABLE",
        commands: [
            'Lua "AZ:Disable()"'
        ]
    },
    {
        name: "AZ ShowEnabled",
        commands: [
            'Lua "AZ:ShowEnabled()"'
        ]
    },
    {
        name: "AZ RESCAN PATCH",
        commands: [
            'Lua "AZ:ScanPatch()"'
        ]
    },
    {
        name:"AZ PRINT PATCH",
        commands:[
            'Lua "AZ:PrintCurrentPatch()"'
        ]
    },
    {
        name: "AZ GET FIXTURE STATUS",
        commands: [
            'Lua "AZ:GetFixturesStatus()"'
        ]
    },
    {
        name: "AZ DISABLE ALL FIXTURES",
        commands: [
            'Lua "AZ:DisableAllFixtures()"'
        ]
    },
    {
        name: "AZ Example ENABLE FIXTURE",
        commands: [
            'Lua "AZ:EnableFixture(301,1001,3)"'
        ]
    },
    {
        name: "AZ Example DISABLE FIXTURE",
        commands: [
            'Lua "AZ:DisableFixture(301)"'
        ]
    },
    {
        name: "AZ Example ENABLE SIZE FADER",
        commands: [
            'Lua "AZ:EnableSizeFader(301)"'
        ]
    },
    {
        name: "AZ Example DISABLE SIZE FADER",
        commands: [
            'Lua "AZ:DisableSizeFader(301)"'
        ]
    },
    {
        name: "AZ ENABLE GLOBAL SIZE FADER",
        commands: [
            'Lua "AZ:EnableGlobalSizeFader()"'
        ]
    },
    {
        name: "AZ DISABLE GLOBAL SIZE FADER",
        commands: [
            'Lua "AZ:DisableGlobalSizeFader()"'
        ]
    },
    {
        name: "AZ SET SIZE FADER RANGE",
        commands: [
            'Lua "AZ:SetSizeFaderRange(0,5)"'
        ]
    },
    {
        name: "AZ Example CREATE AZ SEQUENCES FOR FIXTURE",
        commands: [
            'Lua "AZ:CreateAZSequences(301)"'
        ]
    },
    {
        name: "AZ Enable Datapool",
        commands: [
            'Lua "AZ:EnableDatapool()"'
        ]
    },
    {
        name: "AZ Disable Datapool",
        commands: [
            'Lua "AZ:DisableDatapool()"'
        ]
    }
]