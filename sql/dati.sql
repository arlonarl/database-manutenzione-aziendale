USE Manutenzione_Azienda;

-- DATA MANIPULATION LANGUAGE

-- Un'azienda manifatturiera riceve nel periodo 10-18 marzo 2025 sei segnalazioni da quattro reparti diversi. Quattro di queste generano altrettanti interventi assegnati a tre squadre specializzate (Alfa, Beta, Gamma).
-- Due segnalazioni non producono interventi: una annullata e una ancora in attesa - utile per la query 9.
-- Intervento 1 coinvolge due squadre (Alfa + Beta) --> soddisfa la query 5.

-- PERSONALE
-- 9 dipendenti: ID 1-3 saranno Operatori, ID 4-9 saranno Tecnici.
-- La suddivisione è stabilita dagli INSERT nelle tabelle figlio.

INSERT INTO Personale (nome, cognome, matricola, email) VALUES
	-- 3 operatori
    ("Marco",   "Rossi",    "OP001", "marco.rossi@azienda.it"),
    ("Laura",   "Bianchi",  "OP002", "laura.bianchi@azienda.it"),
    ("Giorgio", "Ferri",    "OP003", "giorgio.ferri@azienda.it"),
    ("Davide",  "Conti",    "TC001", "davide.conti@azienda.it"),     -- Squadra Alfa, elettrica esperto
    ("Elena",   "Russo",    "TC002", "elena.russo@azienda.it"),      -- Squadra Alfa, elettrica avanzato
    ("Luca",    "Marino",   "TC003", "luca.marino@azienda.it"),      -- Squadra Beta, meccanica esperto
    ("Sara",    "Gallo",    "TC004", "sara.gallo@azienda.it"),       -- Squadra Beta, meccanica avanzato
    ("Paolo",   "Ricci",    "TC005", "paolo.ricci@azienda.it"),      -- Squadra Gamma, informatica esperto
    ("Chiara",  "Lombardi", "TC006", "chiara.lombardi@azienda.it");  -- Squadra Alfa


-- OPERATORE (eredita da Personale)
INSERT INTO Operatore (operatore_ID, telefono_interno) VALUES 
	(1, "0871"),
    (2, "0872"),
    (3, "0873");
-- TECNICO (eredita da Personale)
INSERT INTO Tecnico (tecnico_ID, anni_esperienza) VALUES 
	(4, 12),
    (5, 8),
    (6, 15),
    (7, 6),
    (8, 10),
    (9, 7);

-- REPARTO
INSERT INTO Reparto (nome, piano, responsabile) VALUES 
    ("Produzione",         "1",  "Ing. Verdi"),
    ("Magazzino",          "0",  "Sig. Neri"),
    ("Ufficio IT",         "3",  "Dott. Mori"),
    ("Impianti Generali",  NULL, "Ing. Serra");  -- nessun piano fisso

-- COMPETENZA
-- La competenza "Manutenzione elettrica" (ID=1) è usata dalla query 3.
INSERT INTO Competenza (nome, descrizione) VALUES
    ("Manutenzione elettrica",  "Interventi su quadri, impianti e cablaggi elettrici"),
    ("Manutenzione meccanica",  "Riparazione e revisione di componenti meccanici e cinematismi"),
    ("Manutenzione idraulica",  "Interventi su tubazioni, valvole e impianti idraulici"),
    ("Informatica",             "Assistenza e configurazione hardware e software"),
    ("Gestione impianti",       "Supervisione e manutenzione di impianti industriali complessi");

-- SQUADRA
-- Squadra Alfa (elettrica) e Beta (meccanica) collaboreranno nell'intervento 1.
INSERT INTO Squadra (nome, specializzazione) VALUES 
    ("Squadra Alfa",  "Elettrica"),
    ("Squadra Beta",  "Meccanica"),
    ("Squadra Gamma", "Informatica");

-- TECNICI_COMPETENZE
INSERT INTO Tecnici_Competenze (tecnico_RIF, competenza_RIF, livello, anno_certificazione) VALUES 
    (4, 1, "Esperto", 2018),    -- Davide: elettrica esperto
    (4, 2, "Avanzato", 2020),   -- Davide: meccanica avanzato (polivalente)
    (5, 1, "Avanzato", 2021),   -- Elena: elettrica avanzato
    (5, 5, "Base", NULL),       -- Elena: gestione impianti base
    (6, 2, "Esperto", 2016),    -- Luca: meccanica esperto
    (6, 3, "Base", NULL),       -- Luca: idraulica base
    (7, 2, "Avanzato", 2022),   -- Sara: meccanica avanzato
    (8, 4, "Esperto", 2019),    -- Paolo: informatica esperto
    (9, 4, "Avanzato", 2021),   -- Chiara: informatica avanzato
    (9, 1, "Base", NULL);	   	-- Chiara possiede anche competenze elettriche di base oltre a quelle informatiche.


