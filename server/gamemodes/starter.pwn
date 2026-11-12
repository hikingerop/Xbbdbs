#define MAX_PLAYERS 100
#include <a_samp>

#define COLOR_INFO 0x7EC8FFFF
#define COLOR_OK 0x80E080FF
#define COLOR_ERROR 0xFF9090FF
#define STARTING_MONEY 1000000
#define STARTING_DONATE 1000000
#define DIALOG_TEST_BALANCE 22222

new PlayerVehicle[MAX_PLAYERS];
new CameraRestoreTimer[MAX_PLAYERS];
new DB:WalletDB;
new PlayerCash[MAX_PLAYERS];
new PlayerDonate[MAX_PLAYERS];
new bool:WalletLoaded[MAX_PLAYERS];
new WalletName[MAX_PLAYERS][MAX_PLAYER_NAME * 2 + 1];

stock EscapeWalletName(const name[], output[], size)
{
    new dest;
    for (new i; name[i] && dest < size - 1; i++)
    {
        if (name[i] == 39)
        {
            if (dest >= size - 2) break;
            output[dest++] = 39;
        }
        output[dest++] = name[i];
    }
    output[dest] = 0;
    return 1;
}

stock LoadWallet(playerid, const name[])
{
    WalletLoaded[playerid] = false;
    PlayerCash[playerid] = 0;
    PlayerDonate[playerid] = 0;
    if (!WalletDB) return 0;
    EscapeWalletName(name, WalletName[playerid], sizeof WalletName[]);
    new query[256];
    format(query, sizeof query, "INSERT OR IGNORE INTO wallets (nickname, cash, donate) VALUES ('%s', %d, %d)", WalletName[playerid], STARTING_MONEY, STARTING_DONATE);
    new DBResult:result = db_query(WalletDB, query);
    if (!result) return 0;
    db_free_result(result);
    format(query, sizeof query, "SELECT cash, donate FROM wallets WHERE nickname = '%s'", WalletName[playerid]);
    result = db_query(WalletDB, query);
    if (!result) return 0;
    if (db_num_rows(result) != 1)
    {
        db_free_result(result);
        return 0;
    }
    PlayerCash[playerid] = db_get_field_int(result, 0);
    PlayerDonate[playerid] = db_get_field_int(result, 1);
    db_free_result(result);
    WalletLoaded[playerid] = true;
    return 1;
}

stock SaveWallet(playerid)
{
    if (!WalletDB || !WalletLoaded[playerid]) return 0;
    new query[256];
    format(query, sizeof query, "UPDATE wallets SET cash = %d, donate = %d WHERE nickname = '%s'", PlayerCash[playerid], PlayerDonate[playerid], WalletName[playerid]);
    new DBResult:result = db_query(WalletDB, query);
    if (!result) return 0;
    db_free_result(result);
    return 1;
}

stock ShowWalletBalance(playerid)
{
    new line[128];
    format(line, sizeof line, "Virtual money: %d | Test donate BC: %d", PlayerCash[playerid], PlayerDonate[playerid]);
    SendClientMessage(playerid, COLOR_OK, line);
    return 1;
}

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
    WalletDB = db_open("starter-wallets.db");
    if (!WalletDB)
    {
        print("RP_STARTER_WALLET_ERROR: cannot open scriptfiles/starter-wallets.db");
        return 1;
    }
    new DBResult:result = db_query(WalletDB, "CREATE TABLE IF NOT EXISTS wallets (nickname TEXT PRIMARY KEY COLLATE NOCASE, cash INTEGER NOT NULL CHECK (cash >= 0), donate INTEGER NOT NULL CHECK (donate >= 0))");
    if (!result)
    {
        db_close(WalletDB);
        WalletDB = DB:0;
        print("RP_STARTER_WALLET_ERROR: cannot create wallet table");
        return 1;
    }
    db_free_result(result);
    SetGameModeText("RP Starter");
    SetWorldTime(12);
    SetWeather(10);
    UsePlayerPedAnims();
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    for (new i = 0; i < MAX_PLAYERS; i++) PlayerVehicle[i] = INVALID_VEHICLE_ID;
    print("RP_STARTER_READY: SA-MP 0.3.7 test mode loaded.");
    print("RP_STARTER_CAMERA_V2: delayed camera reset and /camera enabled.");
    print("RP_STARTER_WALLET_V3: first profile gets 1000000 money and 1000000 test BC.");
    return 1;
}

public OnGameModeExit()
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        if (CameraRestoreTimer[i]) KillTimer(CameraRestoreTimer[i]);
        SaveWallet(i);
    }
    if (WalletDB) db_close(WalletDB);
    WalletDB = DB:0;
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerVehicle[playerid] = INVALID_VEHICLE_ID;
    new name[MAX_PLAYER_NAME + 1];
    GetPlayerName(playerid, name, sizeof name);
    if (!LoadWallet(playerid, name))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Wallet storage unavailable. Check the server console.");
        Kick(playerid);
        return 0;
    }
    SendClientMessage(playerid, COLOR_INFO, "Welcome to your local multiplayer starter. Use /help.");
    ShowWalletBalance(playerid);
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
    if (!WalletLoaded[playerid]) return 0;
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerHealth(playerid, 100.0);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerCash[playerid]);
    ResetPlayerCamera(playerid);
    // The mobile client's transition can finish after the spawn RPCs arrive.
    if (CameraRestoreTimer[playerid]) KillTimer(CameraRestoreTimer[playerid]);
    CameraRestoreTimer[playerid] = SetTimerEx("RestoreSpawnCamera", 1500, false, "i", playerid);
    SendClientMessage(playerid, COLOR_OK, "Spawn complete. This is a test mode, not the Black Russia server mode.");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    SaveWallet(playerid);
    WalletLoaded[playerid] = false;
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
        SendClientMessage(playerid, COLOR_INFO, "Commands: /help /spawn /camera /car /stats /balance /donate");
        return 1;
    }
    if (!strcmp(cmdtext, "/balance", true) || !strcmp(cmdtext, "/donate", true))
    {
        ShowWalletBalance(playerid);
        if (!strcmp(cmdtext, "/donate", true))
        {
            new info[256];
            format(info, sizeof info, "Virtual money: {80E080}%d{FFFFFF}\nTest donate BC: {80E080}%d{FFFFFF}\n\nThese are balances of your RP Starter test server.\nThe native Black Russia shop is not connected yet.", PlayerCash[playerid], PlayerDonate[playerid]);
            ShowPlayerDialog(playerid, DIALOG_TEST_BALANCE, DIALOG_STYLE_MSGBOX, "RP Starter - Test Balance", info, "Close", "");
        }
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
        ShowWalletBalance(playerid);
        format(line, sizeof line, "State: %d | Position: %.1f, %.1f, %.1f", GetPlayerState(playerid), x, y, z);
        SendClientMessage(playerid, COLOR_INFO, line);
        return 1;
    }
    SendClientMessage(playerid, COLOR_ERROR, "Unknown command. Use /help.");
    return 1;
}
