const mongoose = require("mongoose");


/* I campi intervento_RIF e tecnico_RIF sono stati rinominati in intervento e tecnico per semplificare la struttura del documento.
Essi si riferiscono agli ID dell'intervento e del tecnico di riferimento, e sono obbligatori.

Si sarebbe potuto decidere di mettere direttamente i dati dell'intervento e del tecnico, ma in questo modo si mantiene una struttura più pulita, soprattutto visto che, ad esempio, lo stesso intervento può avere più log associati e solo con il nome si poteva creare ridondanza.

Il campo timestamp_log ha un valore predefinito che utilizza la data corrente.
I campi problemi_riscontrati e stato_avanzamento, essendo nullable, hanno un valore predefinito di null. */
const logSchema = new mongoose.Schema({

    intervento: {
        type: Number,
        min : 1, // L'ID intervento deve essere un numero positivo
        required: true,
    },

    tecnico: {
        type: Number,
        min : 1, // L'ID del tecnico deve essere un numero positivo
        required: true
    },

    timestamp_log: {
        type: Date,
        default: Date.now
    },

    attivita_svolta: {
        type: String,
        required: true,
        trim: true
    },

    problemi_riscontrati: {
        type: String,
        trim: true,
        default: null,
    },

    stato_avanzamento: {
        type: String,
        trim: true,
        default: null,
    }
});

module.exports = mongoose.model("Log", logSchema);