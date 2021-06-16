#include <a_samp>
#include <a_mysql>

/* MySQL Daten */

#define MYSQL_HOSTNAME "localhost"
#define MYSQL_USERNAME "root"
#define MYSQL_PASSWORD ""
#define MYSQL_DATABASE "altis-life"

new MySQL:dbhandle;


// Variable für Benchmark Tests (Zeitberechnung)
new startTime;




main() {}


/*
 *
 *  Dieses Callback wird aufgerufen, wenn der Gamemode geladen wird.
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
*/
public OnGameModeInit() {
	// Starte das Benchmarking
	startTime = GetTickCount();

	// Datenbankverbindung
	mysqlConnect();
	
	return true;
}


/*
 *
 *  Dieses Callback wird aufgerufen, wenn der Gamemode beendet wird.
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
 *  Verbindung zur Datenbank
 *	mit den oben angegebenen Daten (MySQL Daten)
 *
*/
stock mysqlConnect() {
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
}

/*
 *
 *  Dieses Callback wird aufgerufen, wenn ein Fehler bei der Verarbeitung einer MySQL-Abfrage auftritt.
 *	Dieses Callback benutzt den Return-Wert nicht.
 *
 * 	@param	errorid		ID des Fehlers
 * 	@param  error 		Fehlermeldung
 *  @param  callback    Name des aufgerufenen Callbacks (leer wenn keins angegeben)
 *  @param  query       Die Ausgeführte Abfrage
 *  @param  handle      Die Datenbankverbindung
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
