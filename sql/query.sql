USE Manutenzione_Azienda;

-- QUERY LANGUAGE

-- Q1. Richieste di manutenzione con il relativo operatore
SELECT r.richiesta_ID, r.titolo AS richiesta, r.data_richiesta, r.priorita, r.stato,
    o.nome_completo AS operatore, o.matricola
FROM Richiesta r
JOIN v_operatori o ON r.operatore_RIF = o.operatore_ID
ORDER BY r.data_richiesta;


-- Q2. Interventi aperti in una determinata data
SELECT intervento_ID, titolo, data_apertura, stato, richiesta_RIF
FROM Intervento
WHERE data_apertura BETWEEN '2025-03-15 00:00:00' AND '2025-03-15 23:59:59'
ORDER BY data_apertura;


-- Q3. Tecnici con una specifica competenza
SELECT t.nome_completo AS tecnico, t.matricola, c.nome AS competenza, tc.livello
FROM v_tecnici t
JOIN Tecnici_Competenze tc ON t.tecnico_ID = tc.tecnico_RIF
JOIN Competenza c ON tc.competenza_RIF = c.competenza_ID
WHERE c.nome = 'Manutenzione elettrica'
ORDER BY tc.livello;		-- ordinamento alfabetico del livello


-- Q4. Mezzi utilizzati in un determinato intervento
SELECT m.mezzo_ID, m.targa, m.tipo, m.marca_modello,
	s.nome AS squadra
FROM Interventi_Mezzi im
JOIN Mezzo m ON im.mezzo_RIF = m.mezzo_ID
JOIN Squadra s ON im.squadra_RIF = s.squadra_ID
WHERE im.intervento_RIF = 1
ORDER BY m.tipo;


-- Q5. Interventi con più di una squadra
SELECT i.intervento_ID, i.titolo, i.stato, COUNT(si.squadra_RIF) AS numero_squadre
FROM Intervento i
JOIN Squadre_Interventi si ON i.intervento_ID = si.intervento_RIF
GROUP BY i.intervento_ID, i.titolo, i.stato
HAVING COUNT(si.squadra_RIF) > 1
ORDER BY numero_squadre;


-- Q6. Numero di log per ogni intervento
-- COUNT(l.log_ID) restituisce 0 per gli interventi senza log (i NULL non vengono contati)
SELECT i.intervento_ID, i.titolo, i.stato, COUNT(l.log_ID) AS numero_log
FROM Intervento i
LEFT JOIN Log l ON i.intervento_ID = l.intervento_RIF
GROUP BY i.intervento_ID, i.titolo, i.stato
ORDER BY numero_log;


-- Q7. Numero di interventi per ciascuna squadra
SELECT s.squadra_ID, s.nome AS squadra, s.specializzazione,
    COUNT(si.intervento_RIF) AS numero_interventi
FROM Squadra s
LEFT JOIN Squadre_Interventi si ON s.squadra_ID = si.squadra_RIF
GROUP BY s.squadra_ID, s.nome, s.specializzazione
ORDER BY numero_interventi;


-- Q8. Classifica dei tecnici per numero di interventi (i primi hanno il massimo)
SELECT t.nome_completo AS tecnico, t.matricola, COUNT(DISTINCT si.intervento_RIF) AS numero_interventi
FROM v_tecnici t
JOIN Tecnici_Squadre ts ON t.tecnico_ID = ts.tecnico_RIF
JOIN Squadre_Interventi si ON ts.squadra_RIF = si.squadra_RIF AND ts.data_ingresso <= si.data_assegnazione 
	AND 
		(ts.data_uscita IS NULL OR ts.data_uscita >= DATE(si.data_assegnazione))
GROUP BY t.tecnico_ID, t.nome_completo, t.matricola
ORDER BY numero_interventi DESC;
-- il filtro temporale garantisce che il tecnico fosse nella squadra al momento dell'assegnazione all'intervento, non solo in un momento qualsiasi
-- presente anche in Q13 e Q14


