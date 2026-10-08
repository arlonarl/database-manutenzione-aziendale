DROP DATABASE IF EXISTS Manutenzione_Azienda;
CREATE DATABASE Manutenzione_Azienda;
USE Manutenzione_Azienda;

-- DATA DEFINITION LANGUAGE

-- Operatori e tecnici hanno tabelle "identiche" e quindi per evitare ridondanza e permettere nuovi campi in futuro, ho preferito usare una tabella genitore
CREATE TABLE Personale (
	personale_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	nome VARCHAR(50) NOT NULL,
    cognome VARCHAR(50) NOT NULL,
    matricola VARCHAR(20) NOT NULL UNIQUE,		-- identificativo aziendale univoco per i dipendenti
    email VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Operatore (
	operatore_ID INT NOT NULL PRIMARY KEY,
    telefono_interno VARCHAR(10) NULL,
    FOREIGN KEY (operatore_ID) REFERENCES Personale (personale_ID)
);

CREATE TABLE Reparto (
	reparto_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    piano VARCHAR(10) NULL,						-- piano dell'edificio in cui è presente il reparto. Alcuni reparti potrebbero non avere un piano di riferimento
    responsabile VARCHAR(100) NOT NULL			-- qui si poteva scegliere di rendere responsabile un "figlio" di Personale e quindi avere un responsabile_RIF con FK ma sarebbe andato a complicare la struttura del progetto. Ho preferito evitare
);

CREATE TABLE Richiesta (
	richiesta_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    titolo VARCHAR(150) NOT NULL,
    descrizione TEXT NULL,
    data_richiesta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (data_richiesta >= "2000-01-01"),
    priorita VARCHAR(20) NOT NULL CHECK (priorita IN ("Alta", "Media", "Bassa")),
    stato VARCHAR (30) NOT NULL CHECK (stato IN ("In attesa", "In lavorazione", "Chiusa", "Annullata")),
    
    operatore_RIF INT NOT NULL,					-- chi ha registrato la segnalazione
    reparto_RIF INT NOT NULL,					-- da quale reparto proviene
    FOREIGN KEY (operatore_RIF) REFERENCES Operatore (operatore_ID),
    FOREIGN KEY (reparto_RIF) REFERENCES Reparto (reparto_ID)
);

CREATE TABLE Intervento (
	intervento_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    titolo VARCHAR(150) NOT NULL,
    descrizione TEXT NULL,
    data_apertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (data_apertura >= "2000-01-01"),
    data_chiusura DATETIME NULL CHECK (data_chiusura >= "2000-01-01"), 
    stato VARCHAR(30) NOT NULL CHECK (stato IN ("Aperto", "In corso", "Completato", "Sospeso")),
    
    richiesta_RIF INT NOT NULL,														-- un intervento nasce sempre da una richiesta quindi NOT NULL
	FOREIGN KEY (richiesta_RIF) REFERENCES Richiesta (richiesta_ID),
    CHECK (data_chiusura IS NULL OR data_chiusura >= data_apertura)					-- data_chiusura è NULL finchè l'intervento non è concluso
);
    
CREATE TABLE Squadra (
	squadra_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    specializzazione VARCHAR(100) NULL			-- area tecnica prevalente della squadra. Una squadra potrebbe anche non averla -> null
);

CREATE TABLE Tecnico (
	tecnico_ID INT NOT NULL PRIMARY KEY,
    anni_esperienza INT NULL CHECK (anni_esperienza BETWEEN 0 AND 50),
    FOREIGN KEY (tecnico_ID) REFERENCES Personale (personale_ID)
);

-- Tabella indipendente per permettere estensioni future senza toccare la tabella dei tecnici e query direttamente sulle competenze
CREATE TABLE Competenza (
	competenza_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descrizione TEXT NULL
);

-- Relazione molti a molti
CREATE TABLE Tecnici_Competenze (
	tecnico_RIF INT NOT NULL,
    competenza_RIF INT NOT NULL,
    livello VARCHAR(20) NULL CHECK (livello IN ("Base", "Avanzato", "Esperto")),
    anno_certificazione YEAR NULL,
    
    PRIMARY KEY (tecnico_RIF, competenza_RIF),					-- un tecnico non può avere la stessa competenza due volte
    
    -- se si elimina il tecnico o la competenza non ha senso mantenere l'associazione
    FOREIGN KEY (tecnico_RIF) REFERENCES Tecnico (tecnico_ID) ON DELETE CASCADE,
    FOREIGN KEY (competenza_RIF) REFERENCES Competenza (competenza_ID) ON DELETE CASCADE
);

-- Relazione molti a molti: registra lo storico di appartenenza di ogni tecnico alle squadre
CREATE TABLE Tecnici_Squadre (
	tecnico_RIF INT NOT NULL,
    squadra_RIF INT NOT NULL,
    data_ingresso DATE NOT NULL CHECK (data_ingresso >= "2000-01-01"),
    data_uscita DATE NULL CHECK (data_uscita >= "2000-01-01"),
    ruolo VARCHAR(50) NULL CHECK (ruolo IN ("Responsabile", "Vice Responsabile", "Tecnico Senior", "Tecnico")),

    
    PRIMARY KEY (tecnico_RIF, squadra_RIF, data_ingresso),				-- data_ingresso nella PK permette di tracciare rientri nella stessa squadra
    CHECK (data_uscita IS NULL OR data_uscita >= data_ingresso),		-- se è NULL il tecnico fa ancora parte della squadra sennò l'ha lasciata
    -- se si rimuove un tecnico o una squadra, l'associazione viene eliminata di conseguenza
    FOREIGN KEY (tecnico_RIF) REFERENCES Tecnico (tecnico_ID) ON DELETE CASCADE,	
    FOREIGN KEY (squadra_RIF) REFERENCES Squadra (squadra_ID) ON DELETE CASCADE
);

-- Un intervento può coinvolgere più squadre e una squadra può partecipare a più interventi
-- Relazione molti a molti: correlata anche all'utilizzo di mezzi e strumenti che vengono assegnati alla squadra solo quando effettua interventi
CREATE TABLE Squadre_Interventi (
	squadra_RIF INT NOT NULL,
    intervento_RIF INT NOT NULL,
    data_assegnazione DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (data_assegnazione >= "2000-01-01"),
    
    PRIMARY KEY (squadra_RIF, intervento_RIF),
    FOREIGN KEY (squadra_RIF) REFERENCES Squadra (squadra_ID) ON DELETE CASCADE,
    FOREIGN KEY (intervento_RIF) REFERENCES Intervento (intervento_ID) ON DELETE CASCADE
);

CREATE TABLE Mezzo (
	mezzo_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    targa VARCHAR(20) UNIQUE,				-- un mezzo può non avere una targa ma se ce l'ha è univoca
    tipo VARCHAR(50) NOT NULL,				-- es. "Furgone", "Muletto", "Gru", ...
    marca_modello VARCHAR(100) NULL,
    disponibile BOOLEAN NOT NULL DEFAULT TRUE
);

-- Relazione molti a molti con riferimento anche alla squadra
-- La FK verso Squadre_Interventi usa RESTRICT: rimuovere prima queste assegnazioni per eliminare la partecipazione o l'intervento.
CREATE TABLE Interventi_Mezzi (
	intervento_RIF INT NOT NULL,
    mezzo_RIF INT NOT NULL,
    squadra_RIF INT NOT NULL,																					-- squadra a cui il mezzo è assegnato
    ore_utilizzo DECIMAL(5,2) NOT NULL DEFAULT 0,
    
    PRIMARY KEY (intervento_RIF, mezzo_RIF),																	-- un mezzo viene utilizzato una sola volta per intervento
    FOREIGN KEY (mezzo_RIF) REFERENCES Mezzo (mezzo_ID),														-- non è possibile eliminare fisicamente un mezzo che risulti correlato in interventi passati, preservando così la tracciabilità
    FOREIGN KEY (squadra_RIF, intervento_RIF) REFERENCES Squadre_Interventi (squadra_RIF, intervento_RIF)		-- garantisce che una squadra possa essere associata ad un mezzo solo se è già assegnata a quell'intervento		
);

CREATE TABLE Strumento (
	strumento_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,				-- es. "Utensile", "Ricambio", "DPI", "Cavi",...
    descrizione TEXT NULL,
    unita_misura VARCHAR(20) NOT NULL,		-- es. "pezzi", "litri", "metri", "kg", ...
    consumabile BOOLEAN NOT NULL DEFAULT FALSE,
    quantita_disponibile INT NOT NULL DEFAULT 0 CHECK (quantita_disponibile BETWEEN 0 AND 10000)
);

-- Relazione molti a molti con riferimento anche alla squadra
-- La FK verso Squadre_Interventi usa RESTRICT: rimuovere prima queste assegnazioni per eliminare la partecipazione o l'intervento.
CREATE TABLE Interventi_Strumenti (
	intervento_RIF INT NOT NULL,
    strumento_RIF INT NOT NULL,
    squadra_RIF INT NOT NULL,
    quantita_usata INT NOT NULL DEFAULT 1 CHECK (quantita_usata BETWEEN 1 AND 10000),
    
    PRIMARY KEY (intervento_RIF, strumento_RIF),
    FOREIGN KEY (strumento_RIF) REFERENCES Strumento (strumento_ID),												-- come per i mezzi, gli strumenti non vengono eliminati per questioni di storico
    FOREIGN KEY (squadra_RIF, intervento_RIF) REFERENCES Squadre_Interventi (squadra_RIF, intervento_RIF) 			-- garantisce che una squadra possa essere associata ad uno strumento solo se è già assegnata a quell'intervento
);

CREATE TABLE Log (
	log_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    intervento_RIF INT NOT NULL,
    tecnico_RIF INT NOT NULL,
    timestamp_log DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (timestamp_log >= "2000-01-01"),
    attivita_svolta TEXT NOT NULL,
    problemi_riscontrati TEXT NULL,
    stato_avanzamento VARCHAR(50) NULL,			-- Può essere NULL perchè un log può essere redatto anche solo focalizzandosi sulle attività svolte e non necessariamente richiede un aggiornamento dello stato. Valori di esempio: "25%", "50%", "Completato", "Attesa revisione", ...
    
    FOREIGN KEY (intervento_RIF) REFERENCES Intervento (intervento_ID)ON DELETE CASCADE,		-- i log di un intervento eliminato non hanno più senso di esistere. Non equivale a dire che una volta CHIUSO l'intervento il log serve più, infatti:
    FOREIGN KEY (tecnico_RIF) REFERENCES Tecnico (tecnico_ID)									-- nel caso in cui un tecnico venga eliminato è importante tenere traccia dei log da lui redatti, anche se non è più presente nel database. E quindi NO DELETE ON CASCADE.
);

-- View di supporto: evitano di ripetere il join Tecnico -> Personale e Operatore -> Personale
CREATE VIEW v_tecnici AS
SELECT t.tecnico_ID, CONCAT(p.nome, ' ', p.cognome) AS nome_completo, p.matricola
FROM Tecnico t JOIN Personale p ON t.tecnico_ID = p.personale_ID;

CREATE VIEW v_operatori AS
SELECT o.operatore_ID, CONCAT(p.nome, ' ', p.cognome) AS nome_completo, p.matricola
FROM Operatore o JOIN Personale p ON o.operatore_ID = p.personale_ID;
