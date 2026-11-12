#define MAX_PLAYERS 100
#include <a_samp>

#define COLOR_INFO 0x7EC8FFFF
#define COLOR_OK 0x80E080FF
#define COLOR_ERROR 0xFF9090FF

new PlayerVehicle[MAX_PLAYERS];
new CameraRestoreTimer[MAX_PLAYERS];

forward RestoreSpawnCamera(playerid);

stock ResetPlayerCamera(playerid)
{
    TogglePlayerControllable(playerid, true);
    SetCameraBehindPlayer(playerid);
    return 1;
}

public RestoreSpawnCamera(playerid)
{
    CameraRestoreTimer[playerid] = 0;
    if (IsPlayerConnected(playerid)) ResetPlayerCamera(playerid);
    return 1;
}

main() {}

public OnGameModeInit()
{
    SetGameModeText("RP Starter");
    SetWorldTime(12);
    SetWeather(10);
    UsePlayerPedAnims();
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    for (new i = 0; i < MAX_PLAYERS; i++) PlayerVehicle[i] = INVALID_VEHICLE_ID;
    print("RP_STARTER_READY: SA-MP 0.3.7 test mode loaded.");
    print("RP_STARTER_CAMERA_V2: delayed camera reset and /camera enabled.");
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerVehicle[playerid] = INVALID_VEHICLE_ID;
    SendClientMessage(playerid, COLOR_INFO, "Welcome to your local multiplayer starter. Use /help.");
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetSpawnInfo(playerid, NO_TEAM, 0, 1958.3783, 1343.1572, 15.3746, 269.1425, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    SpawnPlayer(playerid);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerHealth(playerid, 100.0);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, 1000);
    ResetPlayerCamera(playerid);
    // The mobile client's transition can finish after the spawn RPCs arrive.
    if (CameraRestoreTimer[playerid]) KillTimer(CameraRestoreTimer[playerid]);
    CameraRestoreTimer[playerid] = SetTimerEx("RestoreSpawnCamera", 1500, false, "i", playerid);
    SendClientMessage(playerid, COLOR_OK, "Spawn complete. This is a test mode, not the Black Russia server mode.");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (CameraRestoreTimer[playerid])
    {
        KillTimer(CameraRestoreTimer[playerid]);
        CameraRestoreTimer[playerid] = 0;
    }
    if (PlayerVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PlayerVehicle[playerid]);
        PlayerVehicle[playerid] = INVALID_VEHICLE_ID;
    }
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/help", true))
    {
        SendClientMessage(playerid, COLOR_INFO, "Commands: /help /spawn /camera /car /stats");
        return 1;
    }
    if (!strcmp(cmdtext, "/camera", true))
    {
        ResetPlayerCamera(playerid);
        SendClientMessage(playerid, COLOR_INFO, "Camera reset requested. If the player is missing, send the /stats output.");
        return 1;
    }
    if (!strcmp(cmdtext, "/spawn", true))
    {
        SpawnPlayer(playerid);
        return 1;
    }
    if (!strcmp(cmdtext, "/car", true))
    {
        new Float:x, Float:y, Float:z, Float:angle;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, angle);
        if (PlayerVehicle[playerid] != INVALID_VEHICLE_ID) DestroyVehicle(PlayerVehicle[playerid]);
        PlayerVehicle[playerid] = CreateVehicle(411, x + 3.0, y, z + 0.5, angle, 1, 1, 60);
        SendClientMessage(playerid, COLOR_OK, "Test vehicle created nearby.");
        return 1;
    }
    if (!strcmp(cmdtext, "/stats", true))
    {
        new line[144], Float:health, Float:x, Float:y, Float:z;
        GetPlayerHealth(playerid, health);
        GetPlayerPos(playerid, x, y, z);
        format(line, sizeof line, "Player ID: %d | Money: %d | Health: %.0f", playerid, GetPlayerMoney(playerid), health);
        SendClientMessage(playerid, COLOR_INFO, line);
        format(line, sizeof line, "State: %d | Position: %.1f, %.1f, %.1f", GetPlayerState(playerid), x, y, z);
        SendClientMessage(playerid, COLOR_INFO, line);
        return 1;
    }
    SendClientMessage(playerid, COLOR_ERROR, "Unknown command. Use /help.");
    return 1;
}
