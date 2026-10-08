const express = require("express")
const mongoose = require("mongoose");
const Log = require('./models/Log');

require('dotenv').config();

const PORTA = process.env.PORTA || 4000;
const INDIRIZZO = process.env.INDIRIZZO || "localhost";
const DB = process.env.DB || "mongodb://localhost:27017/Manutenzione_Azienda";

const app = express();
app.use(express.json());

// Scelta la route /registri-log per chiarezza, solo /log potrebbe essere confusionario
app.listen(PORTA, INDIRIZZO, () => {
    console.log("Sono in ascolto sulla porta " + PORTA + " all'indirizzo " + INDIRIZZO);
    console.log("GET di tutti i log: http://" + INDIRIZZO + ":" + PORTA + "/registri-log");
    console.log("GET di un log specifico: http://" + INDIRIZZO + ":" + PORTA + "/registri-log/{id}");
    console.log("POST per creare un nuovo log: http://" + INDIRIZZO + ":" + PORTA + "/registri-log");
    console.log("DELETE per eliminare un log: http://" + INDIRIZZO + ":" + PORTA + "/registri-log/{id}");
    console.log("PUT per aggiornare un log: http://" + INDIRIZZO + ":" + PORTA + "/registri-log/{id}");
});

app.get("/registri-log", async (req, res) => {
    try {
        const db = await mongoose.connect(DB);
        let elenco = await Log.find({});
        db.disconnect();
        res.json(elenco);
    } catch (error) {
        res.status(500).json({ message: "Errore nel recupero dei log" });
    }
    
})

app.get("/registri-log/:id", async (req, res) => {
    try{
        const db = await mongoose.connect(DB);
        const id = req.params.id;
        let log = await Log.findById(id);
        db.disconnect();
        if (!log) {
            return res.status(404).json({ message: "Log non trovato" });
        }    
        res.json(log);
    } catch (error) {
        res.status(404).json({ message: "Log non trovato" });
    }
});

app.post("/registri-log", async (req, res) => {
    try {
        if (req.body.intervento === undefined || req.body.tecnico === undefined || req.body.attivita_svolta === undefined) {
        return res.status(400).json({ message: "Dati mancanti" });
        }
        const db = await mongoose.connect(DB);
        const log = new Log(req.body);
        await log.save();
        db.disconnect();
        res.status(201).json(log);
    } catch (error) {
        res.status(500).json({ message: "Errore nella creazione del log" });
    }
});

app.delete("/registri-log/:id", async (req, res) => {
    try {
        const db = await mongoose.connect(DB);
        const id = req.params.id;
        let log = await Log.findByIdAndDelete(id);
        db.disconnect();
        if (!log) {
            return res.status(404).json({ message: "Log non trovato" });
        }
        res.json({ message: "Log eliminato" })
    } catch (errore) {
        res.status(500).json({ message: "Errore nell'eliminazione del log" });
    }
});

app.put("/registri-log/:id", async (req, res) => {
    try {
        const db = await mongoose.connect(DB);
        const id = req.params.id;
        let log = await Log.findByIdAndUpdate(id, req.body, { new: true, runValidators: true });
        db.disconnect();
        if (!log) {
            return res.status(404).json({ message: "Log non trovato" });
        }
        res.json(log);
    } catch (errore) {
        res.status(404).json({ message: "Errore nell'aggiornamento del log" });
    }   
});
