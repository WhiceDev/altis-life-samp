#include <a_samp>
#include <a_mysql>
#include <bcrypt>
#include <zcmd>

/* MySQL Daten */

#define MYSQL_HOSTNAME "localhost"
#define MYSQL_USERNAME "root"
#define MYSQL_PASSWORD ""
#define MYSQL_DATABASE "altis-life"

new MySQL:dbhandle;

// Legt die maximale L�nge des Namens fest
#undef MAX_PLAYER_NAME
#define MAX_PLAYER_NAME (20)


// Variable f�r Benchmark Tests (Zeitberechnung)
new startTime;


// Defines f�r einfachere Handhabung
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
	pPassword[61]
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

// Inline Farben definieren
#define D_WHITE "{FFFFFF}"
#define D_GREEN "{00FF00}"
#define D_RED "{FF0000}"

// Spieler Spawn Position
#define SPAWN_PLAYER_POS 1479.5073, -1673.8608, 14.0469, 179.8810



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
	// Schlie�en der Datenbankverbindung
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
	// Abfrage ob Spieler ein NPC ist, falls ja �berspringe das Callback
	if(IsPlayerNPC(playerid)) return true;
	
	// Reset Variables
	pInfo[playerid][pLogged] = false;
	
	// Auslesen des Spielernamens
	GetPlayerName(playerid, pInfo[playerid][pName], MAX_PLAYER_NAME);
	
	// Setze vorab Spawn Position
	SetSpawnInfo(playerid, NO_TEAM, 29, SPAWN_PLAYER_POS, 0, 0, 0, 0, 0, 0);
	
	Spectate(playerid);
	
	// Setze den Spieler an eine gute Position f�r den Login/Register Hintergrund
	PrepareSpawnPlayer(playerid);
	
	// Zeige Verbindungs-Nachricht an
	new string[144];
	format(string, sizeof(string), "Spieler %s verbindet", GetName(playerid));
	SendClientMessageToAll(COLOR_GREY, string);
	return true;
}


/*
 *
 *  Diese Funktion gibt den Spielernamen des angegeben Spielers zur�ck
 *
 *  @params playerid    Die ID des Spielers
 *  @return name        Spielername der zugeh�rigen playerid
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
 *  @return 0 - Der Spieler muss beim n�chsten Spawn eine neue Klasse w�hlen
 *
 */