-- TECNICI_SQUADRE
INSERT INTO Tecnici_Squadre (tecnico_RIF, squadra_RIF, data_ingresso, data_uscita, ruolo) VALUES 
    -- Squadra Alfa: Davide, Elena e Chiara
    (4, 1, "2020-06-01", NULL, "Responsabile"),
    (5, 1, "2021-03-15", NULL, "Tecnico Senior"),
    (9, 1, "2025-02-01", NULL, "Tecnico"),			-- Chiara trasferita da gamma

    -- Squadra Beta: Luca (fondatore), Sara
    (6, 2, "2019-09-01", NULL, "Responsabile"),
    (7, 2, "2022-05-10", NULL, "Tecnico Senior"),

    -- Squadra Gamma: Paolo (attivo)
    (8, 3, "2020-01-15", NULL, "Responsabile"),
    (9, 3, "2022-01-01", "2025-01-31", "Tecnico");


-- RICHIESTA
-- Distribuzione per la query 9 (richieste/giorno e quante generano intervento):
--   10/03: 2 richieste --> 1 genera intervento (richiesta 2 resta "In attesa")
--   12/03: 1 richiesta --> 1 genera intervento
--   15/03: 2 richieste --> 1 genera intervento (richiesta 5 annullata)
--   18/03: 1 richiesta --> 1 genera intervento
-- -----------------------------------------------------------------------------
INSERT INTO Richiesta (titolo, descrizione, data_richiesta, priorita, stato, operatore_RIF, reparto_RIF) VALUES 
    (
        "Guasto quadro elettrico Produzione",
        "Il quadro elettrico principale del reparto risulta in corto: la linea 3 è completamente spenta.",
        "2025-03-10 08:30:00", "Alta", "Chiusa", 1, 1
    ),
    (
        "Perdita acqua nel Magazzino B",
        "Tubazione rotta nella zona deposito: rischio scivolamento e danni alle merci.",
        "2025-03-10 14:00:00", "Alta", "In attesa", 2, 2  -- non genera intervento (ancora in attesa)
    ),
    (
        "Server IT principale non risponde",
        "Il server di produzione risulta irraggiungibile da tutte le postazioni: servizi bloccati.",
        "2025-03-12 09:00:00", "Alta", "Chiusa", 3, 3
    ),
    (
        "Nastro trasportatore linea 2 fuori tensione",
        "Il nastro perde tensione progressivamente; la produzione rallentata del 40%.",
        "2025-03-15 11:00:00", "Media", "In lavorazione", 1, 1
    ),
    (
        "Rumore anomalo compressore aria",
        "Operatori segnalano un rumore intermittente dal compressore centrale.",
        "2025-03-15 15:30:00", "Bassa", "Annullata", 2, 4  -- annullata: non genera intervento
    ),
    (
        "Aggiornamento urgente software gestionale",
        "Il fornitore ha rilasciato una patch critica di sicurezza: applicazione entro 48h.",
        "2025-03-18 10:00:00", "Media", "In lavorazione", 3, 3
    );

-- INTERVENTO
-- Quattro interventi, ognuno nato da una richiesta (richiesta 2 e 5 escluse).
-- Intervento 1: unico completato, con data_chiusura valorizzata.
-- Intervento 2-4: ancora aperti/in corso.
-- -----------------------------------------------------------------------------
INSERT INTO Intervento (titolo, descrizione, data_apertura, data_chiusura, stato, richiesta_RIF) VALUES 
    (
        "Ripristino quadro elettrico Produzione",
        "Ispezione, sostituzione fusibili bruciati e ripristino cablaggio danneggiato sulla linea 3.",
        "2025-03-10 10:00:00", "2025-03-10 18:00:00", "Completato", 1
    ),
    (
        "Ripristino server IT principale",
        "Diagnosi del guasto, sostituzione disco RAID e ripristino dei servizi di produzione.",
        "2025-03-12 10:00:00", NULL, "In corso", 3
    ),
    (
        "Manutenzione nastro trasportatore linea 2",
        "Tensionamento, lubrificazione rulli e verifica sistema di trasmissione.",
        "2025-03-15 13:00:00", NULL, "In corso", 4
    ),
    (
        "Deploy patch sicurezza software gestionale",
        "Installazione patch v4.2.1, test di regressione e validazione in ambiente di staging.",
        "2025-03-18 11:30:00", NULL, "Aperto", 6
    );

