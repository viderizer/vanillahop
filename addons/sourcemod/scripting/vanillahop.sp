#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

public Plugin myinfo =
{
	name = "vanillahop",
	author = "viderizer",
	description = "hold space to jump!",
	version = "0.4",
	url = ""
};

bool autohopEnabled[MAXPLAYERS + 1] = {true, ...};
ConVar sm_autohop_enabled;
Handle cookie_sm_autohop;

public void OnPluginStart()
{
	// Server-side
	LoadTranslations("vanillahop.phrases.txt");
	AutoExecConfig(true);
	sm_autohop_enabled = CreateConVar("sm_autohop_enable", "1", "Enables autohop (0/1)", FCVAR_NOTIFY);

	// Client-side
	RegConsoleCmd("sm_autohop", command_sm_autohop);
	cookie_sm_autohop = RegClientCookie("sm_autohop", "enable autohop", CookieAccess_Private);

	// Lateload cookies
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
}

/**
 * Callback for /autohop. We toggle the value and set client cookie accordingly.
 *
 * @param client  client id
 * @param argc  count of arguments given
 * @return Action
 */
public Action command_sm_autohop(int client, int argc)
{
	autohopEnabled[client] = !autohopEnabled[client];

	if (AreClientCookiesCached(client)) {
		SetClientCookie(client, cookie_sm_autohop, autohopEnabled[client] ? "1" : "0");
	}

	ReplyToCommand(client, "%t", autohopEnabled[client] ? "autohop_enabled" : "autohop_disabled", "\x07/autohop\x01");

	return Plugin_Handled;
}

/**
 * This is called when a joining players' client cookies are cached.
 * We read them and set value to internal array.
 *
 * @param client  client id
 * @noreturn
 */
public void OnClientCookiesCached(int client) {
	char cookieBuffer[2];
	GetClientCookie(client, cookie_sm_autohop, cookieBuffer, sizeof cookieBuffer);
	if (!cookieBuffer) {
		// hasn't used plugin before, initialize with true
		SetClientCookie(client, cookie_sm_autohop, "1");
	} else {
		autohopEnabled[client] = StringToInt(cookieBuffer) ? true : false;
	}
}

/**
 * Called when processing player movement keys.
 *
 * Bunnyhopping traditionally works by jumping again on the same tick you hit the ground.
 * We fake your buttons so that the server thinks you are not holding space while in air
 * and hit it just as you hit the ground.
 *
 * @param client   client id
 * @param buttons  buttons currently pressed
 * @return Action
 */
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (sm_autohop_enabled.BoolValue && autohopEnabled[client] && IsPlayerAlive(client) && !(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityMoveType(client) & MOVETYPE_LADDER) && GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1) {
		buttons &= ~IN_JUMP;
	}

	return Plugin_Continue;
}
