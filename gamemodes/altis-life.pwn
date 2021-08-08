#include <a_samp>
#include <a_mysql>
#include <bcrypt>
#include <zcmd>
#include <sscanf2>
#include <streamer>

/* MySQL Daten */

#define MYSQL_HOSTNAME "localhost"
#define MYSQL_USERNAME "root"
#define MYSQL_PASSWORD ""
#define MYSQL_DATABASE "altis-life"

new MySQL:dbhandle;

// Legt die maximale Länge des Namens fest
#undef MAX_PLAYER_NAME
#define MAX_PLAYER_NAME (20)

// Legt die maximale Spieleranzahl fest
#undef MAX_PLAYERS
#define MAX_PLAYERS (50)


// Variable für Benchmark Tests (Zeitberechnung)
new startTime;


// Defines für einfachere Handhabung
#define function%0(%1) forward%0(%1); public%0(%1)
#define SPD ShowPlayerDialog
#define SCM SendClientMessage
#define KickPlayer(%0) SetTimerEx("KickThePlayer", 250, 0, "i", %0)
#define FreezePlayer(%0) TogglePlayerControllable(%0,0)
#define UnFreezePlayer(%0) TogglePlayerControllable(%0,1)
#define Spectate(%0) TogglePlayerSpectating(%0, 1)
#define UnSpectate(%0) TogglePlayerSpectating(%0, 0)
#define PRESSED(%0) (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))

#if !defined IsValidVehicle
    native IsValidVehicle(vehicleid);
#endif

// BCrypt Kosten
#define BCRYPT_COST 14

// Dialog Enum
enum {
	D_LOGIN = 1,
	D_REGISTER,
	D_SHOWSTORAGE
}

enum E_PLAYER {
	pDBID,
	pName[MAX_PLAYER_NAME + 1],
	pSalt[11],
	bool:pLogged,
	pPassword[61],
	bool:pSideChat,
	bool:pInventoryOpend,
	bool:pTrunkOpend,
	pCash,
	pBank,
	pSkin,
	pArea,
	pWeapon0,
	pAmmo0,
	pWeapon1,
	pAmmo1,
	pWeapon2,
	pAmmo2,
	pWeapon3,
	pAmmo3,
	pWeapon4,
	pAmmo4,
	pWeapon5,
	pAmmo5,
	pWeapon6,
	pAmmo6,
	pWeapon7,
	pAmmo7,
	pWeapon8,
	pAmmo8,
	pWeapon9,
	pAmmo9,
	pWeapon10,
	pAmmo10,
	pWeapon11,
	pAmmo11,
	pWeapon12,
	pAmmo12,
	pStorage
};
new pInfo[MAX_PLAYERS][E_PLAYER];

enum E_FIELDS {
	fieldId,
	fieldName[32],
	Float:fieldMinX,
	Float:fieldMinY,
	Float:fieldMaxX,
	Float:fieldMaxY,
	Float:fieldZ,
	fieldColor,
	fieldItem,
	fieldAreaId,
	fieldMapIcon
};

enum E_VEHICLE {
	vVehicleID,
	vDBID,
	vModel,
	vColor1,
	vColor2,
	vOwner,
	vStorage,
	bool:vBoot
};
new vInfo[MAX_VEHICLES][E_VEHICLE];

// Farben definieren
#define COLOR_FAIL 0xFF0000FF
#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_RED 0xFF0000FF
#define COLOR_BLUE 0x0000FFFF
#define COLOR_CYAN 0x00FFFFFF
#define COLOR_PINK 0xFF00FFFF
#define COLOR_YELLOW 0xFFFF00FF
#define COLOR_GREEN 0x00FF00FF
#define COLOR_GREY 0x969696FF
#define COLOR_SIDECHAT 0x00ABFFFF
#define COLOR_ORANGE 0xFFAA00FF
#define COLOR_BROWN 0x9B5200FF

// Inline Farben definieren
#define D_WHITE "{FFFFFF}"
#define D_GREEN "{00FF00}"
#define D_RED "{FF0000}"
#define D_SIDECHAT "{00ABFF}"

// Spieler Spawn Position
#define SPAWN_PLAYER_POS 1479.5073, -1673.8608, 14.0469, 179.8810

// Inventar Text-Draw Definitionen
new PlayerText:inventoryBackgroundBox[MAX_PLAYERS],
	PlayerText:inventoryTitleBox[MAX_PLAYERS],
	PlayerText:inventoryButtonClose[MAX_PLAYERS],
	PlayerText:inventoryButtonSettings[MAX_PLAYERS],
	PlayerText:inventoryButtonGangmenu[MAX_PLAYERS],
	PlayerText:inventoryButtonKeys[MAX_PLAYERS],
	PlayerText:inventoryButtonSMS[MAX_PLAYERS],
	PlayerText:inventoryButtonUpdate[MAX_PLAYERS],
	PlayerText:inventoryButtonAdmin[MAX_PLAYERS],
	PlayerText:inventoryButtonGroups[MAX_PLAYERS],
	PlayerText:inventoryTextMenu[MAX_PLAYERS],
	PlayerText:inventoryTextWeight[MAX_PLAYERS],
	PlayerText:inventoryBoxMoney[MAX_PLAYERS],
	PlayerText:inventoryBoxLicenses[MAX_PLAYERS],
	PlayerText:inventoryBoxItems[MAX_PLAYERS],
	PlayerText:inventoryImageCash[MAX_PLAYERS],
	PlayerText:inventoryImageBank[MAX_PLAYERS],
	PlayerText:inventoryTextBankMoney[MAX_PLAYERS],
	PlayerText:inventoryTextCashMoney[MAX_PLAYERS],
	PlayerText:inventoryButtonGiveMoney[MAX_PLAYERS],
	PlayerText:inventoryTextGiveMoney[MAX_PLAYERS],
	PlayerText:inventoryTestListLicenses[MAX_PLAYERS],
	PlayerText:inventoryTextListItems[MAX_PLAYERS],
	PlayerText:inventoryTextItemAmount[MAX_PLAYERS],
	PlayerText:inventoryButtonItemUse[MAX_PLAYERS],
	PlayerText:inventoryButtonItemGive[MAX_PLAYERS];

// Kofferraum Text-Draw Definitionen
new PlayerText:trunkBoxBackground[MAX_PLAYERS],
	PlayerText:trunkBoxHeader[MAX_PLAYERS],
	PlayerText:trunkBtnClose[MAX_PLAYERS],
	PlayerText:trunkTxtWeight[MAX_PLAYERS],
	PlayerText:trunkBoxHeaderTrunk[MAX_PLAYERS],
	PlayerText:trunkBoxTrunkBackground[MAX_PLAYERS],
	PlayerText:trunkEditTxtTrunkAmount[MAX_PLAYERS],
	PlayerText:trunkBtnTake[MAX_PLAYERS],
	PlayerText:trunkBoxHeaderInv[MAX_PLAYERS],
	PlayerText:trunkBoxInvBackground[MAX_PLAYERS],
	PlayerText:trunkEditTxtInvAmount[MAX_PLAYERS],
	PlayerText:trunkBoxStore[MAX_PLAYERS],
	PlayerText:trunkTextItem1[MAX_PLAYERS],
	PlayerText:trunkTextItem2[MAX_PLAYERS],
	PlayerText:trunkTextItem3[MAX_PLAYERS],
	PlayerText:trunkTextItem4[MAX_PLAYERS],
	PlayerText:trunkTextItem5[MAX_PLAYERS],
	PlayerText:trunkTextItem6[MAX_PLAYERS],
	PlayerText:trunkTextItem7[MAX_PLAYERS],
	PlayerText:trunkTextItem8[MAX_PLAYERS],
	PlayerText:trunkTextItem9[MAX_PLAYERS],
	PlayerText:trunkTextItem10[MAX_PLAYERS],
	PlayerText:trunkTextItem11[MAX_PLAYERS],
	PlayerText:trunkTextItem12[MAX_PLAYERS],
	PlayerText:trunkTextItem13[MAX_PLAYERS],
	PlayerText:trunkTextInvItem1[MAX_PLAYERS],
	PlayerText:trunkTextInvItem2[MAX_PLAYERS],
	PlayerText:trunkTextInvItem3[MAX_PLAYERS],
	PlayerText:trunkTextInvItem4[MAX_PLAYERS],
	PlayerText:trunkTextInvItem5[MAX_PLAYERS],
	PlayerText:trunkTextInvItem6[MAX_PLAYERS],
	PlayerText:trunkTextInvItem7[MAX_PLAYERS],
	PlayerText:trunkTextInvItem8[MAX_PLAYERS],
	PlayerText:trunkTextInvItem9[MAX_PLAYERS],
	PlayerText:trunkTextInvItem10[MAX_PLAYERS],
	PlayerText:trunkTextInvItem11[MAX_PLAYERS],
	PlayerText:trunkTextInvItem12[MAX_PLAYERS],
	PlayerText:trunkTextInvItem13[MAX_PLAYERS];

/*
 *
 * TEXTDRAW INFOS
 * ß == \150;
 * Ö == \145;
 * ö == \168;
 * Ü == \149;
 * ü == \172;
 * Ä == \131;
 * ä == \154;
 * STERN == \95;
 *
*/


// Felder
new const fields[][E_FIELDS] = {
//  {id, name, minx, miny, max, maxy, höhe (z), farbe, farm item}
	{0, "Pfirsich-Feld", 1465.4302, -1713.8336, 1454.9945, -1682.3903, 14.5469, COLOR_ORANGE, 1},
	{1, "Bananen-Feld", 1491.4678, -1682.0530, 1502.1647, -1713.7992, 14.5469, COLOR_YELLOW, 2},
	{2, "Eisenmiene", 1489.8296, -1669.9438, 1469.0613, -1661.8733, 14.5532, COLOR_BROWN, 3}
};



main() {}


/*
 *
 *	Dieses Callback wird aufgerufen, wenn der Gamemode geladen wird.
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 */
public OnGameModeInit() {

	// Starte das Benchmarking
	startTime = GetTickCount();
    
	// Datenbankverbindung
	mysqlConnect();
	
	// Erstelle Datenbank-Tabellen falls sie noch nicht existieren
	CreateDatabaseTables();
	
	// Erstelle Abbau Felder
	CreateMiningFields();
	return true;
}

/*
 *
 *	Diese Funktion erstellt die Abbau Felder
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 */
stock CreateMiningFields() {
	for(new i = 0; i < sizeof(fields); i++) {
	    fields[i][fieldId] = GangZoneCreate(fields[i][fieldMinX], fields[i][fieldMinY], fields[i][fieldMaxX], fields[i][fieldMaxY]);
	    GangZoneShowForAll(fields[i][fieldId], fields[i][fieldColor]);
	    fields[i][fieldAreaId] = CreateDynamicRectangle(fields[i][fieldMinX], fields[i][fieldMinY], fields[i][fieldMaxX], fields[i][fieldMaxY]);

		// Die Koordinaten der Mitte der Area rausfinden
		new const Float:x = fields[i][fieldMinX] + (fields[i][fieldMaxX] - fields[i][fieldMinX]),
		Float:y = fields[i][fieldMinY] + (fields[i][fieldMaxY] - fields[i][fieldMinY]);

		// Map Icon erstellen
	    fields[i][fieldMapIcon] = CreateDynamicMapIcon(x, y, fields[i][fieldZ], 0, fields[i][fieldColor]);
	}
	return true;
}

/*
 *
 *	Diese Funktion zeigt die Abbaufelder für den angegebenen Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@params playerid    Die ID des Spielers
 *
 */
stock ShowMiningFields(playerid) {
	for(new i = 0; i < sizeof(fields); i++) {
	    GangZoneShowForPlayer(playerid, fields[i][fieldId], fields[i][fieldColor]);
	}
	return true;
}

/*
 *
 *	Diese Funktion Speichert ein Fahrzeug in der Datenbank
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@params vehID    Die ID des Fahrzeugs im Enum
 *
 */
stock SaveVehicle(vehID) {
	new query[256];
	mysql_format(dbhandle, query, sizeof(query), "UPDATE `vehicles` SET `model` = '%d', `color1` = '%d', `color2` = '%d' WHERE `id` = '%d'",
		vInfo[vehID][vModel], vInfo[vehID][vColor1], vInfo[vehID][vColor2], vInfo[vehID][vDBID]);
	mysql_tquery(dbhandle, query);
	return true;
}

/*
 *
 *	Diese Funktion erstellt ein Fahrzeug für einen Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@params playerid    Die ID des Spielers
 *  @params modelid		Die ID des Fahrzeugmodells
 *
 */
stock CreatePlayerVehicle(playerid, modelid) {

	new vehID = GetFreeVehicleEnumID();
	
	// Prüfen ob maximale Anzahl an Fahrzeugen erreicht
	if(vehID == -1) return true;
	
	vInfo[vehID][vModel] = modelid;
	vInfo[vehID][vColor1] = 1;
	vInfo[vehID][vColor2] = 1;
	vInfo[vehID][vOwner] = pInfo[playerid][pDBID];
	vInfo[vehID][vBoot] = false;
	
	new Float:playerPos[4];
	GetPlayerPos(playerid, playerPos[0], playerPos[1], playerPos[2]);
	GetPlayerFacingAngle(playerid, playerPos[3]);
	
	vInfo[vehID][vVehicleID] = CreateVehicle(vInfo[vehID][vModel], playerPos[0], playerPos[1] + 5, playerPos[2], playerPos[3], vInfo[vehID][vColor1], vInfo[vehID][vColor2], -1, 0);
	
	SetVehicleParamsEx(vInfo[vehID][vVehicleID], VEHICLE_PARAMS_ON, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_ON, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF, VEHICLE_PARAMS_OFF);
	
	PutPlayerInVehicle(playerid, vInfo[vehID][vVehicleID], 0);
	
	// Fahrzeug-Storage erstellen
	CreateVehicleInventory(vehID);
	
	return true;
}

