#include <a_samp>
#include <a_mysql>
#include <bcrypt>
#include <zcmd>
#include <sscanf2>

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

// BCrypt Kosten
#define BCRYPT_COST 14

// Dialog Enum
enum {
	D_LOGIN = 1,
	D_REGISTER
}

enum E_PLAYER {
	pDBID,
	pName[MAX_PLAYER_NAME + 1],
	pSalt[11],
	bool:pLogged,
	pPassword[61],
	bool:pSideChat,
	bool:pInventoryOpend
};
new pInfo[MAX_PLAYERS][E_PLAYER];

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
    new hash[BCRYPT_HASH_LENGTH], query[256];
    bcrypt_get_hash(hash);
    mysql_format(dbhandle, query, sizeof(query), "INSERT INTO `users` (`password`, `salt`, `name`) VALUES ('%e', '%e', '%e')",
		hash, pInfo[playerid][pSalt], pInfo[playerid][pName]);
    mysql_tquery(dbhandle, query, "OnUserCreate", "d", playerid);
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
	TogglePlayerSpectating(playerid, false);
	
	// Zeige Verbindungs-Nachricht an
	new string[144];
	format(string, sizeof(string), "Spieler %s verbunden", GetName(playerid));
	SendClientMessageToAll(COLOR_GREY, string);
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
	
	cache_get_value_name_int(0, "id", pInfo[playerid][pDBID]);
	
	
	SCM(playerid, COLOR_WHITE, "=> Erfolgreich eingeloggt");
	pInfo[playerid][pLogged] = true;
	TogglePlayerSpectating(playerid, false);

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
	new const bool:inventoryOpend = pInfo[playerid][pInventoryOpend];
	pInfo[playerid][pInventoryOpend] = !inventoryOpend;
	if(inventoryOpend) {
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
	print("mysql_fehler");
	switch(errorid) {
		case CR_SERVER_GONE_ERROR: {
			printf("[FEHLER] Datenbankverbindung (ID: %d) unterbrochen: %s | Abfrage: %s | Callback: %s", _:handle, error, query, callback);
		}
		case ER_SYNTAX_ERROR: {
			printf("[FEHLER] Syntax Fehler in Datenbankabfrage (ID: %d): %s | Callback: %s | Error: %s", _:handle, query, callback, error);
		}
	}
	return true;
}

/*
 *
 *	Diese Funktion ruft die einzelnen Funktionen zur Datenbanktabllenerstellung auf
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 */
stock CreateDatabaseTables() {
	CreateUserTable();
	
	return true;
}

/*
 *
 *	Diese Funktion erstellt die 'users' Tablle in der Datebank, falls sie noch nicht existiert
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 */
stock CreateUserTable() {
    new query[500], query2[500];
    format(query2, sizeof(query2), "\
		`id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique user id',\
		`name` VARCHAR(20) NOT NULL COMMENT 'user name (unique)' COLLATE 'utf8mb4_general_ci',\
		`password` VARCHAR(61) NOT NULL COMMENT 'password (bcrypt encrypted)' COLLATE 'utf8mb4_general_ci',\
		`salt` VARCHAR(11) NOT NULL COMMENT 'unique salt to protect password' COLLATE 'utf8mb4_general_ci',\
		PRIMARY KEY (`id`) USING BTREE");
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `users` (%s)\
	COMMENT='all user informations'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;", query2);
	mysql_tquery(dbhandle, query);
	
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

	inventoryButtonClose[playerid] = CreatePlayerTextDraw(playerid, 196.000000, 281.000000, "SCHLIESSEN");
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

	inventoryButtonGangmenu[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 281.000000, "GANGMENU");
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

	inventoryButtonKeys[playerid] = CreatePlayerTextDraw(playerid, 382.000000, 281.000000, "SCHLUESSEL");
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

	inventoryButtonAdmin[playerid] = CreatePlayerTextDraw(playerid, 258.000000, 297.000000, "ADMINMENU");
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

	inventoryTextMenu[playerid] = CreatePlayerTextDraw(playerid, 168.000000, 110.000000, "Spielermenu");
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

	inventoryBoxItems[playerid] = CreatePlayerTextDraw(playerid, 362.000000, 133.000000, "Gegenstande");
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
