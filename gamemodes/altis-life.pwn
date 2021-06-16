#include <a_samp>
#include <a_mysql>
#include <bcrypt>

/* MySQL Daten */

#define MYSQL_HOSTNAME "localhost"
#define MYSQL_USERNAME "root"
#define MYSQL_PASSWORD ""
#define MYSQL_DATABASE "altis-life"

new MySQL:dbhandle;

// Legt die maximale Länge des Namens fest
#undef MAX_PLAYER_NAME
#define MAX_PLAYER_NAME (20)


// Variable für Benchmark Tests (Zeitberechnung)
new startTime;


// Defines für einfachere Handhabung
#define function%0(%1) forward%0(%1); public%0(%1)
#define SPD ShowPlayerDialog
#define SCM SendClientMessage
#define KickPlayer(%0) SetTimerEx("KickThePlayer", 250, 0, "i", %0)

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
	pSalt[11]
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

// Inline Farben definieren
#define D_WHITE "{FFFFFF}"
#define D_GREEN "{00FF00}"
#define D_RED "{FF0000}"



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
	
	// Erstellen benötiger lokaler Variablen
	new query[256], playerName[MAX_PLAYER_NAME + 1];
	
	// Auslesen des Spielernamens
	GetPlayerName(playerid, playerName, sizeof(playerName));
	
	format(pInfo[playerid][pName], sizeof(playerName), playerName);
	
	// Überprüfe ob der Spieler in der Datenbank existiert
	mysql_format(dbhandle, query, sizeof(query), "SELECT `id` FROM `users` WHERE `name` = '%e' LIMIT 1", playerName);
	mysql_tquery(dbhandle, query, "AccountCheck", "d", playerid);
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
	new query[256];
	// Überprüfe ob Reihen im Cache sind
	if(cache_num_rows()) {
	    // Account mit dem Namen existiert bereits
		SPD(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, D_WHITE"Einloggen", D_WHITE"Moin, logge dich bitte ein um spielen zu können:", D_WHITE"Einloggen", D_WHITE"Abbrechen");
	} else {
	    // Kein Account mit dem Namen registriert
	    SPD(playerid, D_REGISTER, DIALOG_STYLE_INPUT, D_WHITE"Registrieren", D_WHITE"Moin, bitte gebe ein sicheres Passwort ein um spielen zu können: (6-200 Zeichen)", D_WHITE"Registrieren", D_WHITE"Abbrechen");
	}
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
				    SPD(playerid, D_REGISTER, DIALOG_STYLE_INPUT, D_WHITE"Registrieren", D_WHITE"Moin, bitte gebe ein sicheres Passwort ein um spielen zu können: (6-200 Zeichen)", D_WHITE"Registrieren", D_WHITE"Abbrechen");
				    return true;
				}
				// Passwort ist nach Vorgaben
				
				// Generiere zufälligen Salt
				new salt[11];
				for(new i; i < 10; i++) {
	                salt[i] = random(79) + 47;
	            }
	            salt[10] = 0;
				bcrypt_hash(inputtext, BCRYPT_COST, "OnPasswordHashed", "d", playerid);
				return true;
			}
	    }
	}
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
    new query[500];
	mysql_format(dbhandle, query, sizeof(query), "CREATE TABLE IF NOT EXISTS `users` (\
		`id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'unique user id',\
		`name` VARCHAR(20) NOT NULL COMMENT 'user name (unique)' COLLATE 'utf8mb4_general_ci',\
		`password` VARCHAR(61) NOT NULL COMMENT 'password (bcrypt encrypted)' COLLATE 'utf8mb4_general_ci',\
		`salt` VARCHAR(11) NOT NULL COMMENT 'unique salt to protect password' COLLATE 'utf8mb4_general_ci',\
		PRIMARY KEY (`id`) USING BTREE\
	)\
	COMMENT='all user informations'\
	COLLATE='utf8mb4_general_ci'\
	ENGINE=InnoDB;");
	mysql_tquery(dbhandle, query);
	
	return true;
}