/*
 *
 *	Diese Funktion weißt dem Emum die Datenbank-ID des Fahrzeuges zu
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@params vehID    Die ID des Fahrzeuges im Enum
 *
 */
function OnPlayerVehicleCreated(vehID) {
	vInfo[vehID][vDBID] = cache_insert_id();
	return true;
}

/*
 *
 *	Diese Funktion gibt eine freie ID im Enum zurück
 *
 *  @return		Freie ID im Enum oder -1, falls keine gefunden wird
 *
 */
stock GetFreeVehicleEnumID() {
	for(new i = 0; i < sizeof(vInfo); i++) {
	    if(vInfo[i][vModel] < 400 || vInfo[i][vModel] > 611) return i;
	}
	return -1;
}


/*
 *
 *  Dieses Callback wird aufgerufen, wenn ein Spieler eine dynamische Area betritt
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @params playerid    Die ID des Spielers der den Server betreten hat
 *	@params areaid    	Die Area, die der Spieler betreten hat
 *
 */
public OnPlayerEnterDynamicArea(playerid, areaid) {
    // Schleife über alle Bereiche
	for(new i = 0; i <  sizeof(fields); i++) {
		// Wenn es nicht die betroffene Area ist
	    if(fields[i][fieldAreaId] != areaid) continue;
	    
	    // Zeige Spieler Nachricht, welches Feld er betreten hat
	    new string[128];
		format(string, sizeof(string), "=> %s betreten", fields[i][fieldName]);
		SendClientMessage(playerid, fields[i][fieldColor], string);
		
		// Setzte Variable das Spieler in diesem Feld ist
		pInfo[playerid][pArea] = i;
		
		break;
	}
	return true;
}

/*
 *
 *	Dieses Callback wird aufgerufen, wenn der Gamemode beendet wird.
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 */
public OnGameModeExit() {
	// Schließen der Datenbankverbindung
	mysql_close(dbhandle);
	return true;
}

/*
 *
 *  Dieses Callback wird aufgerufen, wenn ein Spieler auf den Server verbindet.
 *
 *  @params playerid    Die ID des Spielers der den Server betreten hat
 *  @return 0 - Verhintert das Einbinden von Filterscripts, 1 - Erlaubt das Einbinden von Filterscripts
 *
 */
public OnPlayerConnect(playerid) {
	// Abfrage ob Spieler ein NPC ist, falls ja überspringe das Callback
	if(IsPlayerNPC(playerid)) return true;
	
	// Reset Variables
	pInfo[playerid][pLogged] = false;
	
	// Auslesen des Spielernamens
	GetPlayerName(playerid, pInfo[playerid][pName], MAX_PLAYER_NAME);
	
	// Setze vorab Spawn Position
	SetSpawnInfo(playerid, NO_TEAM, 29, SPAWN_PLAYER_POS, 0, 0, 0, 0, 0, 0);
	
	Spectate(playerid);
	
	// Setze den Spieler an eine gute Position für den Login/Register Hintergrund
	PrepareSpawnPlayer(playerid);
	
	// Zeige Verbindungs-Nachricht an
	new string[144];
	format(string, sizeof(string), "Spieler %s verbindet", GetName(playerid));
	SendClientMessageToAll(COLOR_GREY, string);
	
	// Inventar Text-Draw's laden
	LoadInventoryTextDraws(playerid);
	
	// Kofferraum Text-Draw's laden
	LoadTrunkTextDraws(playerid);
	return true;
}

/*
 *
 *  Diese Funktion gibt den Spielernamen des angegeben Spielers zurück
 *
 *  @params playerid    Die ID des Spielers
 *  @return name        Spielername der zugehörigen playerid
 *
 */
stock GetName(playerid) {
	new name[MAX_PLAYER_NAME + 1];
	format(name, sizeof(name), pInfo[playerid][pName]);
	return name;
}

/*
 *
 *  Spawnt den Spieler und Freezt ihn, bevor er zum Login/Register kommt
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @params playerid    Die ID des Spielers
 *
 */
stock PrepareSpawnPlayer(playerid) {
	SpawnPlayer(playerid);
	FreezePlayer(playerid);
	return true;
}

/*
 *
 *  Dieses Callback wird aufgerufen, wenn ein Spieler spawnt.
 *
 *  @params playerid    Die ID des Spielers
 *  @return 0 - Der Spieler muss beim nächsten Spawn eine neue Klasse wählen
 *
 */
public OnPlayerSpawn(playerid) {
	// Abfrage ob Spieler eingeloggt ist
	if(!pInfo[playerid][pLogged]) {
	
	    // Zeige Login/Register Hintergrund
	    SetPlayerCameraPos(10, 10 , 10, 10);
	    SetPlayerCameraLookAt(0, 0, 0, 6);

		// Überprüfe ob der Spieler in der Datenbank existiert
		new query[256];
		mysql_format(dbhandle, query, sizeof(query), "SELECT `salt`, `password` FROM `users` WHERE `name` = '%e' LIMIT 1", pInfo[playerid][pName]);
		mysql_tquery(dbhandle, query, "AccountCheck", "d", playerid);
	
	} else {
	    //
	}
	return true;
}

/*
 *
 *  Diese Funktion überprüft ob der Spieler einen Account hat
 *  Leitet an Regis
 *  Dazu bekommt sie den cache der SQL Abfrage
 *
 *  @params playerid    Die ID des Spielers
 *  @return 0 - Verhintert das Einbinden von Filterscripts, 1 - Erlaubt das Einbinden von Filterscripts
 *
 */
function AccountCheck(playerid) {
	// Überprüfe ob Reihen im Cache sind
	if(cache_num_rows()) {
	    // Account mit dem Namen existiert bereits
	    cache_get_value_name(0, "password", pInfo[playerid][pPassword], 61);
		cache_get_value_name(0, "salt", pInfo[playerid][pSalt], 11);
		ShowLoginDialog(playerid);
	} else {
	    // Kein Account mit dem Namen registriert
	    ShowRegisterDialog(playerid);
	}
	return true;
}

/*
 *
 *  Zeigt den Einloggen-Dialog für den angegeben Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @params playerid    Die ID des Spielers
 *
 */
stock ShowLoginDialog(playerid) {
	new string[256];
	format(string, sizeof(string), D_WHITE"Moin %s, logge dich bitte ein um spielen zu können:", GetName(playerid));
    SPD(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, D_WHITE"Einloggen", string, D_WHITE"Einloggen", D_WHITE"Abbrechen");
	return true;
}

/*
 *
 *  Zeigt den Registrieren-Dialog für den angegeben Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @params playerid    Die ID des Spielers
 *
 */
stock ShowRegisterDialog(playerid) {
	new string[256];
	format(string, sizeof(string), D_WHITE"Moin %s, bitte gebe ein sicheres Passwort ein um spielen zu können: (6-200 Zeichen)", GetName(playerid));
    SPD(playerid, D_REGISTER, DIALOG_STYLE_INPUT, D_WHITE"Registrieren", string, D_WHITE"Registrieren", D_WHITE"Abbrechen");
	return true;
}

/*
 *
 *	Dieses Callback wird aufgerufen, wenn ein Spieler auf irgendeine Weise auf ein mit ShowPlayerDialog erzeugtes Dialogfenster antwortet.
 *
 *  @params playerid	Die ID des Spielers
 *  @params dialogid	Die ID des Dialogs, die in ShowPlayerDialog angegeben wurde.
 *  @params response	1 wenn der linke Button gedrückt wurde, 0 für den Linken (Wenn nur ein Knopf aktiv ist, immer 1)
 *  @params listitem	Die ID der ausgewählten Zeile, wenn DIALOG_STYLE_LIST benutzt wird (beginnend bei 0)
 *  @params inputtext		Der Text, der eingegeben wurde, wenn DIALOG_STYLE_INPUT oder DIALOG_STYLE_PASSWORD benutzt wird.
 							Ebenso enthällt es den Text des ausgewählten Listitems, wenn DIALOG_STYLE_LIST genutzt wird.
 *  @return 0 - Erlaubt das Einbinden von Filterscripts, 1 - Verhindert das Einbinden von Filterscripts
 *
 */
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
	switch(dialogid) {
	    case D_LOGIN: {
	        if(!response) {
				// Auf 'Abbrechen' gedrückt
				SCM(playerid, COLOR_WHITE, "=> Ohne Account kannst du bei uns leider nicht spielen..");
				KickPlayer(playerid);
				return true;
			} else {
			    // Auf 'Einloggen' gedrückt
			    if(strlen(inputtext) < 6 || strlen(inputtext) > 200) {
				    // Passwort ist zu kurz oder zu lang (6-200)
				    SCM(playerid, COLOR_RED, "[FEHLER]: Passwort muss zwischen 6 und 200 Zeichen besitzen!");
				    ShowLoginDialog(playerid);
				    return true;
				}
				// Passwort ist nach Vorgaben
				new password[250];
				format(password, sizeof(password), "%s%s", inputtext, pInfo[playerid][pSalt]);
    			bcrypt_check(password, pInfo[playerid][pPassword], "OnPasswordChecked", "d", playerid);
			}
	    }
	    case D_REGISTER: {
	        if(!response) {
				// Auf 'Abbrechen' gedrückt
				SCM(playerid, COLOR_WHITE, "=> Ohne Account kannst du bei uns leider nicht spielen..");
				KickPlayer(playerid);
				return true;
			} else {
			    // Auf 'Registrieren' gedrückt
				if(strlen(inputtext) < 6 || strlen(inputtext) > 200) {
				    // Passwort ist zu kurz oder zu lang (6-200)
				    SCM(playerid, COLOR_RED, "[FEHLER]: Passwort muss zwischen 6 und 200 Zeichen besitzen!");
				    ShowRegisterDialog(playerid);
				    return true;
				}
				// Passwort ist nach Vorgaben
				
				// Generiere zufälligen Salt
				new salt[11], password[250];
				for(new i; i < 10; i++) {
	                salt[i] = random(79) + 47;
	            }
	            salt[10] = 0;
				format(pInfo[playerid][pSalt], sizeof(salt), salt);
				format(password, sizeof(password), "%s%s", inputtext, salt);
				bcrypt_hash(password, BCRYPT_COST, "OnPasswordHashed", "d", playerid);
				return true;
			}
	    }
	}
	return false;
}

/*
 *
 *  Prüft ob das Passwort mit dem eingegebenen übereinstimmt
 *
 *  @param  playerid    Die ID des Spielers
 *  @return 0 - Fehler, 1 - Erfolg
 *
 */
function OnPasswordChecked(playerid) {
	// Prüfen ob das Passwort übereinstimmt
	if(bcrypt_is_equal()) {
	    new query[256];
	    mysql_format(dbhandle, query, sizeof(query), "SELECT * FROM `users` WHERE `name` = '%e' AND `password` = '%e' AND `salt` = '%e' LIMIT 1",
			GetName(playerid), pInfo[playerid][pPassword], pInfo[playerid][pSalt]);
		mysql_tquery(dbhandle, query, "OnUserLogin", "d", playerid);
	} else {
		SCM(playerid, COLOR_RED, "[FEHLER]: Das Passwort ist nicht korrekt, versuche es erneut!");
		ShowLoginDialog(playerid);
	}
	return 1;
}

/*
 *
 *  Berechnet einen bcrypt-Hash für eine gegebene Zeichenkette
 *	unter Verwendung des angegebenen Arbeitsfaktors.
 *
 *  @param  playerid    Die ID des Spielers
 *  @return 0 - Fehler, 1 - Erfolg
 *
 */
function OnPasswordHashed(playerid) {
    new hash[BCRYPT_HASH_LENGTH];
    bcrypt_get_hash(hash);
    format(pInfo[playerid][pPassword], sizeof(hash), hash);
    CreatePlayerInventory(playerid);
	return true;
}

/*
 *
 *  Dieses Callback wird aufgerufen, wenn ein Spieler in der Datenbank erstellt wird
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *  @param  playerid    Die ID des Spielers
 *
 */
function OnUserCreate(playerid) {
	pInfo[playerid][pDBID] = cache_insert_id();
	SCM(playerid, COLOR_WHITE, "=> Erfolgreich registriert");
	pInfo[playerid][pLogged] = true;
	UnSpectate(playerid);
	
	// Zeige Verbindungs-Nachricht an
	new string[144];
	format(string, sizeof(string), "Spieler %s verbunden", GetName(playerid));
	SendClientMessageToAll(COLOR_GREY, string);
	
	ShowMiningFields(playerid);
	return true;
}

/*
 *
 *  Diese Funktion erstellt ein Spieler-Inventar als Storage
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @param  playerid    Die ID des Spielers
 *
 */
stock CreatePlayerInventory(playerid) {
	new query[128];
	mysql_format(dbhandle, query, sizeof(query), "INSERT INTO `storages` (`capacity`) VALUES ('10')");
	mysql_tquery(dbhandle, query, "OnPlayerInventoryCreated", "d", playerid);
	return true;
}

/*
 *
 *  Diese Funktion erstellt ein Fahrzeug-Inventar als Storage
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @param  vehID    Die ID des Fahrzeuges im Enum
 *
 */