-- Q9. Richieste per giorno e quante hanno generato almeno un intervento
-- DISTINCT evita di contare pi? volte una richiesta che genera pi? interventi.
SELECT DATE(r.data_richiesta) AS giorno,
	COUNT(DISTINCT r.richiesta_ID) AS totale_richieste,
    COUNT(DISTINCT i.richiesta_RIF) AS con_intervento,
    COUNT(DISTINCT r.richiesta_ID) - COUNT(DISTINCT i.richiesta_RIF) AS senza_intervento
FROM Richiesta r
LEFT JOIN Intervento i ON r.richiesta_ID = i.richiesta_RIF
GROUP BY DATE(r.data_richiesta)
ORDER BY giorno;


-- Q10. Interventi generati da una specifica richiesta
SELECT intervento_ID, titolo, data_apertura, data_chiusura, stato
FROM Intervento
WHERE richiesta_RIF = 1
ORDER BY data_apertura;


-- Q11. Squadre assegnate a un determinato intervento
SELECT s.squadra_ID, s.nome AS squadra, s.specializzazione, si.data_assegnazione
FROM Squadre_Interventi si
JOIN Squadra s ON si.squadra_RIF = s.squadra_ID
WHERE si.intervento_RIF = 1
ORDER BY si.data_assegnazione;


-- Q12. Tecnici presenti in una specifica squadra
SELECT t.nome_completo AS tecnico, t.matricola, ts.ruolo
FROM Tecnici_Squadre ts
JOIN v_tecnici t ON ts.tecnico_RIF = t.tecnico_ID
WHERE ts.squadra_RIF = 1 AND ts.data_uscita IS NULL		-- solo membri attivi
ORDER BY t.matricola;


-- Q13. Tecnici che hanno partecipato a un determinato intervento
SELECT DISTINCT t.nome_completo AS tecnico, t.matricola, s.nome AS squadra
FROM Squadre_Interventi si
JOIN Tecnici_Squadre ts ON si.squadra_RIF = ts.squadra_RIF AND ts.data_ingresso <= si.data_assegnazione
	AND (ts.data_uscita IS NULL OR ts.data_uscita >= DATE(si.data_assegnazione))
JOIN v_tecnici t ON ts.tecnico_RIF = t.tecnico_ID
JOIN Squadra s ON si.squadra_RIF = s.squadra_ID
WHERE si.intervento_RIF = 1
ORDER BY s.nome;


-- Q14. Riepilogo completo per intervento: squadre, tecnici, mezzi, strumenti
-- Le righe rappresentano combinazioni di entità coinvolte, non correlazioni dirette tra tecnico, mezzo e strumento:
-- per una squadra con 2 mezzi e 3 strumenti si ottengono 6 combinazioni per tecnico.
-- Risultato di dettaglio denormalizzato: non usare il numero di righe per contare risorse o partecipanti.
SELECT DISTINCT i.intervento_ID, i.titolo AS intervento, i.stato,
    s.nome AS squadra, t.nome_completo AS tecnico,
    m.targa AS mezzo_targa, m.tipo AS mezzo_tipo,
    st.nome AS strumento, ist.quantita_usata
FROM Intervento i
LEFT JOIN Squadre_Interventi si ON i.intervento_ID = si.intervento_RIF
LEFT JOIN Squadra s ON si.squadra_RIF = s.squadra_ID
LEFT JOIN Tecnici_Squadre ts ON si.squadra_RIF = ts.squadra_RIF AND ts.data_ingresso <= si.data_assegnazione 
			AND (ts.data_uscita IS NULL OR ts.data_uscita >= DATE(si.data_assegnazione))
LEFT JOIN v_tecnici t ON ts.tecnico_RIF = t.tecnico_ID
LEFT JOIN Interventi_Mezzi im ON si.intervento_RIF = im.intervento_RIF AND si.squadra_RIF = im.squadra_RIF
LEFT JOIN Mezzo m ON im.mezzo_RIF = m.mezzo_ID
LEFT JOIN Interventi_Strumenti ist ON si.intervento_RIF = ist.intervento_RIF AND si.squadra_RIF = ist.squadra_RIF
LEFT JOIN Strumento st ON ist.strumento_RIF = st.strumento_ID
ORDER BY i.intervento_ID, s.nome;