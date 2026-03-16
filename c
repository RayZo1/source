shared.config = {
    ['General'] = {
        ['Toggle'] = 'C',
        ['Mode'] = 'Auto',
        ['Console'] = true,
        ['FpsUnlocker'] = true,
        ['Info'] = {
            ['Enabled'] = true,
            ['Position'] = { X = 500, Y = 600 }
        },
    },

    ['Conditions'] = {
        ['Whilst a player is selected'] = {
            ['Knock Check'] = true,
            ['Self Knocked'] = true,
            ['Visible'] = true,
            ['Crew Check'] = false,
        },
        ['Whilst selecting a player'] = {
            ['Knock Check'] = true,
            ['Self Knocked'] = true,
            ['Visible'] = true,
            ['Crew Check'] = true,
        },
    },

    ['Silent Aim'] = {
        ['Enabled'] = true,
        ['Hit Part'] = 'Closest Point',
        ['Distance'] = 500,
        ['Closest Point'] = {
            ['Type'] = 'Advanced',
            ['Scale'] = 0.67
        },
        ['Prediction'] = { ['X'] = 0, ['Y'] = 0, ['Z'] = 0 },

        -- Bullet Redirection (new)
        ['Redirection'] = {
            ['Enabled'] = true,
            ['Prediction'] = { ['X'] = 0.01, ['Y'] = 0.01, ['Z'] = 0.01 },
            ['Weapons'] = {
                '[Revolver]',
                '[Rifle]',
                '[Silencer]',
                '[Glock]'
            }
        },

        ['FOV'] = {
            ['Enabled'] = true,
            ['Size'] = { ['X'] = 5, ['Y'] = 7, ['Z'] = 3 },
            ['Weapon Configuration'] = {
                ['Enabled'] = true,
                ['Shotguns'] = { ['X'] = 4.2, ['Y'] = 4.4, ['Z'] = 2 },
                ['Pistols']  = { ['X'] = 2.6, ['Y'] = 4.4, ['Z'] = 1.9 },
                ['Others']   = { ['X'] = 3,   ['Y'] = 4,   ['Z'] = 2 }
            }
        }
    },

    ['Camera Aimbot'] = {
        ['Enabled'] = true,
        ['Hit Part'] = 'Closest Part',
        ['Snappiness'] = 0.01,
        ['Prediction'] = { ['X'] = 0, ['Y'] = 0, ['Z'] = 0 },
        ['Camera Aimbot Checks'] = {
            ['First Person'] = true,
            ['Third Person'] = false,
            ['Right Click'] = true,
        },
        ['FOV'] = {
            ['Enabled'] = true,
            ['Size'] = { ['X'] = 30, ['Y'] = 30, ['Z'] = 30 },
            ['Weapon Configuration'] = {
                ['Enabled'] = false,
                ['Shotguns'] = { ['X'] = 15, ['Y'] = 9, ['Z'] = 15 },
                ['Pistols']  = { ['X'] = 15, ['Y'] = 8, ['Z'] = 15 },
                ['Others']   = { ['X'] = 15, ['Y'] = 8, ['Z'] = 15 }
            }
        }
    },

    ['Trigger Bot'] = {
        ['Enabled'] = true,
        ['Click Cooldown'] = 0,
        ['Prediction'] = { ['X'] = 0, ['Y'] = 0, ['Z'] = 0 },
        ['Activation'] = {
            ['Activation Mode'] = 'Hold',
            ['Activation Bind'] = 'V'
        },
        ['FOV'] = { ['X'] = 3, ['Y'] = 4.3, ['Z'] = 1.7 }
    },

    ['ESP'] = {
        ['Enabled'] = false,
        ['Activation'] = {
            ['Activation Mode'] = 'Hold',
            ['Activation Bind'] = 'Y'
        },
        ['Color'] = Color3.fromRGB(255, 255, 255),
        ['Target Color'] = Color3.fromRGB(255, 0, 0),
        ['Use Display Name'] = false,
        ['Name Above'] = false,
    },

    ['Weapon Modifications'] = {
        ['Enabled'] = true,
        ['[Double-Barrel SG]'] = { ['Multiplier'] = 0.77 },
        ['[TacticalShotgun]']  = { ['Multiplier'] = 0.77 },
        ['[Shotgun]']          = { ['Multiplier'] = 0.90 },
        ['[DrumShotgun]']      = { ['Multiplier'] = 0.77 },
    }
}