stock CreateVehicleInventory(vehID) {
	new query[128];
	mysql_format(dbhandle, query, sizeof(query), "INSERT INTO `storages` (`capacity`) VALUES ('50')");
	mysql_tquery(dbhandle, query, "OnVehicleInventoryCreated", "d", vehID);
	return true;
}

/*
 *
 *  Dieses Callback wird aufgerufen, wenn ein Spieler-Inventar erstellt wird
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *  @param  playerid    Die ID des Spielers
 *
 */
function OnPlayerInventoryCreated(playerid) {
	pInfo[playerid][pStorage] = cache_insert_id();
	
	new query[256];
	mysql_format(dbhandle, query, sizeof(query), "INSERT INTO `users` (`password`, `salt`, `name`, `storage`) VALUES ('%e', '%e', '%e', '%d')",
		pInfo[playerid][pPassword], pInfo[playerid][pSalt], pInfo[playerid][pName], pInfo[playerid][pStorage]);
    mysql_tquery(dbhandle, query, "OnUserCreate", "d", playerid);

	return true;
}

/*
 *
 *  Dieses Callback wird aufgerufen, wenn ein Fahrzeug-Inventar erstellt wird
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *  @param  vehID    Die ID des Fahrzeuges im Enum
 *
 */
function OnVehicleInventoryCreated(vehID) {
	vInfo[vehID][vStorage] = cache_insert_id();

	new query[256];
	mysql_format(dbhandle, query, sizeof(query), "INSERT INTO `vehicles` (`model`, `owner`, `color1`, `color2`, `storage`) VALUES ('%d', '%d', '%d', '%d', '%d')",
		vInfo[vehID][vModel], vInfo[vehID][vOwner], vInfo[vehID][vColor1], vInfo[vehID][vColor2], vInfo[vehID][vStorage]);
	mysql_tquery(dbhandle, query);

	return true;
}


/*
 *
 *  Dieses Callback wird aufgerufen, wenn sich ein Spieler einloggt
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *  @param  playerid    Die ID des Spielers
 *
 */
function OnUserLogin(playerid) {

    SCM(playerid, COLOR_WHITE, "=> Erfolgreich eingeloggt");
	pInfo[playerid][pLogged] = true;
	UnSpectate(playerid);
	
	cache_get_value_name_int(0, "id", pInfo[playerid][pDBID]);
	cache_get_value_name_int(0, "cash", pInfo[playerid][pCash]);
	cache_get_value_name_int(0, "bank", pInfo[playerid][pBank]);
	cache_get_value_name_int(0, "skin", pInfo[playerid][pSkin]);
	cache_get_value_name_int(0, "storage", pInfo[playerid][pStorage]);
	
	cache_get_value_name_int(0, "weapon0", pInfo[playerid][pWeapon0]);
	cache_get_value_name_int(0, "ammo0", pInfo[playerid][pAmmo0]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon0], pInfo[playerid][pAmmo0]);
	
	cache_get_value_name_int(0, "weapon1", pInfo[playerid][pWeapon1]);
	cache_get_value_name_int(0, "ammo1", pInfo[playerid][pAmmo1]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon1], pInfo[playerid][pAmmo1]);
	
	cache_get_value_name_int(0, "weapon2", pInfo[playerid][pWeapon2]);
	cache_get_value_name_int(0, "ammo2", pInfo[playerid][pAmmo2]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon2], pInfo[playerid][pAmmo2]);
	
	cache_get_value_name_int(0, "weapon3", pInfo[playerid][pWeapon3]);
	cache_get_value_name_int(0, "ammo3", pInfo[playerid][pAmmo3]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon3], pInfo[playerid][pAmmo3]);
	
	cache_get_value_name_int(0, "weapon4", pInfo[playerid][pWeapon4]);
	cache_get_value_name_int(0, "ammo4", pInfo[playerid][pAmmo4]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon4], pInfo[playerid][pAmmo4]);
	
	cache_get_value_name_int(0, "weapon5", pInfo[playerid][pWeapon5]);
	cache_get_value_name_int(0, "ammo5", pInfo[playerid][pAmmo5]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon5], pInfo[playerid][pAmmo5]);
	
	cache_get_value_name_int(0, "weapon6", pInfo[playerid][pWeapon6]);
	cache_get_value_name_int(0, "ammo6", pInfo[playerid][pAmmo6]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon6], pInfo[playerid][pAmmo6]);
	
	cache_get_value_name_int(0, "weapon7", pInfo[playerid][pWeapon7]);
	cache_get_value_name_int(0, "ammo7", pInfo[playerid][pAmmo7]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon7], pInfo[playerid][pAmmo7]);
	
	cache_get_value_name_int(0, "weapon8", pInfo[playerid][pWeapon8]);
	cache_get_value_name_int(0, "ammo8", pInfo[playerid][pAmmo8]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon8], pInfo[playerid][pAmmo8]);
	
	cache_get_value_name_int(0, "weapon9", pInfo[playerid][pWeapon9]);
	cache_get_value_name_int(0, "ammo9", pInfo[playerid][pAmmo9]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon9], pInfo[playerid][pAmmo9]);
	
	cache_get_value_name_int(0, "weapon10", pInfo[playerid][pWeapon10]);
	cache_get_value_name_int(0, "ammo10", pInfo[playerid][pAmmo10]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon10], pInfo[playerid][pAmmo10]);
	
	cache_get_value_name_int(0, "weapon11", pInfo[playerid][pWeapon11]);
	cache_get_value_name_int(0, "ammo11", pInfo[playerid][pAmmo11]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon11], pInfo[playerid][pAmmo11]);
	
	cache_get_value_name_int(0, "weapon12", pInfo[playerid][pWeapon12]);
	cache_get_value_name_int(0, "ammo12", pInfo[playerid][pAmmo12]);
	GivePlayerWeapon(playerid, pInfo[playerid][pWeapon12], pInfo[playerid][pAmmo12]);
	
	SetPlayerSkin(playerid, pInfo[playerid][pSkin]);

    ShowMiningFields(playerid);

	ShowConnectMessage(playerid);
	return true;
}

/*
 *
 *  Diese Funktion sendet allen Spielern eine Verbindungs-Nachricht
 *	zum angegebenen Spieler
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *  @param  playerid    Die ID des Spielers
 *
 */
stock ShowConnectMessage(playerid) {
    // Zeige Verbindungs-Nachricht an
	new string[144];
	format(string, sizeof(string), "Spieler %s verbunden", GetName(playerid));
	SendClientMessageToAll(COLOR_GREY, string);
	return true;
}

/*
 *
 *  Wird aufgerufen, wenn ein Spieler versucht, über die Klassenauswahl zu spawnen,
 *	entweder durch Drücken der UMSCHALTTASTE oder durch Klicken auf die Schaltfläche "Spawn".
 *
 *  @param  playerid    Die ID des Spielers
 *  @param  classid     Die ID der derzeit angeschauten Klasse
 *  @return 0 - Hält den Spieler vom spawnen ab, 1 - ändert nichts
 *
 */
public OnPlayerRequestClass(playerid, classid) {
	return false;
}

/*
 *
 *  Wird aufgerufen, wenn ein Spieler versucht, über die Klassenauswahl zu spawnen,
 *	entweder durch Drücken der UMSCHALTTASTE oder durch Klicken auf die Schaltfläche "Spawn".
 *
 *  @param  playerid    Die ID des Spielers
 *  @return 0 - Hält den Spieler vom spawnen ab, 1 - ändert nichts
 *
 */
public OnPlayerRequestSpawn(playerid) {
	return false;
}

/*
 *
 *	Verbindung zur Datenbank
 *	mit den oben angegebenen Daten (MySQL Daten)
 *  Dieses Callback benutzt den Return-Wert nicht.
 *
 */
stock mysqlConnect() {
	// Verbindungsaufbau
	dbhandle = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE);
	
	// Überprüfe ob die Datenbankverbindung steht (0 = Erfolgreich, -1 = Fehler)
	new errno = mysql_errno();
	if(errno == 0) {
	    // Datenbankverbindung erfolgreich
	    
	    // Gebe den Erfolg mit der benötigten Zeit auf der Konsole aus
	    printf("=> Datenbankverbindung (ID: %d) erfolgreich in %dms herrgestellt!", _:dbhandle, GetTickCount() - startTime);
	} else {
	    // Fehler in Datenbankverbindung
	    
	    // Gebe den Fehler auf die Konsole aus
	    new error[100];
		mysql_error(error, sizeof(error), dbhandle);
		printf("[FEHLER] Datenbankverbindung fehlgeschlagen #%d '%s'", errno, error);
	}
	return true;
}

/*
 *
 *	Dieser Befehl schaltet nichteingabe von Parametern den Side-Chat aus/aus
 *  Wenn Parameter eingegeben werden, werden diese im Side-Chat ausgegeben
 *	Dieser Befehl benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  params 		Eingegebenen Parameter
 *
 */
CMD:side(playerid, params[]) {
	new message[140], string[144];
	if(sscanf(params, "s[100]", message)) {
	    // Keine Parameter angegeben, also Side-Chat aktivieren / deaktivieren
	    
	    // Schalte den Side-Chat des Spielers um
		new const bool:sideChat = pInfo[playerid][pSideChat];
	    pInfo[playerid][pSideChat] = !sideChat;
	    
	    // Sende Spieler Nachricht zur Information
	    new status[24];
	    if(pInfo[playerid][pSideChat]) status = D_RED"deaktiviert";
	    else status = D_GREEN"aktiviert";
		format(string, sizeof(string), "=> "D_SIDECHAT"Side-Chat %s", status);
		SCM(playerid, COLOR_WHITE, string);
	} else {
	    // Parameter angegeben, somit jene schreiben ohne Side-Chat umzustellen
	    if(strlen(message) >= 100) return SCM(playerid, COLOR_RED, "[FEHLER] "D_WHITE"Maximal 100 Zeichen erlaubt");
	    format(string, sizeof(string), "%s:"D_WHITE" \"%s\"", GetName(playerid), message);
		SendClientMessageToAll(COLOR_SIDECHAT, string);
	}
	return true;
}

/*
 *
 *	Dieser Befehl öffnet/schließt das Inventar
 *	Dieser Befehl benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  params 		Eingegebenen Parameter
 *
 */
CMD:inventory(playerid, params[]) {
	#pragma unused params
	if(pInfo[playerid][pInventoryOpend]) {
	    // Inventar schließen
	    HideInventoryTextDraws(playerid);
	} else {
	    // Inventar öffnen
	    ShowInventoryTextDraws(playerid);
	}
	return true;
}

/*
 *
 *	Dieser Befehl öffnet/schließt den Kofferraum des eigenen Fahrzeuges
 *	Dieser Befehl benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  params 		Eingegebenen Parameter
 *
 */