public OnPlayerSpawn(playerid) {
	// Abfrage ob Spieler eingeloggt ist
	if(!pInfo[playerid][pLogged]) {
	
	    // Zeige Login/Register Hintergrund
	    SetPlayerCameraPos(10, 10 , 10, 10);
	    SetPlayerCameraLookAt(0, 0, 0, 6);
	    
		// �berpr�fe ob der Spieler in der Datenbank existiert
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
 *  Diese Funktion �berpr�ft ob der Spieler einen Account hat
 *  Leitet an Regis
 *  Dazu bekommt sie den cache der SQL Abfrage
 *
 *  @params playerid    Die ID des Spielers
 *  @return 0 - Verhintert das Einbinden von Filterscripts, 1 - Erlaubt das Einbinden von Filterscripts
 *
 */
function AccountCheck(playerid) {
	new query[256];
	// �berpr�fe ob Reihen im Cache sind
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
 *  Zeigt den Einloggen-Dialog f�r den angegeben Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @params playerid    Die ID des Spielers
 *
 */
stock ShowLoginDialog(playerid) {
	new string[256];
	format(string, sizeof(string), D_WHITE"Moin %s, logge dich bitte ein um spielen zu k�nnen:", GetName(playerid));
    SPD(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, D_WHITE"Einloggen", string, D_WHITE"Einloggen", D_WHITE"Abbrechen");
	return true;
}

/*
 *
 *  Zeigt den Registrieren-Dialog f�r den angegeben Spieler
 *	Diese Funktion benutzt den Return-Wert nicht.
 *
 *  @params playerid    Die ID des Spielers
 *
 */
stock ShowRegisterDialog(playerid) {
	new string[256];
	format(string, sizeof(string), D_WHITE"Moin %s, bitte gebe ein sicheres Passwort ein um spielen zu k�nnen: (6-200 Zeichen)", GetName(playerid));
    SPD(playerid, D_REGISTER, DIALOG_STYLE_INPUT, D_WHITE"Registrieren", string, D_WHITE"Registrieren", D_WHITE"Abbrechen");
	return true;
}

/*
 *
 *	Dieses Callback wird aufgerufen, wenn ein Spieler auf irgendeine Weise auf ein mit ShowPlayerDialog erzeugtes Dialogfenster antwortet.
 *
 *  @params playerid	Die ID des Spielers
 *  @params dialogid	Die ID des Dialogs, die in ShowPlayerDialog angegeben wurde.
 *  @params response	1 wenn der linke Button gedr�ckt wurde, 0 f�r den Linken (Wenn nur ein Knopf aktiv ist, immer 1)
 *  @params listitem	Die ID der ausgew�hlten Zeile, wenn DIALOG_STYLE_LIST benutzt wird (beginnend bei 0)
 *  @params inputtext		Der Text, der eingegeben wurde, wenn DIALOG_STYLE_INPUT oder DIALOG_STYLE_PASSWORD benutzt wird.
 							Ebenso enth�llt es den Text des ausgew�hlten Listitems, wenn DIALOG_STYLE_LIST genutzt wird.
 *  @return 0 - Erlaubt das Einbinden von Filterscripts, 1 - Verhindert das Einbinden von Filterscripts
 *
 */
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
	switch(dialogid) {
	    case D_LOGIN: {
	        if(!response) {
				// Auf 'Abbrechen' gedr�ckt
				SCM(playerid, COLOR_WHITE, "=> Ohne Account kannst du bei uns leider nicht spielen..");
				KickPlayer(playerid);
				return true;
			} else {
			    // Auf 'Einloggen' gedr�ckt
			    if(strlen(inputtext) < 6 || strlen(inputtext) > 200) {
				    // Passwort ist zu kurz oder zu lang (6-200)
				    SCM(playerid, COLOR_RED, "[FEHLER]: Passwort muss zwischen 6 und 200 Zeichen besitzen!");
				    ShowLoginDialog(playerid);
				    return true;
				}
				// Passwort ist nach Vorgaben
				new password[250];
				format(password, sizeof(password), "%s%s", inputtext, pInfo[playerid][pSalt]);
				bcrypt_check(password, inputtext, "OnPasswordChecked", "d", playerid);
			}
	    }
	    case D_REGISTER: {
	        if(!response) {
				// Auf 'Abbrechen' gedr�ckt
				SCM(playerid, COLOR_WHITE, "=> Ohne Account kannst du bei uns leider nicht spielen..");
				KickPlayer(playerid);
				return true;
			} else {
			    // Auf 'Registrieren' gedr�ckt
				if(strlen(inputtext) < 6 || strlen(inputtext) > 200) {
				    // Passwort ist zu kurz oder zu lang (6-200)
				    SCM(playerid, COLOR_RED, "[FEHLER]: Passwort muss zwischen 6 und 200 Zeichen besitzen!");
				    ShowRegisterDialog(playerid);
				    return true;
				}
				// Passwort ist nach Vorgaben
				
				// Generiere zuf�lligen Salt
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
 *  Pr�ft ob das Passwort mit dem eingegebenen �bereinstimmt
 *
 *  @param  playerid    Die ID des Spielers
 *  @return 0 - Fehler, 1 - Erfolg
 *
 */
function OnPasswordChecked(playerid) {
	// Pr�fen ob das Passwort �bereinstimmt
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
 *  Berechnet einen bcrypt-Hash f�r eine gegebene Zeichenkette
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
 *  Wird aufgerufen, wenn ein Spieler versucht, �ber die Klassenauswahl zu spawnen,
 *	entweder durch Dr�cken der UMSCHALTTASTE oder durch Klicken auf die Schaltfl�che "Spawn".
 *
 *  @param  playerid    Die ID des Spielers
 *  @param  classid     Die ID der derzeit angeschauten Klasse
 *  @return 0 - H�lt den Spieler vom spawnen ab, 1 - �ndert nichts
 *
 */
public OnPlayerRequestClass(playerid, classid) {
	return false;
}

/*
 *
 *  Wird aufgerufen, wenn ein Spieler versucht, �ber die Klassenauswahl zu spawnen,
 *	entweder durch Dr�cken der UMSCHALTTASTE oder durch Klicken auf die Schaltfl�che "Spawn".
 *
 *  @param  playerid    Die ID des Spielers
 *  @return 0 - H�lt den Spieler vom spawnen ab, 1 - �ndert nichts
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
	
	// �berpr�fe ob die Datenbankverbindung steht (0 = Erfolgreich, -1 = Fehler)
	new errno = mysql_errno();
	if(errno == 0) {
	    // Datenbankverbindung erfolgreich
	    
	    // Gebe den Erfolg mit der ben�tigten Zeit auf der Konsole aus
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
 *	Dieses Callback wird aufgerufen, wenn ein Fehler bei der Verarbeitung einer MySQL-Abfrage auftritt.
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 *	@param	errorid		ID des Fehlers
 *	@param  error 		Fehlermeldung
 *	@param  callback    Name des aufgerufenen Callbacks (leer wenn keins angegeben)
 *	@param  query       Die Ausgef�hrte Abfrage
 *	@param  handle      Die Datenbankverbindung
 *
 */
public OnQueryError(errorid, const error[], const callback[], const query[], MySQL:handle) {
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
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE `users` (%s)\
	COMMENT='all user informations'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;", query2);
	mysql_tquery(dbhandle, query);
	
	return true;
}
