CS_TEAM_NONE = 0
CS_TEAM_SPECTATOR = 1
CS_TEAM_T = 2
CS_TEAM_CT = 3

-- Allows our cvars to autocomplete in console
FCVAR_RELEASE = bit.lshift(1, 19)

IN_ATTACK = bit.lshift(1, 0)
IN_JUMP = bit.lshift(1, 1)
IN_DUCK = bit.lshift(1, 2)
IN_FORWARD = bit.lshift(1, 3)
IN_BACK = bit.lshift(1, 4)
IN_USE = bit.lshift(1, 5)
IN_TURNLEFT = bit.lshift(1, 7)
IN_TURNRIGHT = bit.lshift(1, 8)
IN_MOVELEFT = bit.lshift(1, 9)
IN_MOVERIGHT = bit.lshift(1, 10)
IN_ATTACK2 = bit.lshift(1, 11)
IN_RELOAD = bit.lshift(1, 13)
IN_SPEED = bit.lshift(1, 16)
IN_JOYAUTOSPRINT = bit.lshift(1, 17)
IN_USEORRELOAD = bit.lshift(1, 32)
IN_SCORE = bit.lshift(1, 33)
IN_ZOOM = bit.lshift(1, 34)
IN_JUMP_THROW_RELEASE = bit.lshift(1, 35)