CMD:kofferraum(playerid, params[]) {
	#pragma unused params
	if(IsPlayerInAnyVehicle(playerid)) return SCM(playerid, COLOR_WHITE, "[Fehler] In einem Fahrzeug geht das nicht");
	new vehID = GetNearestVehicleFromPlayer(playerid);
	new vehicleIndex = GetVehicleEnumID(vehID);
    if(vehicleIndex == -1) return SCM(playerid, COLOR_WHITE, "[Fehler] Melde dich im Support");
    if(GetPlayerPositionNextToACar(playerid, vehID) != 4) return true;

    new string[100], status[50], engine, lights, alarm, doors, bonnet, boot, objective;
	GetVehicleParamsEx(vehID, engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(vehID, engine, lights, alarm, doors, bonnet, !boot, objective);
    vInfo[vehicleIndex][vBoot] = !vInfo[vehicleIndex][vBoot];

    if(vInfo[vehicleIndex][vBoot]) status = "~g~geoeffnet";
	else status = "~r~geschlossen";

    format(string, sizeof(string), "~w~Kofferraum %s", status);
    GameTextForPlayer(playerid, string, 2000, 3);
    
    if(pInfo[playerid][pTrunkOpend]) {
	    // Kofferraum schließen
	    HideTrunkTextDraws(playerid);
	} else {
	    // Kofferraum öffnen
	    ShowTrunkTextDraws(playerid);
	    SetTrunkTextDrawValues(playerid, vInfo[vehicleIndex][vStorage]);
	}
	return 1;
}

/*
 *
 *	Diese Funktion gibt die Vehicle-ID des nähsten Fahrzeuges zurück
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@return	Vehicle-ID des Fahrzeuges
 *
 */
stock GetNearestVehicleFromPlayer(playerid) {
	new Float:dist = 9999999, Float:pos[3], Float:newDist, vehicleID = INVALID_VEHICLE_ID;
	for(new i = 0; i < MAX_VEHICLES; i++) {
		if(!IsValidVehicle(i)) continue;
		GetVehiclePos(i, pos[0], pos[1], pos[2]);
		newDist = GetPlayerDistanceFromPoint(playerid, pos[0], pos[1], pos[2]);
		if(newDist < dist) {
			dist = newDist;
			vehicleID = i;
		}
	}
	return vehicleID;
}

/*
 *
 *	Diese Funktion gibt die Enum-ID des Fahrzeuges zurück
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param	vehicleid	Die Vehicle-ID des Fahrzeuges
 *	@return	Enum-ID des Fahrzeuges
 *
 */
stock GetVehicleEnumID(vehicleid) {
	for(new i = 0; i < sizeof(vInfo); i++) {
	    if(vInfo[i][vVehicleID] == vehicleid) return i;
	}
	return -1;
}

/*
 *
 *	Dieser Befehl zeigt den Inhalt eines Storage an (Develop Befehl)
 *	Dieser Befehl benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  params 		Eingegebenen Parameter
 *
 */
// TODO: Entfernen (Develop Befehl)
CMD:getstorage(playerid, params[]) {
	new storageID;
	if(sscanf(params, "d", storageID)) return SCM(playerid, COLOR_RED, "[FEHLER]"D_WHITE" Benutzung: /getstorage [Storage-ID]");
	OpenStorage(playerid, storageID);
	return true;
}

/*
 *
 *	Diese Funktion fragt ab, welche Items der Spieler im Inventar hat
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  storageid   Die Storage-ID
 *
 */
stock OpenStorage(playerid, storageid) {
    new query[512];
	mysql_format(dbhandle, query, sizeof(query), "SELECT `items`.`name`, `items`.`weight`, `storage_items`.`amount`, `storages`.`capacity` FROM\
	`items` LEFT JOIN `storage_items` ON `items`.`id` = `storage_items`.`item_id`\
	LEFT JOIN `storages` ON `storages`.`id` = `storage_items`.`storage_id` WHERE `storage_items`.`storage_id` = '%d'", storageid);
	mysql_tquery(dbhandle, query, "ShowPlayerStorage", "dd", playerid, storageid);
	return true;
}

/*
 *
 *	Diese Funktion zeigt das Storage-Inventar in einem Dialog an den Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  storageid   Die Storage-ID
 *
 */
function ShowPlayerStorage(playerid, storageid) {
 	new rows = cache_num_rows();
	//if(!rows) return SCM(playerid, COLOR_RED, "[FEHLER]"D_WHITE" Keine Items im Storage");
	new query[512], caption[128], maxCapacity, currentCapacity;

	// Dialog Header setzten
	format(query, sizeof(query), D_WHITE"Item\t"D_WHITE"Gewicht\t"D_WHITE"Anzahl\n");
	for(new i = 0; i < rows; i++) {
	
		// Dialog mit Werten füllen
	    new amount, weight, name[71];
	    cache_get_value_name_int(i, "amount", amount);
	    cache_get_value_name_int(i, "weight", weight);
	    cache_get_value_name(i, "name", name, sizeof(name));
	    format(query, sizeof(query), "%s%s\t%d\t%d\n", query, name, weight, amount);

	    currentCapacity += (weight * amount);
	}
	// Überschrift mit Kapazitäts-Anzeige setzten
	cache_get_value_name_int(0, "capacity", maxCapacity);
	format(caption, sizeof(caption), D_WHITE"Storage (%d / %d kg)", currentCapacity, maxCapacity);
	ShowPlayerDialog(playerid, D_SHOWSTORAGE, DIALOG_STYLE_TABLIST_HEADERS, caption, query, D_WHITE"Auswählen", D_WHITE"Schließen");
	return true;
}

/*
 *
 *	Dieser Befehl erstellt ein Fahrzeug (Develop Befehl)
 *	Dieser Befehl benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  params 		Eingegebenen Parameter
 *
 */
 // TODO: Entfernen (Develop Befehl)
CMD:v(playerid, params[]) {
	new modelID;
	if(sscanf(params, "d", modelID)) return SCM(playerid, COLOR_RED, "[FEHLER]"D_WHITE" Benutzung: /v [Model-ID]");
	if(modelID < 400 || modelID > 611) return SCM(playerid, COLOR_RED, "[FEHLER]"D_WHITE" Model-ID muss zwischen 400-611 liegen");
	CreatePlayerVehicle(playerid, modelID);
	return true;
}

/*
 *
 *	Diese Funktion gibt die Spielerposition zurück,
 *	wo sich der Spieler vom Fahrzeug aus befindet
 *  Geschrieben von https://breadfish.de/wcf/user/11258-iprototypei/
 *  Funktionsweise leicht abgeändert - Whice
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  carid		Die VehicleID des Fahrzeuges
 *  @return 1 - Rechts, 2 - Links, 3 - Vorne, 4 - Dahinter
 *
 */
stock GetPlayerPositionNextToACar(playerid, vehicleid) {
	new Float:Pos[7];
	GetVehiclePos(vehicleid, Pos[0], Pos[1], Pos[2]);
	GetVehicleZAngle(vehicleid, Pos[3]);
	GetPlayerPos(playerid, Pos[4], Pos[5], Pos[6]);
	if(!IsPlayerInRangeOfPoint(playerid, 5, Pos[0], Pos[1], Pos[2])) return 0;
	Pos[6] = ((Pos[4] - Pos[0]) * floatcos(Pos[3], degrees) + (Pos[5] - Pos[1]) * floatsin(Pos[3], degrees));
	Pos[3] = ((-(Pos[4] - Pos[0])) * floatsin(Pos[3], degrees)+(Pos[5] - Pos[1]) * floatcos(Pos[3], degrees));
	GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, Pos[0], Pos[1], Pos[2]);
	if(Pos[6] >= 0 && Pos[3] <= (Pos[1]/2) && Pos[3] >= (-Pos[1]/2)) return 1; 	// Rechts
	else if(Pos[6] <= 0 && Pos[3] <= Pos[1]/2 && Pos[3] >= -Pos[1]/2) return 2; // Links
	else if(Pos[3] >= 0 && Pos[6] <= Pos[0]/2 && Pos[6] >= -Pos[0]/2) return 3; // Vorne
	else if(Pos[3] <= 0 && Pos[6] <= Pos[0]/2 && Pos[6] >= -Pos[0]/2) return 4; // Dahinter
	return 0;
}

/*
 *
 *	Dieser Callback wird aufgerufen, wenn der Zustand einer beliebigen unterstützten
 *	Taste geändert wird (gedrückt/freigegeben).
 *	Richtungstasten lösen OnPlayerKeyStateChange (oben/unten/links/rechts) nicht aus.
 *	Dieser Befehl benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  newkeys		Eine Map (Bitmaske) der aktuell gehaltenen Tasten
 *  @param  oldkeys     Eine Map (Bitmaske) der Tasten, die vor der aktuellen Änderung gehalten wurden
 *
 */
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
	// Wenn es kein Spieler, sondern ein NPC ist gehe nicht weiter
	if(IsPlayerNPC(playerid)) return true;
	
	// Falls Taste 'Z' gedrückt wird => Öffne/Schließe Inventar
	if(PRESSED(KEY_YES)) {
	    cmd_inventory(playerid, "");
	    
 	// Falls Taste 'N' gedrückt wird => Baue ab, wenn auf Feld
	} else if(PRESSED(KEY_NO)) {
	    // Wenn Spieler in keiner Abbau-Area ist gehe nicht weiter
	    if(!IsPlayerInAnyDynamicArea(playerid)) return true;
	    
	    new areaId = pInfo[playerid][pArea];
	    
	    // Falls Spieler in für keine Area registiert ist gehe nicht weiter
	    if(!IsValidDynamicArea(fields[areaId][fieldAreaId])) return true;
	    
	    GivePlayerItem(playerid, fields[areaId][fieldItem], 1);
	}
	return true;
}

/*
 *
 *	Diese Funktion gibt den angegeben Spieler das angegebene Item
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  itemid		Die ID des Items
 *	@param  amount		Die Anzahl der Items
 *
 */
stock GivePlayerItem(playerid, itemid, amount) {
	new query[256];
	mysql_format(dbhandle, query, sizeof(query), "SELECT `storage_items`.`amount`, `items`.`name` FROM `storage_items` LEFT JOIN `items` ON `storage_items`.`item_id` = `items`.`id`\
		WHERE `storage_items`.`storage_id` = '%d' AND `storage_items`.`item_id` = '%d'", pInfo[playerid][pStorage], itemid);
	mysql_tquery(dbhandle, query, "OnPlayerGiveItemCheckExists", "ddd", playerid, itemid, amount);
	return true;
}


/*
 *
 *	Diese Funktion überprüft, ob der angegebene Spieler das angegebene Item bereits im Inventar hat
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  itemid		Die ID des Items
 *	@param  amount		Die Anzahl der Items
 *
 */
function OnPlayerGiveItemCheckExists(playerid, itemid, amount) {
	new query[256];
	if(cache_num_rows()) {
	    mysql_format(dbhandle, query, sizeof(query), "UPDATE `storage_items` SET `amount` = `storage_items`.`amount` + '%d' WHERE  `item_id` = '%d'", amount, itemid);
 	} else {
 	    mysql_format(dbhandle, query, sizeof(query), "INSERT INTO `storage_items` (`item_id`, `storage_id`, `amount`) VALUES ('%d', '%d', '%d')", itemid, pInfo[playerid][pStorage], amount);
 	}
 	mysql_tquery(dbhandle, query);
 	
 	// Check Item Name
 	mysql_format(dbhandle, query, sizeof(query), "SELECT `name` FROM `items` WHERE `id` = '%d'", itemid);
 	mysql_tquery(dbhandle, query, "ShowPlayerGiveItemMessage", "dd", playerid, amount);
	return true;
}


/*
 *
 *	Diese Funktion sendet dem Spieler eine Nachricht, welches Item und wie viel er davon bekommen hat
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param	playerid	Die ID des Spielers
 *	@param  amount		Die Anzahl der Items
 *
 */
function ShowPlayerGiveItemMessage(playerid, amount) {
 	new name[71], query[128];
	cache_get_value_name(0, "name", name, sizeof(name));

	format(query, sizeof(query), "=> %d %s erhalten", amount, name);
 	SCM(playerid, COLOR_WHITE, query);
	return true;
}

/*
 *
 *	Dieses Callback wird aufgerufen, wenn ein Fehler bei der Verarbeitung einer MySQL-Abfrage auftritt.
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *	@param	errorid		ID des Fehlers
 *	@param  error 		Fehlermeldung
 *	@param  callback    Name des aufgerufenen Callbacks (leer wenn keins angegeben)
 *	@param  query       Die Ausgeführte Abfrage
 *	@param  handle      Die Datenbankverbindung
 *
 */
public OnQueryError(errorid, const error[], const callback[], const query[], MySQL:handle) {
	//1064 prüfen
	switch(errorid) {
		case CR_SERVER_GONE_ERROR: {
			printf("[FEHLER] Datenbankverbindung (ID: %d) unterbrochen: %s | Abfrage: %s | Callback: %s", _:handle, error, query, callback);
		}
		case ER_SYNTAX_ERROR: {
			printf("[FEHLER] Syntax Fehler in Datenbankabfrage (ID: %d): %s | Callback: %s | Error: %s", _:handle, query, callback, error);
		}
		default: {
            printf("[FEHLER] Datenbank-Anfrage (ID: %d) fehlgeschlagen: #%d %s | Callback: %s | Error: %s", _:handle, errorid, query, callback, error);
		}
	}
	return true;
}

/*
 *
 *	Diese Funktion ruft die einzelnen Funktionen zur Datenbanktabllenerstellung auf
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 */
stock CreateDatabaseTables() {
	CreateUserTable();
	CreateItemTable();
	CreateStoragesTable();
	CreateStorageItemsTable();
	CreateVehicleTable();

	CreateDefaultItems();
	
	return true;
}

/*
 *
 *	Diese Funktion erstellt die 'vehicles' Tabelle in der Datebank, falls sie noch nicht existiert
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 */
stock CreateVehicleTable() {
    new query[800];
    format(query, sizeof(query), "\
		`id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique vehicle id',\
		`model` INT(11) NOT NULL COMMENT 'vehicle model',\
		`owner` INT(11) NOT NULL COMMENT 'player id from table players',\
		`color1` INT(11) NOT NULL DEFAULT '1' COMMENT 'primary vehicle color',\
		`color2` INT(11) NOT NULL DEFAULT '1' COMMENT 'secondary vehicle color',\
		`storage` INT(11) NOT NULL COMMENT 'vehicle storage',");
	format(query, sizeof(query), "\
		%sPRIMARY KEY (`id`) USING BTREE,\
		INDEX `FK_vehicles_users` (`owner`) USING BTREE,\
		CONSTRAINT `FK_vehicles_storages` FOREIGN KEY (`storage`) REFERENCES `storages` (`id`) ON UPDATE CASCADE ON DELETE CASCADE,\
		CONSTRAINT `FK_vehicles_users` FOREIGN KEY (`owner`) REFERENCES `users` (`id`) ON UPDATE CASCADE ON DELETE CASCADE", query);
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `vehicles` (%s)\
	COMMENT='player vehicles'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;", query);

	//printf("vehicles table: %d", strlen(query)); // 

	mysql_tquery(dbhandle, query);
}


/*
 *
 *	Diese Funktion erstellt die 'users' Tabelle in der Datebank, falls sie noch nicht existiert
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 */
stock CreateDefaultItems() {
	new query[128];
	format(query, sizeof(query), "INSERT IGNORE INTO `items` (`name`, `weight`) VALUES ('Pfirsich', 1)");
	mysql_tquery(dbhandle, query);
	format(query, sizeof(query), "INSERT IGNORE INTO `items` (`name`, `weight`) VALUES ('Banane', 1)");
	mysql_tquery(dbhandle, query);
	format(query, sizeof(query), "INSERT IGNORE INTO `items` (`name`, `weight`) VALUES ('Eisenerz', '5')");
	mysql_tquery(dbhandle, query);
	return true;
}

