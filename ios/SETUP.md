# Pubblicare GSM Remote per Comandi Rapidi

## Stato e prerequisiti

Il sito genera la configurazione e supporta il passaggio tramite appunti alla
shortcut **GSM Remote**. La shortcut Apple deve ancora essere creata e verificata
con le istruzioni seguenti, poi condivisa via iCloud. Questa repository non
contiene un file `.shortcut` firmato. Non pubblicare un link prima del collaudo.
Serve un iPhone (oppure un Mac con Comandi Rapidi, seguito dal collaudo su iPhone).
Non serve un server. La conferma di aggiunta di Apple è necessaria.

Il risultato è un unico Comando Rapido con una lista di quattro voci, non una
schermata personalizzata con quattro pulsanti a griglia. Ogni utente installa la
stessa shortcut, ma salva la propria configurazione in iCloud Drive. È prevista
una configurazione attiva per utente: importarne una nuova sostituisce quella
precedente solo dopo conferma. iCloud può sincronizzarla sugli altri dispositivi
dello stesso account. Il sito non la carica su GitHub o su un nostro server.

## Costruire la shortcut una volta sola

I nomi delle azioni possono variare leggermente con lingua e versione di iOS.
Le variabili indicate qui vanno collegate agli output delle azioni, non digitate
come testo letterale. Creare un Comando Rapido chiamato esattamente **GSM Remote**.

### A. Importazione (quando è presente Input comando rapido)

1. Aggiungere **Se** → `Input comando rapido` **ha un valore**.
2. Nel ramo Se: **Ottieni dizionario dall’input** usando `Input comando rapido`.
   Salvare il risultato nella variabile `Configurazione` con **Imposta variabile**.
3. Validare prima di salvare. Usare **Ottieni valore dizionario**, **Conta** e
   blocchi **Se**. In ogni caso non valido mostrare un avviso e terminare con
   **Interrompi questo comando rapido**:
   - `version` deve essere il numero `1`;
   - `phone` deve corrispondere all’espressione regolare `^\+?[0-9]{3,15}$`
     (azione **Trova corrispondenze nel testo**);
   - `names` deve essere una lista con esattamente quattro elementi;
   - `messages` deve essere un dizionario con esattamente quattro chiavi;
   - **Ripeti con ogni elemento** di `names`: verificare che il nome sia testo
     non vuoto, lungo al massimo 40 caratteri, e che esista in `messages` con
     un valore testo non composto solo da spazi. Usare una lista `Nomi verificati`
     per rifiutare nomi duplicati. Non modificare gli spazi del testo SMS originale.
4. **Mostra avviso**: «Salvare questa configurazione per [phone]? Sostituirà
   l’eventuale configurazione precedente.» Lasciare attivo il pulsante Annulla.
5. **Ottieni testo dall’input** con `Input comando rapido` (il JSON originale).
6. **Imposta nome** del testo a `gsm-remote-config.json`.
7. **Salva file** in `iCloud Drive/Shortcuts`, con **Chiedi dove salvare** disattivato
   e **Sovrascrivi se il file esiste** attivo. Il percorso risultante deve essere
   `iCloud Drive/Shortcuts/gsm-remote-config.json`.
8. **Mostra avviso**: «Configurazione salvata. Apri GSM Remote per scegliere un comando.»
9. **Interrompi questo comando rapido**: l’importazione non deve mai proseguire
   fino all’invio di un messaggio.
10. Chiudere il blocco Se (lasciare vuoto Altrimenti).

### B. Telecomando (avvio senza input)

1. **Ottieni file dalla cartella** `iCloud Drive/Shortcuts`, percorso
   `gsm-remote-config.json`. Disattivare **Errore se non trovato**.
2. **Se** il file non ha un valore: **Mostra avviso** «Prima configura GSM Remote
   dal sito», poi **Interrompi questo comando rapido**.
3. **Ottieni testo dall’input** dal file, poi **Ottieni dizionario dall’input**.
   Impostare la variabile `Configurazione`. Ripetere le validazioni della sezione A
   anche qui, perché il file può essere modificato fuori dalla shortcut.
