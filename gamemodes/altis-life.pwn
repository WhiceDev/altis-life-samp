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

public OnGameModeInit() {
	// Starte das Benchmarking
	startTime = GetTickCount();

	// Datenbankverbindung
	mysqlConnect();
	
	return true;
}

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