/*
 *
 *	Diese Funktion erstellt die 'users' Tabelle in der Datebank, falls sie noch nicht existiert
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 */
stock CreateUserTable() {
    new query[2400];
    format(query, sizeof(query), "\
		`id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique user id',\
		`name` VARCHAR(20) NOT NULL COMMENT 'user name (unique)' COLLATE 'utf8mb4_general_ci',\
		`password` VARCHAR(61) NOT NULL COMMENT 'password (bcrypt encrypted)' COLLATE 'utf8mb4_general_ci',\
		`salt` VARCHAR(11) NOT NULL COMMENT 'unique salt to protect password' COLLATE 'utf8mb4_general_ci',\
		`cash` INT(11) NOT NULL DEFAULT '0' COMMENT 'money (cash)',");
	format(query, sizeof(query), "\
		%s`bank` INT(11) NOT NULL DEFAULT '0' COMMENT 'money (on bank-account)',\
		`skin` INT(11) NOT NULL DEFAULT '88' COMMENT 'skin model',\
		`weapon0` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 0',\
		`ammo0` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 0',\
  		`weapon1` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 1',\
  		`ammo1` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 1',", query);
    format(query, sizeof(query), "\
		%s`weapon2` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 2',\
  		`ammo2` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 2',\
  		`weapon3` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 3',\
		`ammo3` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 3',\
		`weapon4` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 4',\
		`ammo4` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 4',", query);
    format(query, sizeof(query), "\
		%s`weapon5` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 5',\
		`ammo5` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 5',\
		`weapon6` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 6',\
		`ammo6` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 6',\
		`weapon7` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 7',\
		`ammo7` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 7',", query);
    format(query, sizeof(query), "\
		%s`weapon8` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 8',\
		`ammo8` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 8',\
		`weapon9` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 9',\
		`ammo9` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 9',\
		`weapon10` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 10',\
		`ammo10` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 10',", query);
    format(query, sizeof(query), "\
		%s`weapon11` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 11',\
		`ammo11` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 11',\
		`weapon12` INT(11) NOT NULL DEFAULT '0' COMMENT 'weapon slot 12',\
		`ammo12` INT(11) NOT NULL DEFAULT '0' COMMENT 'ammo slot 12',\
		`storage` INT(11) NOT NULL DEFAULT '0' COMMENT 'inventory storage id',\
		PRIMARY KEY (`id`) USING BTREE", query);
		
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `users` (%s)\
	COMMENT='all user informations'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;", query);
	
	//printf("users table: %d", strlen(query)); // 2231
	
	mysql_tquery(dbhandle, query);
	
	return true;
}

/*
 *
 *	Diese Funktion erstellt die 'items' Tabelle in der Datebank, falls sie noch nicht existiert
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 */
stock CreateItemTable() {
    new query[400];
    format(query, sizeof(query), "\
		`id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique item id',\
		`name` VARCHAR(70) NOT NULL COMMENT 'item name' COLLATE 'utf8mb4_general_ci',\
		`weight` INT(11) NOT NULL DEFAULT '1' COMMENT 'item weight',\
		PRIMARY KEY (`id`) USING BTREE,\
		UNIQUE INDEX `name` (`name`) USING BTREE");
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `items` (%s)\
	COMMENT='all item informations'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;", query);
	
	//printf("item table: %d", strlen(query)); // 360
	
	mysql_tquery(dbhandle, query);

	return true;
}

/*
 *
 *	Diese Funktion erstellt die 'storages' Tabelle in der Datebank, falls sie noch nicht existiert
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 */
stock CreateStoragesTable() {
    new query[400];
    format(query, sizeof(query), "\
		`id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique item id',\
		`capacity` INT(11) NOT NULL COMMENT 'storage capacity',\
		PRIMARY KEY (`id`) USING BTREE");
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `storages` (%s)\
	COMMENT='all item informations'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;", query);
	
	//printf("storages table: %d", strlen(query)); // 363

	mysql_tquery(dbhandle, query);

	return true;
}

/*
 *
 *	Diese Funktion erstellt die 'storage_items' Tabelle in der Datebank, falls sie noch nicht existiert
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 */
stock CreateStorageItemsTable() {
    new query[600];
    format(query, sizeof(query), "\
		`item_id` INT(11) NOT NULL,\
		`storage_id` INT(11) NOT NULL,\
		`amount` INT(11) NOT NULL DEFAULT '1',\
		INDEX `FK__items` (`item_id`) USING BTREE,\
		INDEX `FK__storages` (`storage_id`) USING BTREE,\
		CONSTRAINT `FK__items` FOREIGN KEY (`item_id`) REFERENCES `altis-life`.`items` (`id`) ON UPDATE CASCADE ON DELETE CASCADE,\
		CONSTRAINT `FK__storages` FOREIGN KEY (`storage_id`) REFERENCES `altis-life`.`storages` (`id`) ON UPDATE CASCADE ON DELETE CASCADE");
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `storage_items` (%s)\
	COMMENT='all item informations'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;", query);

    //printf("storages items table: %d", strlen(query)); // 517

	mysql_tquery(dbhandle, query);

	return true;
}


/*
 *
 *	Dieses Callback wird aufgerufen, wenn ein Spieler auf ein auswählbares Player-TextDraw klickt.
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *	@param  playerid    Die ID des Spielers
 *  @param  playertextid    Die ID des ausgewählten Player-TextDraws.
 */
public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid) {
    // Text-Draw 'Schließen' im Inventory-Text-Draw wurde angeklickt
    if(playertextid == inventoryButtonClose[playerid]) {
        HideInventoryTextDraws(playerid);
    }
    // Text-Draw 'Update' im Inventory-Text-Draw wurde angeklickt
	else if(playertextid == inventoryButtonUpdate[playerid]) {
	    SavePlayer(playerid);
	    SCM(playerid, COLOR_WHITE, "=> Deine Daten wurden gespeichert");
	    HideInventoryTextDraws(playerid);
	}
	// // Text-Draw 'Schließen' im Kofferraum-Text-Draw wurde angeklickt
	else if(playertextid == trunkBtnClose[playerid]) {
	    HideTrunkTextDraws(playerid);
	}
	return true;
}

/*
 *
 *	Diese Funktion updated die Datenbank mit den aktuellen Werten des Spielers
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid    Die ID des Spielers
 */
stock SavePlayer(playerid) {
	new query[600];
	mysql_format(dbhandle, query, sizeof(query), "UPDATE `users` SET `bank` = '%d', `cash` = '%d', `skin` = '%d', `weapon0` = '%d', `ammo0` = '%d', `weapon1` = '%d', `ammo1` = '%d', `weapon2` = '%d', `ammo2` = '%d', `weapon3` = '%d',",
		pInfo[playerid][pBank], pInfo[playerid][pCash], pInfo[playerid][pSkin], pInfo[playerid][pWeapon0], pInfo[playerid][pAmmo0], pInfo[playerid][pWeapon1],
		pInfo[playerid][pAmmo1], pInfo[playerid][pWeapon2], pInfo[playerid][pAmmo2], pInfo[playerid][pWeapon3]);
		
	mysql_format(dbhandle, query, sizeof(query), "%s`ammo3` = '%d', `weapon4` = '%d', `ammo4` = '%d', `weapon5` = '%d', `ammo5` = '%d', `weapon6` = '%d', `ammo6` = '%d', `weapon7` = '%d', `ammo7` = '%d', `weapon8` = '%d',",
	     query, pInfo[playerid][pAmmo3], pInfo[playerid][pWeapon4], pInfo[playerid][pAmmo4], pInfo[playerid][pWeapon5], pInfo[playerid][pAmmo5], pInfo[playerid][pWeapon6],
		 pInfo[playerid][pAmmo6], pInfo[playerid][pWeapon7], pInfo[playerid][pAmmo7], pInfo[playerid][pWeapon8]);

	mysql_format(dbhandle, query, sizeof(query), "%s`ammo8` = '%d',`weapon9` = '%d',`ammo9` = '%d', `weapon10` = '%d', `ammo10` = '%d', `weapon11` = '%d', `ammo11` = '%d', `weapon12` = '%d', `ammo12` = '%d' WHERE `name` = '%e' AND `id` = '%d'",
		query, pInfo[playerid][pAmmo8], pInfo[playerid][pWeapon9], pInfo[playerid][pAmmo9], pInfo[playerid][pWeapon10], pInfo[playerid][pAmmo10], pInfo[playerid][pWeapon11], pInfo[playerid][pAmmo11],
		pInfo[playerid][pWeapon12], pInfo[playerid][pAmmo12], GetName(playerid), pInfo[playerid][pDBID]);
		
	mysql_tquery(dbhandle, query);
	return true;
}

/*
 *
 *	Diese Funktion wandelt eine eingehende Zahl
 *	in einen String mit ',' alle 3 Stellen um
 *	Geschrieben von Kaliber: https://breadfish.de/wcf/user/13893-kaliber/
 *
 *	@param  money   Umzuwandelnde Zahl
 *	@return Zahl als String mit ',' als Dezimal-Punkt
 */
stock formatMoney(money) {
	new str[24], i;
	valstr(str, money);
	i = (money > 0) ? strlen(str) - 3 : strlen(str) - 4;
	for(; i > 0; i -= 3) {
		strins(str, ",", (money > 0) ? i : i + 1, 24);
	}
	return str;
}

/*
 *
 *	Diese Funktion setzt die variablen Werte im Inventar-System
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
stock SetInventoryTextDrawValues(playerid) {
	// Seztzt den Konto Wert
	new string[300];
	format(string, sizeof(string), "$%s", formatMoney(pInfo[playerid][pBank]));
    PlayerTextDrawSetString(playerid, inventoryTextBankMoney[playerid], string);
    
    // Setzt das Bargeld
    format(string, sizeof(string), "$%s", formatMoney(pInfo[playerid][pCash]));
	PlayerTextDrawSetString(playerid, inventoryTextCashMoney[playerid], string);
	
	// Setzt das Gewicht
	mysql_format(dbhandle, string, sizeof(string), "SELECT `storages`.`capacity`, SUM(`items`.`weight` * `storage_items`.`amount`) AS 'weight' FROM `storages` LEFT JOIN `storage_items`\
		ON `storages`.`id` = `storage_items`.`storage_id` LEFT JOIN `items` ON `items`.`id` = `storage_items`.`item_id` WHERE `storages`.`id` = '%d'", pInfo[playerid][pStorage]);
	mysql_tquery(dbhandle, string, "SetInventoryWeights", "d", playerid);
	
	return true;
}

/*
 *
 *	Diese Funktion setzt die variablen Werte im Kofferraum-System
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 *  @param  storageid   Die ID des Fahrzeug-Storages
 *
 */
stock SetTrunkTextDrawValues(playerid, storageid) {

	new string[300];
	// Setzt das Gewicht
	mysql_format(dbhandle, string, sizeof(string), "SELECT `storages`.`capacity`, SUM(`items`.`weight` * `storage_items`.`amount`) AS 'weight' FROM `storages` LEFT JOIN `storage_items`\
		ON `storages`.`id` = `storage_items`.`storage_id` LEFT JOIN `items` ON `items`.`id` = `storage_items`.`item_id` WHERE `storages`.`id` = '%d'", storageid);
	mysql_tquery(dbhandle, string, "SetTrunkWeights", "d", playerid);

	return true;
}