4. **Ottieni valore dizionario** `names` da `Configurazione`.
5. **Scegli dall’elenco**, input: `names`, prompt: «Scegli un comando».
   Disattivare la selezione multipla e salvare il risultato come `Nome scelto`.
   Se non ha un valore, interrompere il comando rapido.
6. **Ottieni valore dizionario** `messages` da `Configurazione`, poi
   **Ottieni valore dizionario** con chiave variabile `Nome scelto` da quel risultato.
   Impostare la variabile `Messaggio`.
7. **Ottieni valore dizionario** `phone` da `Configurazione`. Impostare `Numero`.
8. **Mostra avviso** con titolo `Nome scelto`, testo «Inviare a [Numero]?», seguito
   dal valore integrale di `Messaggio`. Lasciare attivo il pulsante Annulla.
9. **Invia messaggio**: testo `Messaggio`, destinatario `Numero` (variabile, non
   un contatto fisso). Lasciare **Mostra quando eseguito** attivo. Verificare
   su iPhone la conferma nell’interfaccia Messaggi e gli eventuali permessi.
   Non aggiungere notifiche che dichiarino la consegna dell’SMS.

L’annullamento della scelta o della conferma non deve inviare nulla.
Per avere un’icona sulla Home usare l’opzione **Aggiungi alla schermata Home**
della shortcut. Gli SMS richiedono un iPhone con servizio telefonico; l’apertura
del tab su iPad non implica che quel dispositivo possa inviarli autonomamente.

## Collaudo su iPhone prima della pubblicazione

Usare un numero di test sotto il proprio controllo, mai quello di un impianto reale.

- Avviare senza configurazione: viene mostrata la richiesta di configurarla.
- Dal sito compilare un numero e quattro comandi distinti; includere accenti,
  virgolette, `&`, `+` e un SMS su più righe. Copiare la configurazione.
- Per il primo collaudo, senza link iCloud pubblicato, aprire da Safari il link
  `shortcuts://run-shortcut?name=GSM%20Remote&input=clipboard`.
- Confermare il salvataggio: nessun SMS deve partire. Chiudere e riaprire la
  shortcut senza input: verificare i quattro nomi e ciascun destinatario/testo.
- Annullare sia la selezione sia la conferma: nessun messaggio deve partire.
- Inviare al numero di test e controllare il contenuto effettivamente ricevuto.
- Importare una seconda configurazione: Annulla conserva la prima; confermare
  la sostituisce. Verificare anche JSON malformato, versione errata e campi mancanti.
- Verificare il flusso da un altro iPhone/account dopo la condivisione: la
  configurazione dell’autore non deve essere inclusa nella shortcut condivisa.

## Pubblicazione

1. In Comandi Rapidi condividere **GSM Remote** → **Copia link iCloud**.
   La shortcut deve contenere soltanto la logica e il percorso del file, nessun
   numero o SMS personale inserito come costante.
2. Inserire quel link in `installUrl` di `docs/ios-config.js`.
3. Mantenere allineato `shortcutName` al nome effettivo **GSM Remote**.
4. Pubblicare `docs/` tramite il normale flusso GitHub Pages.

Il sito abilita il link d’installazione e il passaggio in Comandi Rapidi soltanto
quando è presente un link iCloud nel formato previsto. Prima di allora permette
copia e download delle impostazioni, spiegando che l’installazione non è disponibile.
L’apertura usa `input=clipboard`, così gli SMS lunghi non finiscono in URL enormi.
Se il browser nega l’accesso agli appunti, viene mostrato il testo da copiare a mano.
Dopo una modifica al modulo occorre ricopiare la configurazione.

Il file scaricato è JSON: non è una shortcut e non si installa toccandolo.
Per usarlo su iPhone copiarne tutto il testo negli appunti e avviare il link
all’importazione. Non rinominare il JSON in `.shortcut`.

## Riferimenti Apple

- [Eseguire una shortcut tramite URL e input clipboard](https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios)
- [Condividere shortcut tramite iCloud o file](https://support.apple.com/guide/shortcuts-mac/share-shortcuts-apdf01f8c054/mac)
