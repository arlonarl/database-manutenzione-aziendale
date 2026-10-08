# Note progettuali

## Obiettivo

Rappresentare le segnalazioni dei reparti aziendali, gli interventi che ne derivano e le risorse coinvolte, mantenendo informazioni utili alla tracciabilità delle attività. Il [README](../README.md#ambito-e-requisiti-del-progetto) descrive il dominio e i requisiti originali e contiene le istruzioni di avvio.

La componente relazionale è il modello esteso del dominio. L'estensione MongoDB seleziona soltanto i log e aggiunge un'API CRUD indipendente.

## Modellazione relazionale

Lo [schema](../sql/schema.sql) comprende 16 tabelle e due viste. `Personale` conserva nome, cognome, matricola ed email; `Operatore` e `Tecnico` hanno chiavi primarie che sono anche foreign key verso la tabella padre. Questa generalizzazione evita di duplicare le anagrafiche. Non impone che ogni dipendente appartenga a un ruolo, né che i due ruoli siano disgiunti: lo schema permette di assegnarli entrambi alla stessa persona.

`Reparto` è un'anagrafica indipendente. Il responsabile è un testo, come esplicitato nel commento SQL, anziché una relazione aggiuntiva con `Personale`.

`Richiesta` ha obbligatoriamente un operatore e un reparto. `Intervento` ha obbligatoriamente una richiesta, ma `richiesta_RIF` non è univoco: una richiesta può non generare interventi oppure generarne più di uno. I dati iniziali mostrano soltanto il caso con un intervento per richiesta.

Le associazioni molti a molti hanno tabelle dedicate, con attributi propri quando necessario. È una separazione dei dati coerente con una modellazione relazionale normalizzata; i file non contengono un'analisi formale delle dipendenze funzionali che permetta di attestare una specifica forma normale.

### Chiavi e vincoli

Matricola ed email del personale, nomi di reparti, squadre e competenze sono univoci. La targa del mezzo è univoca quando valorizzata e può essere `NULL`.

I `CHECK` limitano priorità, stati, livelli, ruoli, anni di esperienza e quantità. Controllano date dal 2000 e la successione apertura/chiusura e ingresso/uscita. Le colonne facoltative rimangono nullable: un `CHECK` non sostituisce `NOT NULL`.

Non vengono controllate tutte le regole del dominio: un intervento può essere privo di squadre, una squadra priva di membri, la chiusura non è vincolata allo stato e la data di un log non è confrontata con quella dell'intervento. `ore_utilizzo` non ha un vincolo che escluda valori negativi.

### Cancellazioni

| Relazione | Comportamento effettivo |
| --- | --- |
| Personale → Operatore/Tecnico | Cancellazione bloccata se esiste il ruolo figlio. |
| Operatore/Reparto → Richiesta | Cancellazione bloccata se esistono richieste. |
| Richiesta → Intervento | Cancellazione bloccata se esistono interventi. |
| Tecnico/Competenza → Tecnici_Competenze | Associazioni eliminate con `CASCADE`. |
| Tecnico/Squadra → Tecnici_Squadre | Appartenenze eliminate con `CASCADE`. |
| Squadra/Intervento → Squadre_Interventi | Partecipazioni eliminate con `CASCADE`, salvo blocchi dovuti alle assegnazioni di risorse. |
| Squadre_Interventi → Interventi_Mezzi/Interventi_Strumenti | Cancellazione bloccata: le foreign key composte non hanno `ON DELETE CASCADE`. |
| Mezzo/Strumento → assegnazioni | Cancellazione bloccata se la risorsa è assegnata. |
| Intervento → Log | Log eliminati con `CASCADE`, se la cancellazione dell'intervento è consentita. |
| Tecnico → Log | Cancellazione bloccata se il tecnico è autore di log. |

La cascata non si propaga automaticamente attraverso una foreign key con comportamento restrittivo. Per eliminare un intervento con risorse occorre prima rimuovere le assegnazioni.

## Gestione della manutenzione

### Richieste e interventi

Titolo, descrizione, date, priorità e stato descrivono la segnalazione. L'intervento mantiene titolo, descrizione, apertura, eventuale chiusura e stato propri. Gli stati delle due entità sono indipendenti: non esistono trigger o procedure che li allineino.

### Tecnici, squadre e competenze

`Tecnici_Competenze` associa una competenza una sola volta a ciascun tecnico, con eventuale livello e anno di certificazione. `Tecnici_Squadre` conserva ruolo, ingresso e uscita. La chiave `(tecnico_RIF, squadra_RIF, data_ingresso)` permette rientri, ma non impedisce intervalli sovrapposti.

L'assunzione della pagina «Premesse» nel diagramma è che tutti i membri della squadra alla data di assegnazione partecipino all'intervento. Q8, Q13 e Q14 applicano questa regola: non misurano presenze individuali registrate separatamente. Un tecnico può partecipare senza scrivere log.

Le date di appartenenza sono `DATE`, mentre l'assegnazione è `DATETIME`. Il giorno di uscita è trattato come incluso, confrontando `data_uscita` con `DATE(data_assegnazione)`; altrimenti il confronto escluderebbe le assegnazioni successive alla mezzanotte di quel giorno.

Q12 considera attivi i record con `data_uscita IS NULL`. Non ricostruisce l'appartenenza a una data arbitraria e non esclude ingressi futuri.

### Mezzi e strumenti

Le tabelle di utilizzo memorizzano la squadra assegnataria e ore o quantità. La foreign key `(squadra_RIF, intervento_RIF)` impone che la squadra sia già assegnata all'intervento.

Le chiavi `(intervento_RIF, mezzo_RIF)` e `(intervento_RIF, strumento_RIF)` permettono una sola assegnazione di ciascuna risorsa nell'intervento. La stessa risorsa non può essere suddivisa tra più squadre dello stesso intervento. Lo schema non impedisce invece l'uso contemporaneo in interventi diversi.

`disponibile` e `quantita_disponibile` sono dati memorizzati: non esiste un aggiornamento automatico all'inserimento delle assegnazioni, né una verifica della disponibilità residua. Gli strumenti includono utensili, ricambi e consumabili, senza un modello separato di movimenti di magazzino.

### Log

Ogni log identifica intervento e tecnico e contiene data, attività, eventuali problemi e avanzamento. La FK controlla l'esistenza del tecnico, ma non la sua appartenenza a una squadra coinvolta. I materiali non hanno un campo dedicato nel log: possono essere descritti nell'attività, mentre le quantità strutturate sono in `Interventi_Strumenti` a livello di squadra/intervento.

## Query e interrogazioni

Le viste `v_tecnici` e `v_operatori` compongono i nomi e rendono disponibili le matricole, centralizzando il join con `Personale`. Sono oggetti strutturali creati da `schema.sql`; `query.sql` contiene solo selezione del database e interrogazioni.

Q1–Q4 interrogano richieste, aperture giornaliere, competenze e mezzi. Q5–Q9 raggruppano squadre, log, interventi e richieste. Q10–Q13 esplorano le relazioni di una richiesta, di un intervento o di una squadra. Q14 fornisce il dettaglio complessivo delle risorse coinvolte.

### Aggregazioni e conteggi

Q5 individua gli interventi con più squadre tramite `GROUP BY` e `HAVING`. Q6 e Q7 utilizzano `LEFT JOIN` per includere anche interventi senza log e squadre senza interventi: il conteggio delle chiavi associate restituisce zero quando non esistono record collegati.

Q8 costruisce una classifica per numero di interventi distinti. Un tecnico appartenente a più squadre coinvolte nello stesso intervento contribuisce una sola volta al conteggio di quell'intervento. La classifica comprende i tecnici con almeno un'assegnazione e conserva gli eventuali pari merito.

Q9 raggruppa le richieste per giorno e distingue quelle con almeno un intervento da quelle senza interventi. L'unità di conteggio è la richiesta: anche quando genera più interventi, viene contata una sola volta.

### Partecipazione e filtri temporali

Q8, Q13 e Q14 ricostruiscono la partecipazione dei tecnici attraverso le squadre assegnate e lo storico delle appartenenze. Un tecnico è incluso se la data di ingresso precede o coincide con l'assegnazione e la data di uscita è assente oppure comprende il giorno dell'assegnazione.

Il giorno di uscita è incluso per intero, coerentemente con il tipo `DATE` utilizzato per le appartenenze. La presenza di un log non è necessaria per risultare tra i partecipanti: il criterio è l'appartenenza alla squadra al momento dell'assegnazione.

### Riepilogo delle risorse

Q14 restituisce un dettaglio per intervento, associando mezzi e strumenti alla coppia squadra/intervento. Ogni risorsa compare quindi accanto alla squadra assegnataria.

Il risultato contiene combinazioni delle entità coinvolte: per una squadra con due mezzi e tre strumenti si ottengono sei combinazioni per tecnico. Le righe non indicano un utilizzo individuale delle risorse e non possono essere contate direttamente per ricavare il numero di tecnici, mezzi o strumenti.

### Lettura dei dati di esempio

Il dataset illustra richieste senza intervento, collaborazione tra squadre, trasferimenti di tecnici e distribuzione dei log. Alcuni risultati attesi sono:

| Interrogazione | Risultato sui dati di esempio |
| --- | --- |
| Q5 | L'intervento 1 coinvolge le squadre Alfa e Beta. |
| Q6 | Gli interventi 1–4 hanno rispettivamente 4, 2, 2 e 1 log. |
| Q7 | Alfa, Beta e Gamma sono assegnate rispettivamente a 1, 2 e 2 interventi. |
| Q8 | Luca, Sara e Paolo hanno due interventi ciascuno, secondo il criterio di partecipazione per squadra. |
| Q9 | Totale richieste/con intervento: 2/1 il 10 marzo, 1/1 il 12 marzo, 2/1 il 15 marzo e 1/1 il 18 marzo 2025. |

Date, identificativi e competenza nei filtri di `query.sql` sono valori dimostrativi da adattare all'interrogazione desiderata.

## Estensione MongoDB

### Mapping concettuale

| SQL `Log` | Documento Mongoose | Differenza |
| --- | --- | --- |
| `log_ID` | `_id` | Identificativo MongoDB generato autonomamente. |
| `intervento_RIF` | `intervento` | Numero obbligatorio, minimo 1; nessuna FK o verifica di esistenza. |
| `tecnico_RIF` | `tecnico` | Numero obbligatorio, minimo 1; nessuna FK o verifica di esistenza. |
| `timestamp_log` | `timestamp_log` | `Date` con default corrente; nessun limite dal 2000 e campo non obbligatorio. |
| `attivita_svolta` | `attivita_svolta` | Stringa obbligatoria con `trim`. |
| `problemi_riscontrati` | `problemi_riscontrati` | Stringa con `trim`, default `null`. |
| `stato_avanzamento` | `stato_avanzamento` | Stringa con `trim`, default `null`. |

Il modello si chiama `Log`; la collezione viene determinata dalla convenzione Mongoose, senza nome esplicito nel codice. Il documento può includere anche il campo di versione `__v`. Non contiene documenti incorporati di tecnici o interventi. I numeri mantengono un riferimento concettuale al dominio SQL, ma non sono relazioni applicative risolte da Node.js.

### API e validazione

`app.js` concentra avvio Express e cinque route; non ci sono controller separati o frontend. `express.json()` legge il corpo JSON; dotenv carica la configurazione dall'ambiente e da `.env`.

Il `POST` controlla la presenza di `intervento`, `tecnico` e `attivita_svolta`, poi esegue `save()` con validazione del modello. Il `PUT` usa `findByIdAndUpdate` con `new: true` e `runValidators: true`. I validatori di aggiornamento riguardano i percorsi modificati: non equivalgono alla validazione completa di un nuovo documento.

L'applicazione non impone ID interi, non verifica l'esistenza di tecnici/interventi e non distingue sistematicamente errore di validazione, ID malformato e indisponibilità del database. Un documento assente produce `404`; in alcuni percorsi anche errori diversi vengono tradotti in `404`, mentre la creazione non valida può produrre `500`.

### Connessione

Ogni route esegue `mongoose.connect(DB)` e chiama `disconnect()` dopo l'operazione, senza attenderne il completamento. La connessione Mongoose è condivisa: una richiesta può chiuderla mentre un'altra la sta usando. Nei percorsi di errore la disconnessione non è garantita.

Il server HTTP parte prima della connessione al database, che viene tentata solo su richiesta. Il messaggio di avvio non dimostra che MongoDB sia raggiungibile. Una possibile evoluzione è una connessione persistente, con gestione dell'avvio e della chiusura dell'applicazione.

## Confronto relazionale / documentale

In MySQL anagrafiche e associazioni sono separate e collegate da foreign key. Il log può esistere soltanto per un tecnico e un intervento presenti; eliminare un tecnico autore è bloccato, mentre eliminare un intervento può cancellarne i log.

In MongoDB viene mantenuto un documento per log con i soli identificativi numerici. Non è stato scelto di incorporare le anagrafiche né di creare collezioni collegate. L'API gestisce i documenti senza interrogare MySQL e non replica le sue politiche di cancellazione. La cancellazione di un documento non modifica altri dati.

La flessibilità documentale non implica assenza di schema: Mongoose definisce tipi, requisiti e valori predefiniti. Tuttavia la validazione è nel livello applicativo, non sono presenti vincoli MongoDB di collezione nel repository, e non riproduce tutta l'integrità referenziale SQL.

## Diagramma e documentazione

Il sorgente draw.io contiene una pagina ER e una pagina di premesse, particolarmente utile per la regola di partecipazione dei tecnici. Il diagramma ER è disponibile anche in formato SVG per la consultazione immediata.

Le 16 entità/tabelle del modello SQL hanno un corrispondente nel diagramma, che rappresenta anche attributi delle associazioni e generalizzazione del personale. Il disegno è concettuale: non elenca le chiavi SQL e non mostra tutti gli attributi implementativi, ad esempio il flag `disponibile` del mezzo. Non è sufficiente per dedurre le politiche di cancellazione o tutti i vincoli di cardinalità minima. Lo schema SQL resta la fonte per questi dettagli.

## Limiti e decisioni

I requisiti di diagramma, creazione SQL, dati di esempio e 14 interrogazioni sono rappresentati nei file. La richiesta di CRUD MongoDB è coperta dalle route sui log. Il sistema realizza soprattutto la persistenza e le interrogazioni: non contiene un'applicazione operativa MySQL con flussi per operatori e tecnici.

Il minimo di tecnici per squadra e di squadre per intervento previsto dai requisiti non è imposto dal database. Le appartenenze temporali possono sovrapporsi; la partecipazione è inferita per squadra, non registrata per persona. Materiali e risorse non sono un sistema di inventario completo. Questi punti sono semplificazioni, non funzionalità implementate.