/*
 *
 *	Diese Funktion setzt das Gewicht im Kofferraum-Textdraw
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
function SetTrunkWeights(playerid) {

    new string[128], maxCapacity, capacity;
	cache_get_value_name_int(0, "weight", capacity);
	cache_get_value_name_int(0, "capacity", maxCapacity);
	format(string, sizeof(string), "Weight: %d / %d kg", capacity, maxCapacity);
    PlayerTextDrawSetString(playerid, trunkTxtWeight[playerid], string);
	return true;
}

/*
 *
 *	Diese Funktion setzt das Gewicht im Inventar-Textdraw
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
function SetInventoryWeights(playerid) {

    new string[128], maxCapacity, capacity;
	cache_get_value_name_int(0, "weight", capacity);
	cache_get_value_name_int(0, "capacity", maxCapacity);
	format(string, sizeof(string), "Weight: %d / %d kg", capacity, maxCapacity);
    PlayerTextDrawSetString(playerid, inventoryTextWeight[playerid], string);
	return true;
}

/*
 *
 *	Diese Funktion zeigt die Inventar Text-Draws für den Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
stock ShowInventoryTextDraws(playerid) {
    PlayerTextDrawShow(playerid, inventoryBackgroundBox[playerid]);
	PlayerTextDrawShow(playerid, inventoryTitleBox[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonClose[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonSettings[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonGangmenu[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonKeys[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonSMS[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonUpdate[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonAdmin[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonGroups[playerid]);
	PlayerTextDrawShow(playerid, inventoryTextMenu[playerid]);
	PlayerTextDrawShow(playerid, inventoryTextWeight[playerid]);
	PlayerTextDrawShow(playerid, inventoryBoxMoney[playerid]);
	PlayerTextDrawShow(playerid, inventoryBoxLicenses[playerid]);
	PlayerTextDrawShow(playerid, inventoryBoxItems[playerid]);
	PlayerTextDrawShow(playerid, inventoryImageCash[playerid]);
	PlayerTextDrawShow(playerid, inventoryImageBank[playerid]);
	PlayerTextDrawShow(playerid, inventoryTextBankMoney[playerid]);
	PlayerTextDrawShow(playerid, inventoryTextCashMoney[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonGiveMoney[playerid]);
	PlayerTextDrawShow(playerid, inventoryTextGiveMoney[playerid]);
	PlayerTextDrawShow(playerid, inventoryTestListLicenses[playerid]);
	PlayerTextDrawShow(playerid, inventoryTextListItems[playerid]);
	PlayerTextDrawShow(playerid, inventoryTextItemAmount[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonItemUse[playerid]);
	PlayerTextDrawShow(playerid, inventoryButtonItemGive[playerid]);
	SelectTextDraw(playerid, COLOR_ORANGE);
	
	SetInventoryTextDrawValues(playerid);
	pInfo[playerid][pInventoryOpend] = true;
	return true;
}

/*
 *
 *	Diese Funktion zeigt die Kofferraum Text-Draws für den Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
stock ShowTrunkTextDraws(playerid) {
    PlayerTextDrawShow(playerid, trunkBoxBackground[playerid]);
	PlayerTextDrawShow(playerid, trunkBoxHeader[playerid]);
	PlayerTextDrawShow(playerid, trunkBtnClose[playerid]);
	PlayerTextDrawShow(playerid, trunkTxtWeight[playerid]);
	PlayerTextDrawShow(playerid, trunkBoxHeaderTrunk[playerid]);
	PlayerTextDrawShow(playerid, trunkBoxTrunkBackground[playerid]);
	PlayerTextDrawShow(playerid, trunkEditTxtTrunkAmount[playerid]);
	PlayerTextDrawShow(playerid, trunkBtnTake[playerid]);
	PlayerTextDrawShow(playerid, trunkBoxHeaderInv[playerid]);
	PlayerTextDrawShow(playerid, trunkBoxInvBackground[playerid]);
	PlayerTextDrawShow(playerid, trunkEditTxtInvAmount[playerid]);
	PlayerTextDrawShow(playerid, trunkBoxStore[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem1[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem2[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem3[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem4[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem5[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem6[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem7[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem8[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem9[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem10[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem11[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem12[playerid]);
	PlayerTextDrawShow(playerid, trunkTextItem13[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem1[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem2[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem3[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem4[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem5[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem6[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem7[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem8[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem9[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem10[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem11[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem12[playerid]);
	PlayerTextDrawShow(playerid, trunkTextInvItem13[playerid]);
	
	SelectTextDraw(playerid, COLOR_ORANGE);
	pInfo[playerid][pTrunkOpend] = true;
	return true;
}

/*
 *
 *	Diese Funktion versteckt die Kofferraum Text-Draws vor dem Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
stock HideTrunkTextDraws(playerid) {
    PlayerTextDrawHide(playerid, trunkBoxBackground[playerid]);
	PlayerTextDrawHide(playerid, trunkBoxHeader[playerid]);
	PlayerTextDrawHide(playerid, trunkBtnClose[playerid]);
	PlayerTextDrawHide(playerid, trunkTxtWeight[playerid]);
	PlayerTextDrawHide(playerid, trunkBoxHeaderTrunk[playerid]);
	PlayerTextDrawHide(playerid, trunkBoxTrunkBackground[playerid]);
	PlayerTextDrawHide(playerid, trunkEditTxtTrunkAmount[playerid]);
	PlayerTextDrawHide(playerid, trunkBtnTake[playerid]);
	PlayerTextDrawHide(playerid, trunkBoxHeaderInv[playerid]);
	PlayerTextDrawHide(playerid, trunkBoxInvBackground[playerid]);
	PlayerTextDrawHide(playerid, trunkEditTxtInvAmount[playerid]);
	PlayerTextDrawHide(playerid, trunkBoxStore[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem1[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem2[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem3[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem4[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem5[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem6[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem7[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem8[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem9[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem10[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem11[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem12[playerid]);
	PlayerTextDrawHide(playerid, trunkTextItem13[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem1[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem2[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem3[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem4[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem5[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem6[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem7[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem8[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem9[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem10[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem11[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem12[playerid]);
	PlayerTextDrawHide(playerid, trunkTextInvItem13[playerid]);
	
	CancelSelectTextDraw(playerid);
	pInfo[playerid][pTrunkOpend] = false;
	return true;
}

/*
 *
 *	Diese Funktion versteckt die Inventar Text-Draws vor dem Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
stock HideInventoryTextDraws(playerid) {
    PlayerTextDrawHide(playerid, inventoryBackgroundBox[playerid]);
	PlayerTextDrawHide(playerid, inventoryTitleBox[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonClose[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonSettings[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonGangmenu[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonKeys[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonSMS[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonUpdate[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonAdmin[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonGroups[playerid]);
	PlayerTextDrawHide(playerid, inventoryTextMenu[playerid]);
	PlayerTextDrawHide(playerid, inventoryTextWeight[playerid]);
	PlayerTextDrawHide(playerid, inventoryBoxMoney[playerid]);
	PlayerTextDrawHide(playerid, inventoryBoxLicenses[playerid]);
	PlayerTextDrawHide(playerid, inventoryBoxItems[playerid]);
	PlayerTextDrawHide(playerid, inventoryImageCash[playerid]);
	PlayerTextDrawHide(playerid, inventoryImageBank[playerid]);
	PlayerTextDrawHide(playerid, inventoryTextBankMoney[playerid]);
	PlayerTextDrawHide(playerid, inventoryTextCashMoney[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonGiveMoney[playerid]);
	PlayerTextDrawHide(playerid, inventoryTextGiveMoney[playerid]);
	PlayerTextDrawHide(playerid, inventoryTestListLicenses[playerid]);
	PlayerTextDrawHide(playerid, inventoryTextListItems[playerid]);
	PlayerTextDrawHide(playerid, inventoryTextItemAmount[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonItemUse[playerid]);
	PlayerTextDrawHide(playerid, inventoryButtonItemGive[playerid]);
	CancelSelectTextDraw(playerid);
	pInfo[playerid][pInventoryOpend] = false;
	return true;
}

/*
 *
 *	Diese Funktion lädt die Trunk Text-Draws für den angegeben Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
stock LoadTrunkTextDraws(playerid) {
	trunkBoxBackground[playerid] = CreatePlayerTextDraw(playerid, 324.000000, 110.000000, "_");
	PlayerTextDrawFont(playerid, trunkBoxBackground[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkBoxBackground[playerid], 0.725000, 27.500003);
	PlayerTextDrawTextSize(playerid, trunkBoxBackground[playerid], 300.500000, 343.500000);
	PlayerTextDrawSetOutline(playerid, trunkBoxBackground[playerid], 1);
	PlayerTextDrawSetShadow(playerid, trunkBoxBackground[playerid], 0);
	PlayerTextDrawAlignment(playerid, trunkBoxBackground[playerid], 2);
	PlayerTextDrawColor(playerid, trunkBoxBackground[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBoxBackground[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkBoxBackground[playerid], 135);
	PlayerTextDrawUseBox(playerid, trunkBoxBackground[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBoxBackground[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBoxBackground[playerid], 0);

	trunkBoxHeader[playerid] = CreatePlayerTextDraw(playerid, 152.000000, 92.000000, "Kofferraum - Infernus");
	PlayerTextDrawFont(playerid, trunkBoxHeader[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkBoxHeader[playerid], 0.224996, 1.499999);
	PlayerTextDrawTextSize(playerid, trunkBoxHeader[playerid], 495.500000, 199.000000);
	PlayerTextDrawSetOutline(playerid, trunkBoxHeader[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkBoxHeader[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkBoxHeader[playerid], 1);
	PlayerTextDrawColor(playerid, trunkBoxHeader[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBoxHeader[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkBoxHeader[playerid], -8388408);
	PlayerTextDrawUseBox(playerid, trunkBoxHeader[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBoxHeader[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBoxHeader[playerid], 0);

	trunkBtnClose[playerid] = CreatePlayerTextDraw(playerid, 152.000000, 362.000000, "Schliessen");
	PlayerTextDrawFont(playerid, trunkBtnClose[playerid], 2);
	PlayerTextDrawLetterSize(playerid, trunkBtnClose[playerid], 0.229166, 1.600000);
	PlayerTextDrawTextSize(playerid, trunkBtnClose[playerid], 218.500000, 13.500000);
	PlayerTextDrawSetOutline(playerid, trunkBtnClose[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkBtnClose[playerid], 0);
	PlayerTextDrawAlignment(playerid, trunkBtnClose[playerid], 1);
	PlayerTextDrawColor(playerid, trunkBtnClose[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBtnClose[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkBtnClose[playerid], 135);
	PlayerTextDrawUseBox(playerid, trunkBtnClose[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBtnClose[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBtnClose[playerid], 1);

	trunkTxtWeight[playerid] = CreatePlayerTextDraw(playerid, 493.000000, 92.000000, "Weight: 198 / 200 kg");
	PlayerTextDrawFont(playerid, trunkTxtWeight[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTxtWeight[playerid], 0.233333, 1.500000);
	PlayerTextDrawTextSize(playerid, trunkTxtWeight[playerid], 400.000000, 17.000000);
	PlayerTextDrawSetOutline(playerid, trunkTxtWeight[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTxtWeight[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTxtWeight[playerid], 3);
	PlayerTextDrawColor(playerid, trunkTxtWeight[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTxtWeight[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTxtWeight[playerid], 50);
	PlayerTextDrawUseBox(playerid, trunkTxtWeight[playerid], 0);
	PlayerTextDrawSetProportional(playerid, trunkTxtWeight[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTxtWeight[playerid], 0);

	trunkBoxHeaderTrunk[playerid] = CreatePlayerTextDraw(playerid, 155.000000, 114.000000, "Kofferraum");
	PlayerTextDrawFont(playerid, trunkBoxHeaderTrunk[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkBoxHeaderTrunk[playerid], 0.224996, 1.499999);
	PlayerTextDrawTextSize(playerid, trunkBoxHeaderTrunk[playerid], 287.000000, 199.000000);
	PlayerTextDrawSetOutline(playerid, trunkBoxHeaderTrunk[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkBoxHeaderTrunk[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkBoxHeaderTrunk[playerid], 1);
	PlayerTextDrawColor(playerid, trunkBoxHeaderTrunk[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBoxHeaderTrunk[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkBoxHeaderTrunk[playerid], -8388408);
	PlayerTextDrawUseBox(playerid, trunkBoxHeaderTrunk[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBoxHeaderTrunk[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBoxHeaderTrunk[playerid], 0);

	trunkBoxTrunkBackground[playerid] = CreatePlayerTextDraw(playerid, 221.000000, 130.000000, "_");
	PlayerTextDrawFont(playerid, trunkBoxTrunkBackground[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkBoxTrunkBackground[playerid], 0.633333, 20.200025);
	PlayerTextDrawTextSize(playerid, trunkBoxTrunkBackground[playerid], 299.500000, 131.500000);
	PlayerTextDrawSetOutline(playerid, trunkBoxTrunkBackground[playerid], 1);
	PlayerTextDrawSetShadow(playerid, trunkBoxTrunkBackground[playerid], 0);
	PlayerTextDrawAlignment(playerid, trunkBoxTrunkBackground[playerid], 2);
	PlayerTextDrawColor(playerid, trunkBoxTrunkBackground[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBoxTrunkBackground[playerid], -741092353);
	PlayerTextDrawBoxColor(playerid, trunkBoxTrunkBackground[playerid], 1296911686);
	PlayerTextDrawUseBox(playerid, trunkBoxTrunkBackground[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBoxTrunkBackground[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBoxTrunkBackground[playerid], 0);

	trunkEditTxtTrunkAmount[playerid] = CreatePlayerTextDraw(playerid, 155.000000, 318.000000, "1");
	PlayerTextDrawFont(playerid, trunkEditTxtTrunkAmount[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkEditTxtTrunkAmount[playerid], 0.224996, 1.499999);
	PlayerTextDrawTextSize(playerid, trunkEditTxtTrunkAmount[playerid], 287.000000, 13.500000);
	PlayerTextDrawSetOutline(playerid, trunkEditTxtTrunkAmount[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkEditTxtTrunkAmount[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkEditTxtTrunkAmount[playerid], 1);
	PlayerTextDrawColor(playerid, trunkEditTxtTrunkAmount[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkEditTxtTrunkAmount[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkEditTxtTrunkAmount[playerid], 200);
	PlayerTextDrawUseBox(playerid, trunkEditTxtTrunkAmount[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkEditTxtTrunkAmount[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkEditTxtTrunkAmount[playerid], 1);

	trunkBtnTake[playerid] = CreatePlayerTextDraw(playerid, 189.000000, 339.000000, " NEHMEN");
	PlayerTextDrawFont(playerid, trunkBtnTake[playerid], 2);
	PlayerTextDrawLetterSize(playerid, trunkBtnTake[playerid], 0.229166, 1.600000);
	PlayerTextDrawTextSize(playerid, trunkBtnTake[playerid], 250.000000, 13.500000);
	PlayerTextDrawSetOutline(playerid, trunkBtnTake[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkBtnTake[playerid], 0);
	PlayerTextDrawAlignment(playerid, trunkBtnTake[playerid], 1);
	PlayerTextDrawColor(playerid, trunkBtnTake[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBtnTake[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkBtnTake[playerid], -8388473);
	PlayerTextDrawUseBox(playerid, trunkBtnTake[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBtnTake[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBtnTake[playerid], 1);

	trunkBoxHeaderInv[playerid] = CreatePlayerTextDraw(playerid, 361.000000, 114.000000, "Spielerinventar");
	PlayerTextDrawFont(playerid, trunkBoxHeaderInv[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkBoxHeaderInv[playerid], 0.224996, 1.499999);
	PlayerTextDrawTextSize(playerid, trunkBoxHeaderInv[playerid], 493.000000, 199.000000);
	PlayerTextDrawSetOutline(playerid, trunkBoxHeaderInv[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkBoxHeaderInv[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkBoxHeaderInv[playerid], 1);
	PlayerTextDrawColor(playerid, trunkBoxHeaderInv[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBoxHeaderInv[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkBoxHeaderInv[playerid], -8388408);
	PlayerTextDrawUseBox(playerid, trunkBoxHeaderInv[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBoxHeaderInv[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBoxHeaderInv[playerid], 0);

	trunkBoxInvBackground[playerid] = CreatePlayerTextDraw(playerid, 427.000000, 130.000000, "_");
	PlayerTextDrawFont(playerid, trunkBoxInvBackground[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkBoxInvBackground[playerid], 0.633333, 20.250024);
	PlayerTextDrawTextSize(playerid, trunkBoxInvBackground[playerid], 298.500000, 132.000000);
	PlayerTextDrawSetOutline(playerid, trunkBoxInvBackground[playerid], 1);
	PlayerTextDrawSetShadow(playerid, trunkBoxInvBackground[playerid], 0);
	PlayerTextDrawAlignment(playerid, trunkBoxInvBackground[playerid], 2);
	PlayerTextDrawColor(playerid, trunkBoxInvBackground[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBoxInvBackground[playerid], -741092353);
	PlayerTextDrawBoxColor(playerid, trunkBoxInvBackground[playerid], 1296911686);
	PlayerTextDrawUseBox(playerid, trunkBoxInvBackground[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBoxInvBackground[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBoxInvBackground[playerid], 0);

	trunkEditTxtInvAmount[playerid] = CreatePlayerTextDraw(playerid, 361.000000, 318.000000, "1");
	PlayerTextDrawFont(playerid, trunkEditTxtInvAmount[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkEditTxtInvAmount[playerid], 0.224996, 1.499999);
	PlayerTextDrawTextSize(playerid, trunkEditTxtInvAmount[playerid], 493.000000, 13.500000);
	PlayerTextDrawSetOutline(playerid, trunkEditTxtInvAmount[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkEditTxtInvAmount[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkEditTxtInvAmount[playerid], 1);
	PlayerTextDrawColor(playerid, trunkEditTxtInvAmount[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkEditTxtInvAmount[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkEditTxtInvAmount[playerid], 200);
	PlayerTextDrawUseBox(playerid, trunkEditTxtInvAmount[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkEditTxtInvAmount[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkEditTxtInvAmount[playerid], 1);

	trunkBoxStore[playerid] = CreatePlayerTextDraw(playerid, 403.000000, 339.000000, " Lagern");
	PlayerTextDrawFont(playerid, trunkBoxStore[playerid], 2);
	PlayerTextDrawLetterSize(playerid, trunkBoxStore[playerid], 0.229166, 1.600000);
	PlayerTextDrawTextSize(playerid, trunkBoxStore[playerid], 464.500000, 13.500000);
	PlayerTextDrawSetOutline(playerid, trunkBoxStore[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkBoxStore[playerid], 0);
	PlayerTextDrawAlignment(playerid, trunkBoxStore[playerid], 1);
	PlayerTextDrawColor(playerid, trunkBoxStore[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkBoxStore[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkBoxStore[playerid], -8388473);
	PlayerTextDrawUseBox(playerid, trunkBoxStore[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkBoxStore[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkBoxStore[playerid], 1);

	trunkTextItem1[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 131.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem1[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem1[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem1[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem1[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem1[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem1[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem1[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem1[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem1[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem1[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem1[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem1[playerid], 1);

	trunkTextItem2[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 145.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem2[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem2[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem2[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem2[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem2[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem2[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem2[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem2[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem2[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem2[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem2[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem2[playerid], 1);

	trunkTextItem3[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 159.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem3[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem3[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem3[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem3[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem3[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem3[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem3[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem3[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem3[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem3[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem3[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem3[playerid], 1);

	trunkTextItem4[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 173.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem4[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem4[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem4[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem4[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem4[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem4[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem4[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem4[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem4[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem4[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem4[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem4[playerid], 1);

	trunkTextItem5[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 187.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem5[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem5[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem5[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem5[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem5[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem5[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem5[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem5[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem5[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem5[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem5[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem5[playerid], 1);

	trunkTextItem6[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 201.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem6[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem6[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem6[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem6[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem6[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem6[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem6[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem6[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem6[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem6[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem6[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem6[playerid], 1);

	trunkTextItem7[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 215.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem7[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem7[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem7[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem7[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem7[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem7[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem7[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem7[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem7[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem7[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem7[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem7[playerid], 1);

	trunkTextItem8[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 229.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem8[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem8[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem8[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem8[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem8[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem8[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem8[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem8[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem8[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem8[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem8[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem8[playerid], 1);

	trunkTextItem9[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 243.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem9[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem9[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem9[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem9[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem9[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem9[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem9[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem9[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem9[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem9[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem9[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem9[playerid], 1);

	trunkTextItem10[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 257.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem10[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem10[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem10[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem10[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem10[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem10[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem10[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem10[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem10[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem10[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem10[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem10[playerid], 1);

	trunkTextItem11[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 271.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem11[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem11[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem11[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem11[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem11[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem11[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem11[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem11[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem11[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem11[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem11[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem11[playerid], 1);

	trunkTextItem12[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 285.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem12[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem12[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem12[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem12[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem12[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem12[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem12[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem12[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem12[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem12[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem12[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem12[playerid], 1);

	trunkTextItem13[playerid] = CreatePlayerTextDraw(playerid, 156.000000, 299.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextItem13[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextItem13[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextItem13[playerid], 285.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextItem13[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextItem13[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextItem13[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextItem13[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextItem13[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextItem13[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextItem13[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextItem13[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextItem13[playerid], 1);

	trunkTextInvItem1[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 131.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem1[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem1[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem1[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem1[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem1[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem1[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem1[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem1[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem1[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem1[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem1[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem1[playerid], 1);

	trunkTextInvItem2[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 145.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem2[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem2[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem2[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem2[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem2[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem2[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem2[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem2[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem2[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem2[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem2[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem2[playerid], 1);

	trunkTextInvItem3[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 159.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem3[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem3[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem3[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem3[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem3[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem3[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem3[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem3[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem3[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem3[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem3[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem3[playerid], 1);

	trunkTextInvItem4[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 173.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem4[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem4[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem4[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem4[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem4[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem4[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem4[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem4[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem4[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem4[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem4[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem4[playerid], 1);

	trunkTextInvItem5[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 187.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem5[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem5[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem5[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem5[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem5[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem5[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem5[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem5[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem5[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem5[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem5[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem5[playerid], 1);

	trunkTextInvItem6[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 201.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem6[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem6[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem6[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem6[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem6[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem6[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem6[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem6[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem6[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem6[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem6[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem6[playerid], 1);

	trunkTextInvItem7[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 215.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem7[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem7[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem7[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem7[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem7[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem7[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem7[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem7[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem7[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem7[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem7[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem7[playerid], 1);

	trunkTextInvItem8[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 229.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem8[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem8[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem8[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem8[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem8[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem8[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem8[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem8[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem8[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem8[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem8[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem8[playerid], 1);

	trunkTextInvItem9[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 243.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem9[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem9[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem9[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem9[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem9[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem9[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem9[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem9[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem9[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem9[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem9[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem9[playerid], 1);

	trunkTextInvItem10[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 257.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem10[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem10[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem10[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem10[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem10[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem10[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem10[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem10[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem10[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem10[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem10[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem10[playerid], 1);

	trunkTextInvItem11[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 271.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem11[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem11[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem11[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem11[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem11[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem11[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem11[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem11[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem11[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem11[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem11[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem11[playerid], 1);

	trunkTextInvItem12[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 285.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem12[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem12[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem12[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem12[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem12[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem12[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem12[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem12[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem12[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem12[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem12[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem12[playerid], 1);

	trunkTextInvItem13[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 299.000000, "[33] - SchildkrÃ¶ten Fleisch");
	PlayerTextDrawFont(playerid, trunkTextInvItem13[playerid], 1);
	PlayerTextDrawLetterSize(playerid, trunkTextInvItem13[playerid], 0.212500, 1.250000);
	PlayerTextDrawTextSize(playerid, trunkTextInvItem13[playerid], 492.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, trunkTextInvItem13[playerid], 0);
	PlayerTextDrawSetShadow(playerid, trunkTextInvItem13[playerid], 1);
	PlayerTextDrawAlignment(playerid, trunkTextInvItem13[playerid], 1);
	PlayerTextDrawColor(playerid, trunkTextInvItem13[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, trunkTextInvItem13[playerid], 255);
	PlayerTextDrawBoxColor(playerid, trunkTextInvItem13[playerid], -8388558);
	PlayerTextDrawUseBox(playerid, trunkTextInvItem13[playerid], 1);
	PlayerTextDrawSetProportional(playerid, trunkTextInvItem13[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, trunkTextInvItem13[playerid], 1);
	return true;
}

/*
 *
 *	Diese Funktion lädt die Inventar Text-Draws für den angegeben Spieler
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *	@param  playerid	Die ID des Spielers
 */