-- SQUADRE_INTERVENTI
-- L'intervento 1 coinvolge due squadre (Alfa + Beta): dato chiave per la query 5. Gli altri interventi hanno una squadra ciascuno. Conti per la query 7 (interventi per squadra):
--   Alfa  --> 1 (intervento 1)
--   Beta  --> 2 (interventi 1 e 3)
--   Gamma --> 2 (interventi 2 e 4)
INSERT INTO Squadre_Interventi (squadra_RIF, intervento_RIF, data_assegnazione) VALUES 
    (1, 1, "2025-03-10 09:45:00"),  -- Alfa  --> intervento 1 (quadro elettrico)
    (2, 1, "2025-03-10 09:45:00"),  -- Beta  --> intervento 1 (supporto meccanico) ← jolly
    (3, 2, "2025-03-12 09:30:00"),  -- Gamma --> intervento 2 (server IT)
    (2, 3, "2025-03-15 12:30:00"),  -- Beta  --> intervento 3 (nastro trasportatore)
    (3, 4, "2025-03-18 11:00:00");  -- Gamma --> intervento 4 (software)

-- MEZZO
INSERT INTO Mezzo (targa, tipo, marca_modello, disponibile) VALUES 
    ("AB123CD", "Furgone", "Fiat Ducato 2022", TRUE),
    ("EF456GH", "Muletto", "Toyota 7FBH15", TRUE),
    (NULL, "Piattaforma elevatrice", "Haulotte H12 SX", FALSE),  -- in uso. Non ha targa: veicolo da cantiere.
    ("IJ789KL", "Furgone", "Mercedes Sprinter 314", TRUE);

-- INTERVENTI_MEZZI
-- La FK (squadra_RIF, intervento_RIF) verifica che la squadra sia già assegnata all'intervento in Squadre_Interventi.

-- Intervento 1: due mezzi, uno per squadra (Alfa usa il furgone AB123CD, Beta usa la piattaforma elevatrice per i lavori in quota).
-- Intervento 2: Gamma usa il furgone IJ789KL per trasportare attrezzatura.
-- Intervento 3: Beta usa il muletto per movimentare componenti pesanti.
-- Intervento 4: nessun mezzo necessario (intervento software, in loco).
INSERT INTO Interventi_Mezzi (intervento_RIF, mezzo_RIF, squadra_RIF, ore_utilizzo) VALUES 
    (1, 1, 1, 8.00),  	-- int.1, furgone AB, Squadra Alfa
    (1, 3, 2, 8.00),  	-- int.1, piattaforma, Squadra Beta
    (2, 4, 3, 3.50),  	-- int.2, furgone IJ, Squadra Gamma
    (3, 2, 2, 4.00);	-- int.3, muletto, Squadra Beta 


-- STRUMENTO
INSERT INTO Strumento (nome, tipo, descrizione, unita_misura, consumabile, quantita_disponibile) VALUES 
    ("Multimetro digitale Fluke 117", "Utensile", "Tester per misura tensione, corrente e resistenza", "pezzi", FALSE, 4),
    ("Fusibili 16A ceramici", "Ricambio", "Fusibili di ricambio per quadri elettrici industriali", "pezzi", TRUE, 180),
    ("Chiave dinamometrica 40-200 Nm", "Utensile", "Chiave per serraggio a coppia controllata", "pezzi", FALSE, 3),
    ("Lubrificante industriale WD-40", "Consumabile","Lubrificante multifunzione per rulli e cinematismi", "litri", TRUE, 12);