stock LoadInventoryTextDraws(playerid) {
    inventoryBackgroundBox[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 127.000000, "_");
	PlayerTextDrawFont(playerid, inventoryBackgroundBox[playerid], 1);
	PlayerTextDrawLetterSize(playerid, inventoryBackgroundBox[playerid], 0.600000, 16.650005);
	PlayerTextDrawTextSize(playerid, inventoryBackgroundBox[playerid], 306.000000, 306.000000);
	PlayerTextDrawSetOutline(playerid, inventoryBackgroundBox[playerid], 1);
	PlayerTextDrawSetShadow(playerid, inventoryBackgroundBox[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryBackgroundBox[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryBackgroundBox[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryBackgroundBox[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryBackgroundBox[playerid], 175);
	PlayerTextDrawUseBox(playerid, inventoryBackgroundBox[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryBackgroundBox[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryBackgroundBox[playerid], 0);

	inventoryTitleBox[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 112.000000, "_");
	PlayerTextDrawFont(playerid, inventoryTitleBox[playerid], 1);
	PlayerTextDrawLetterSize(playerid, inventoryTitleBox[playerid], 0.600000, 1.199995);
	PlayerTextDrawTextSize(playerid, inventoryTitleBox[playerid], 296.000000, 305.500000);
	PlayerTextDrawSetOutline(playerid, inventoryTitleBox[playerid], 1);
	PlayerTextDrawSetShadow(playerid, inventoryTitleBox[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryTitleBox[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryTitleBox[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTitleBox[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryTitleBox[playerid], -8388408);
	PlayerTextDrawUseBox(playerid, inventoryTitleBox[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryTitleBox[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTitleBox[playerid], 0);

	inventoryButtonClose[playerid] = CreatePlayerTextDraw(playerid, 196.000000, 281.000000, "SCHLIE\150;EN");
	PlayerTextDrawFont(playerid, inventoryButtonClose[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonClose[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonClose[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonClose[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonClose[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonClose[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonClose[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonClose[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonClose[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonClose[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonClose[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonClose[playerid], 1);

	inventoryButtonSettings[playerid] = CreatePlayerTextDraw(playerid, 258.000000, 281.000000, "EINSTELLUNG");
	PlayerTextDrawFont(playerid, inventoryButtonSettings[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonSettings[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonSettings[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonSettings[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonSettings[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonSettings[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonSettings[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonSettings[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonSettings[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonSettings[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonSettings[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonSettings[playerid], 1);

	inventoryButtonGangmenu[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 281.000000, "GANGMEN\149;");
	PlayerTextDrawFont(playerid, inventoryButtonGangmenu[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonGangmenu[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonGangmenu[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonGangmenu[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonGangmenu[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonGangmenu[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonGangmenu[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonGangmenu[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonGangmenu[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonGangmenu[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonGangmenu[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonGangmenu[playerid], 1);

	inventoryButtonKeys[playerid] = CreatePlayerTextDraw(playerid, 382.000000, 281.000000, "SCHL\149;SSEL");
	PlayerTextDrawFont(playerid, inventoryButtonKeys[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonKeys[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonKeys[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonKeys[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonKeys[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonKeys[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonKeys[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonKeys[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonKeys[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonKeys[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonKeys[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonKeys[playerid], 1);

	inventoryButtonSMS[playerid] = CreatePlayerTextDraw(playerid, 444.000000, 281.000000, "SMS");
	PlayerTextDrawFont(playerid, inventoryButtonSMS[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonSMS[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonSMS[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonSMS[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonSMS[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonSMS[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonSMS[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonSMS[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonSMS[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonSMS[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonSMS[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonSMS[playerid], 1);

	inventoryButtonUpdate[playerid] = CreatePlayerTextDraw(playerid, 196.000000, 297.000000, "UPDATE");
	PlayerTextDrawFont(playerid, inventoryButtonUpdate[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonUpdate[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonUpdate[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonUpdate[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonUpdate[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonUpdate[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonUpdate[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonUpdate[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonUpdate[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonUpdate[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonUpdate[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonUpdate[playerid], 1);

	inventoryButtonAdmin[playerid] = CreatePlayerTextDraw(playerid, 258.000000, 297.000000, "ADMINMEN\149;");
	PlayerTextDrawFont(playerid, inventoryButtonAdmin[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonAdmin[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonAdmin[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonAdmin[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonAdmin[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonAdmin[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonAdmin[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonAdmin[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonAdmin[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonAdmin[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonAdmin[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonAdmin[playerid], 1);

	inventoryButtonGroups[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 297.000000, "GRUPPEN");
	PlayerTextDrawFont(playerid, inventoryButtonGroups[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonGroups[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonGroups[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonGroups[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonGroups[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonGroups[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonGroups[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonGroups[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryButtonGroups[playerid], 200);
	PlayerTextDrawUseBox(playerid, inventoryButtonGroups[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonGroups[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonGroups[playerid], 1);

	inventoryTextMenu[playerid] = CreatePlayerTextDraw(playerid, 168.000000, 110.000000, "Spielermen\172;");
	PlayerTextDrawFont(playerid, inventoryTextMenu[playerid], 1);
	PlayerTextDrawLetterSize(playerid, inventoryTextMenu[playerid], 0.204162, 1.500000);
	PlayerTextDrawTextSize(playerid, inventoryTextMenu[playerid], -1.500000, 10.500000);
	PlayerTextDrawSetOutline(playerid, inventoryTextMenu[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTextMenu[playerid], 1);
	PlayerTextDrawAlignment(playerid, inventoryTextMenu[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryTextMenu[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTextMenu[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryTextMenu[playerid], 50);
	PlayerTextDrawUseBox(playerid, inventoryTextMenu[playerid], 0);
	PlayerTextDrawSetProportional(playerid, inventoryTextMenu[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTextMenu[playerid], 0);

	inventoryTextWeight[playerid] = CreatePlayerTextDraw(playerid, 470.000000, 111.000000, "Weight: 144 / 144");
	PlayerTextDrawFont(playerid, inventoryTextWeight[playerid], 1);
	PlayerTextDrawLetterSize(playerid, inventoryTextWeight[playerid], 0.208333, 1.200000);
	PlayerTextDrawTextSize(playerid, inventoryTextWeight[playerid], -4.000000, 5.500000);
	PlayerTextDrawSetOutline(playerid, inventoryTextWeight[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTextWeight[playerid], 1);
	PlayerTextDrawAlignment(playerid, inventoryTextWeight[playerid], 3);
	PlayerTextDrawColor(playerid, inventoryTextWeight[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTextWeight[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryTextWeight[playerid], 50);
	PlayerTextDrawUseBox(playerid, inventoryTextWeight[playerid], 0);
	PlayerTextDrawSetProportional(playerid, inventoryTextWeight[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTextWeight[playerid], 0);

	inventoryBoxMoney[playerid] = CreatePlayerTextDraw(playerid, 171.000000, 133.000000, "Guthaben");
	PlayerTextDrawFont(playerid, inventoryBoxMoney[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryBoxMoney[playerid], 0.200000, 1.299993);
	PlayerTextDrawTextSize(playerid, inventoryBoxMoney[playerid], 260.000000, 76.000000);
	PlayerTextDrawSetOutline(playerid, inventoryBoxMoney[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryBoxMoney[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryBoxMoney[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryBoxMoney[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryBoxMoney[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryBoxMoney[playerid], -8388508);
	PlayerTextDrawUseBox(playerid, inventoryBoxMoney[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryBoxMoney[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryBoxMoney[playerid], 0);

	inventoryBoxLicenses[playerid] = CreatePlayerTextDraw(playerid, 267.000000, 133.000000, "Lizenzen");
	PlayerTextDrawFont(playerid, inventoryBoxLicenses[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryBoxLicenses[playerid], 0.200000, 1.299993);
	PlayerTextDrawTextSize(playerid, inventoryBoxLicenses[playerid], 355.000000, 76.000000);
	PlayerTextDrawSetOutline(playerid, inventoryBoxLicenses[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryBoxLicenses[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryBoxLicenses[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryBoxLicenses[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryBoxLicenses[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryBoxLicenses[playerid], -8388508);
	PlayerTextDrawUseBox(playerid, inventoryBoxLicenses[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryBoxLicenses[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryBoxLicenses[playerid], 0);

	inventoryBoxItems[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 133.000000, "Gegenst\154;nde");
	PlayerTextDrawFont(playerid, inventoryBoxItems[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryBoxItems[playerid], 0.200000, 1.299993);
	PlayerTextDrawTextSize(playerid, inventoryBoxItems[playerid], 465.000000, 76.000000);
	PlayerTextDrawSetOutline(playerid, inventoryBoxItems[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryBoxItems[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryBoxItems[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryBoxItems[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryBoxItems[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryBoxItems[playerid], -8388508);
	PlayerTextDrawUseBox(playerid, inventoryBoxItems[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryBoxItems[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryBoxItems[playerid], 0);

	inventoryImageCash[playerid] = CreatePlayerTextDraw(playerid, 174.000000, 170.000000, "HUD:radar_cash");
	PlayerTextDrawFont(playerid, inventoryImageCash[playerid], 4);
	PlayerTextDrawLetterSize(playerid, inventoryImageCash[playerid], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, inventoryImageCash[playerid], 9.000000, 10.500000);
	PlayerTextDrawSetOutline(playerid, inventoryImageCash[playerid], 1);
	PlayerTextDrawSetShadow(playerid, inventoryImageCash[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryImageCash[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryImageCash[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryImageCash[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryImageCash[playerid], 50);
	PlayerTextDrawUseBox(playerid, inventoryImageCash[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryImageCash[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryImageCash[playerid], 0);

	inventoryImageBank[playerid] = CreatePlayerTextDraw(playerid, 174.000000, 153.000000, "HUD:radar_propertyg");
	PlayerTextDrawFont(playerid, inventoryImageBank[playerid], 4);
	PlayerTextDrawLetterSize(playerid, inventoryImageBank[playerid], 0.600000, 2.000000);
	PlayerTextDrawTextSize(playerid, inventoryImageBank[playerid], 9.000000, 10.500000);
	PlayerTextDrawSetOutline(playerid, inventoryImageBank[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryImageBank[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryImageBank[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryImageBank[playerid], 9109759);
	PlayerTextDrawBackgroundColor(playerid, inventoryImageBank[playerid], -16776961);
	PlayerTextDrawBoxColor(playerid, inventoryImageBank[playerid], -1962934222);
	PlayerTextDrawUseBox(playerid, inventoryImageBank[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryImageBank[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryImageBank[playerid], 0);

	inventoryTextBankMoney[playerid] = CreatePlayerTextDraw(playerid, 187.000000, 153.000000, "8,781,741$");
	PlayerTextDrawFont(playerid, inventoryTextBankMoney[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryTextBankMoney[playerid], 0.154164, 1.149999);
	PlayerTextDrawTextSize(playerid, inventoryTextBankMoney[playerid], 406.500000, 14.500000);
	PlayerTextDrawSetOutline(playerid, inventoryTextBankMoney[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTextBankMoney[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryTextBankMoney[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryTextBankMoney[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTextBankMoney[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryTextBankMoney[playerid], 50);
	PlayerTextDrawUseBox(playerid, inventoryTextBankMoney[playerid], 0);
	PlayerTextDrawSetProportional(playerid, inventoryTextBankMoney[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTextBankMoney[playerid], 0);

	inventoryTextCashMoney[playerid] = CreatePlayerTextDraw(playerid, 187.000000, 170.000000, "1,576$");
	PlayerTextDrawFont(playerid, inventoryTextCashMoney[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryTextCashMoney[playerid], 0.154164, 1.149999);
	PlayerTextDrawTextSize(playerid, inventoryTextCashMoney[playerid], 406.500000, 14.500000);
	PlayerTextDrawSetOutline(playerid, inventoryTextCashMoney[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTextCashMoney[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryTextCashMoney[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryTextCashMoney[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTextCashMoney[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryTextCashMoney[playerid], 50);
	PlayerTextDrawUseBox(playerid, inventoryTextCashMoney[playerid], 0);
	PlayerTextDrawSetProportional(playerid, inventoryTextCashMoney[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTextCashMoney[playerid], 0);

	inventoryButtonGiveMoney[playerid] = CreatePlayerTextDraw(playerid, 211.000000, 211.000000, "Geben");
	PlayerTextDrawFont(playerid, inventoryButtonGiveMoney[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonGiveMoney[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonGiveMoney[playerid], 10.000000, 58.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonGiveMoney[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonGiveMoney[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonGiveMoney[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonGiveMoney[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonGiveMoney[playerid], -8388353);
	PlayerTextDrawBoxColor(playerid, inventoryButtonGiveMoney[playerid], -8388508);
	PlayerTextDrawUseBox(playerid, inventoryButtonGiveMoney[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonGiveMoney[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonGiveMoney[playerid], 1);

	inventoryTextGiveMoney[playerid] = CreatePlayerTextDraw(playerid, 176.000000, 191.000000, "1000000");
	PlayerTextDrawFont(playerid, inventoryTextGiveMoney[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryTextGiveMoney[playerid], 0.141662, 1.200001);
	PlayerTextDrawTextSize(playerid, inventoryTextGiveMoney[playerid], 246.500000, 10.000000);
	PlayerTextDrawSetOutline(playerid, inventoryTextGiveMoney[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTextGiveMoney[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryTextGiveMoney[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryTextGiveMoney[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTextGiveMoney[playerid], -1);
	PlayerTextDrawBoxColor(playerid, inventoryTextGiveMoney[playerid], 135);
	PlayerTextDrawUseBox(playerid, inventoryTextGiveMoney[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryTextGiveMoney[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTextGiveMoney[playerid], 1);

	inventoryTestListLicenses[playerid] = CreatePlayerTextDraw(playerid, 270.000000, 147.000000, "Fuererschein Pilotenschein Marihuanaveredlung Diamantverarbeitung");
	PlayerTextDrawFont(playerid, inventoryTestListLicenses[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryTestListLicenses[playerid], 0.145833, 1.150007);
	PlayerTextDrawTextSize(playerid, inventoryTestListLicenses[playerid], 299.500000, 79.000000);
	PlayerTextDrawSetOutline(playerid, inventoryTestListLicenses[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTestListLicenses[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryTestListLicenses[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryTestListLicenses[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTestListLicenses[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryTestListLicenses[playerid], 135);
	PlayerTextDrawUseBox(playerid, inventoryTestListLicenses[playerid], 0);
	PlayerTextDrawSetProportional(playerid, inventoryTestListLicenses[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTestListLicenses[playerid], 0);

	inventoryTextListItems[playerid] = CreatePlayerTextDraw(playerid, 367.000000, 154.000000, "3x-Pausenbrot 3x-Bananenshake 10x-Nagelband 9x-Banane");
	PlayerTextDrawFont(playerid, inventoryTextListItems[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryTextListItems[playerid], 0.145833, 1.150007);
	PlayerTextDrawTextSize(playerid, inventoryTextListItems[playerid], 449.000000, 201.500000);
	PlayerTextDrawSetOutline(playerid, inventoryTextListItems[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTextListItems[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryTextListItems[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryTextListItems[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTextListItems[playerid], 255);
	PlayerTextDrawBoxColor(playerid, inventoryTextListItems[playerid], 1296911751);
	PlayerTextDrawUseBox(playerid, inventoryTextListItems[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryTextListItems[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTextListItems[playerid], 0);

	inventoryTextItemAmount[playerid] = CreatePlayerTextDraw(playerid, 369.000000, 247.000000, "1000000");
	PlayerTextDrawFont(playerid, inventoryTextItemAmount[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryTextItemAmount[playerid], 0.141662, 1.200001);
	PlayerTextDrawTextSize(playerid, inventoryTextItemAmount[playerid], 469.000000, 10.000000);
	PlayerTextDrawSetOutline(playerid, inventoryTextItemAmount[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryTextItemAmount[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryTextItemAmount[playerid], 1);
	PlayerTextDrawColor(playerid, inventoryTextItemAmount[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryTextItemAmount[playerid], -1);
	PlayerTextDrawBoxColor(playerid, inventoryTextItemAmount[playerid], 135);
	PlayerTextDrawUseBox(playerid, inventoryTextItemAmount[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryTextItemAmount[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryTextItemAmount[playerid], 1);

	inventoryButtonItemUse[playerid] = CreatePlayerTextDraw(playerid, 393.000000, 263.000000, "Benutzen");
	PlayerTextDrawFont(playerid, inventoryButtonItemUse[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonItemUse[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonItemUse[playerid], 10.000000, 47.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonItemUse[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonItemUse[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonItemUse[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonItemUse[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonItemUse[playerid], -8388353);
	PlayerTextDrawBoxColor(playerid, inventoryButtonItemUse[playerid], -8388508);
	PlayerTextDrawUseBox(playerid, inventoryButtonItemUse[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonItemUse[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonItemUse[playerid], 1);

	inventoryButtonItemGive[playerid] = CreatePlayerTextDraw(playerid, 445.000000, 263.000000, "Geben");
	PlayerTextDrawFont(playerid, inventoryButtonItemGive[playerid], 2);
	PlayerTextDrawLetterSize(playerid, inventoryButtonItemGive[playerid], 0.200000, 1.299980);
	PlayerTextDrawTextSize(playerid, inventoryButtonItemGive[playerid], 10.000000, 47.000000);
	PlayerTextDrawSetOutline(playerid, inventoryButtonItemGive[playerid], 0);
	PlayerTextDrawSetShadow(playerid, inventoryButtonItemGive[playerid], 0);
	PlayerTextDrawAlignment(playerid, inventoryButtonItemGive[playerid], 2);
	PlayerTextDrawColor(playerid, inventoryButtonItemGive[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, inventoryButtonItemGive[playerid], -8388353);
	PlayerTextDrawBoxColor(playerid, inventoryButtonItemGive[playerid], -8388508);
	PlayerTextDrawUseBox(playerid, inventoryButtonItemGive[playerid], 1);
	PlayerTextDrawSetProportional(playerid, inventoryButtonItemGive[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, inventoryButtonItemGive[playerid], 1);
	return true;
}