-- INTERVENTI_STRUMENTI
-- La FK (squadra_RIF, intervento_RIF) verifica la coerenza con Squadre_Interventi.
-- Intervento 1: Alfa usa il multimetro e i fusibili di ricambio.
-- Intervento 3: Beta usa la chiave dinamometrica e il lubrificante.
-- Interventi 2 e 4: solo attrezzatura informatica non catalogata qui (laptop, cavi, ecc.) - volutamente assenti per variare il dataset.
INSERT INTO Interventi_Strumenti (intervento_RIF, strumento_RIF, squadra_RIF, quantita_usata) VALUES 
    (1, 1, 1,  1),   -- int.1: Alfa usa 1 multimetro
    (1, 2, 1, 12),   -- int.1: Alfa usa 12 fusibili di ricambio
    (3, 3, 2,  1),   -- int.3: Beta usa 1 chiave dinamometrica
    (3, 4, 2,  2);   -- int.3: Beta usa 2 litri di lubrificante


-- LOG
-- Nove log distribuiti su tutti e quattro gli interventi (il quarto, appena aperto, ha un solo log iniziale). Variazione di tecnici scriventi, stati avanzamento e presenza/assenza di problemi riscontrati.
-- Corrispondenza tecnici-squadre attive al momento degli interventi:
--   Intervento 1 (Alfa+Beta): Davide(4), Elena(5) [Alfa] - Luca(6) [Beta]
--   Intervento 2 (Gamma):     Paolo(8)
--   Intervento 3 (Beta):      Luca(6), Sara(7)
--   Intervento 4 (Gamma):     Paolo(8)
--
-- Query 6 (log per intervento): int.1-->4, int.2-->2, int.3-->2, int.4-->1
-- Query 8 (tecnici con più interventi): Luca(6) e Sara(7) su 2 interventi (1+3), Paolo(8) su 2 interventi (2+4) --> tre tecnici a pari merito in cima.
-- -----------------------------------------------------------------------------
INSERT INTO Log (intervento_RIF, tecnico_RIF, timestamp_log, attivita_svolta, problemi_riscontrati, stato_avanzamento) VALUES 
    -- Intervento 1: quadro elettrico (4 log, tre tecnici diversi)
    (
        1, 4, "2025-03-10 10:30:00",
        "Ispezione visiva del quadro elettrico principale: rilevati tre fusibili bruciati e sezione di cablaggio con isolamento danneggiato.",
        "Cablaggio lato utenza linea 3 parzialmente fuso: necessaria sostituzione completa del tratto.",
        "25%"
    ),
    (
        1, 5, "2025-03-10 12:45:00",
        "Sostituzione dei tre fusibili 16A bruciati e rimozione del tratto di cablaggio danneggiato.",
        NULL,
        "50%"
    ),
    (
        1, 6, "2025-03-10 15:15:00",
        "Stesura del nuovo cablaggio sulla linea 3 e collegamento ai morsetti del quadro. Verifica continuità con multimetro.",
        NULL,
        "75%"
    ),
    (
        1, 4, "2025-03-10 17:30:00",
        "Test finale: riattivazione quadro, verifica tensione su tutte le linee, collaudo con il responsabile di reparto. Impianto ripristinato.",
        NULL,
        "Completato"
    ),

    -- Intervento 2: server IT (2 log, stesso tecnico)
    (
        2, 8, "2025-03-12 10:45:00",
        "Diagnosi iniziale: il server non risponde a ping. Accesso diretto in sala server. Il RAID controller segnala un disco in stato 'failed'.",
        "Disco RAID 1 in fault: necessaria sostituzione immediata per evitare perdita dati.",
        "20%"
    ),
    (
        2, 8, "2025-03-12 15:30:00",
        "Sostituzione del disco difettoso con hot-spare disponibile in magazzino. Avviata ricostruzione array RAID. Servizi riportati online in modalità degradata.",
        NULL,
        "60%"
    ),

    -- Intervento 3: nastro trasportatore (2 log, tecnici diversi)
    (
        3, 6, "2025-03-15 13:45:00",
        "Misurazione tensione nastro con tensiometro: valore rilevato 180 N, norma prevista 280 N. Ispezione rulli: tre rulli presentano usura superficiale.",
        "Tensione fuori norma del 35%; due rulli centrali da sostituire nella prossima manutenzione programmata.",
        "25%"
    ),
    (
        3, 7, "2025-03-15 16:30:00",
        "Tensionamento nastro al valore di norma. Lubrificazione di tutti i rulli con WD-40. Prova a vuoto e a carico: parametri rientrati nella norma.",
        NULL,
        "80%"
    ),

    -- Intervento 4: software (1 log iniziale, appena avviato)
    (
        4, 8, "2025-03-18 12:15:00",
        "Backup completo del database gestionale e snapshot della VM prima di procedere con il deploy della patch v4.2.1.",
        NULL,
        "15%"
    );
