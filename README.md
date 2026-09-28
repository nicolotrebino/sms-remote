# GSM Remote

App Flutter per Android, interamente locale, con quattro comandi personalizzabili.
I comandi inviano SMS direttamente dal dispositivo senza aprire l'app Messaggi.
Al primo invio Android chiede il permesso di invio SMS; ogni comando mantiene la
propria opzione di conferma. Un feedback conferma che Android ha affidato il
messaggio alla rete, ma non conferma la consegna al destinatario. Non servono
account o backend.
La UI ha quattro accenti di colore e segue il tema chiaro/scuro di sistema.

## Utilizzo

Aprire l'ingranaggio nella Home, configurare il destinatario e i quattro comandi,
quindi premere **Salva impostazioni**. Ogni comando include nome, testo SMS e
interruttore di conferma. Puoi scegliere anche una delle cinque icone e uno dei quattro
colori proposti per ciascun pulsante. Premi **Salva impostazioni** per applicare
le scelte alla Home e conservarle al riavvio. Le configurazioni precedenti
mantengono i colori; le icone ritirate vengono sostituite automaticamente:
accensione/regolazione/casa/porta → chiesa, energia → luce, messaggio → melodia, serratura → martello. I colori corallo e rosa diventano ambra e viola. La Home ha esattamente quattro pulsanti comando grandi;
la navigazione alle impostazioni avviene dalla barra superiore.

Il numero accetta 3–15 cifre, un `+` iniziale facoltativo e separatori comuni
(spazi, trattini, parentesi), rimossi prima del salvataggio. Questa è una
validazione sintattica, non una verifica dell'esistenza del numero. I nomi sono
obbligatori e limitati a 40 caratteri. Il testo SMS non può essere vuoto o composto
solo da spazi; gli spazi e gli a capo del testo vengono conservati esattamente.
Non è imposto un limite di 160 caratteri: Android divide automaticamente i
messaggi lunghi in più parti. Su dispositivi dual SIM va selezionata una SIM
predefinita per gli SMS nelle impostazioni Android. Si applicano le tariffe del
proprio operatore.

## Scaricare e installare l'APK

1. Apri la pagina [Release di GSM Remote su GitHub](https://github.com/nicolotrebino/sms-remote/releases/latest).
2. Nella sezione **Assets**, scarica il file `.apk` della versione più recente. Il file `.sha1` contiene solo l'impronta di verifica e non installa l'app.
3. Apri l'APK scaricato sul telefono Android e conferma l'installazione. Se richiesto, autorizza temporaneamente il browser o il file manager usato per scaricarlo a installare app sconosciute.

Se Android segnala che l'app proviene da una fonte esterna, verifica di aver scaricato l'APK dalla Release ufficiale indicata sopra prima di proseguire.

## Sito web GitHub Pages

La pagina di download è in `docs/` e punta all'APK della release 1.1.0. Per
pubblicarla, apri [Settings → Pages](https://github.com/nicolotrebino/sms-remote/settings/pages)
nel repository GitHub, scegli **Deploy from a branch**, seleziona il branch
`main` e la cartella `/docs`, quindi salva.
GitHub pubblicherà la pagina su
https://nicolotrebino.github.io/sms-remote/ e aggiornerà il sito a ogni push sul
branch selezionato. Per le release future aggiorna anche il link all'APK in
`docs/index.html` se cambia il nome del file.

## iPhone: Comandi Rapidi

GitHub Pages include i tab Android e iOS, selezionati automaticamente in base
al dispositivo (Android come predefinito su desktop). Il modulo iOS prepara un
numero destinatario e quattro comandi con nomi distinti e testi SMS. La
configurazione può essere copiata o scaricata come JSON; non è un file installabile.

Il flusso previsto è: installare **GSM Remote** da iCloud, compilare il modulo,
copiare e importare la configurazione, quindi avviare il telecomando dalla Home
o da Comandi Rapidi. La shortcut presenta una lista di quattro voci e richiede
conferma per l’invio. I dati personali sono salvati nel proprio iCloud Drive.

**Da completare su un dispositivo Apple:** creare e collaudare la shortcut
seguendo [ios/SETUP.md](ios/SETUP.md), condividerla e inserire il link iCloud in
`docs/ios-config.js`. Finché il link manca, il sito segnala che l’installazione
non è disponibile e non abilita l’importazione. Nessuna shortcut firmata viene
generata da GitHub Pages.

Verifica del formato e della validazione: `node --test test/ios_config_test.cjs`.

## Licenza

GSM Remote è disponibile gratuitamente per uso personale o interno, alle
condizioni della [licenza proprietaria](LICENSE). La vendita, la distribuzione
commerciale, il rebranding e la distribuzione di versioni modificate richiedono
l'autorizzazione scritta del titolare dei diritti. Le librerie e gli altri
materiali di terzi mantengono le proprie licenze e condizioni.

La licenza non elimina le funzionalità di visualizzazione e fork che GitHub
prevede per i repository pubblici nei propri Termini di servizio; non concede
però altri diritti d'uso sul codice. Prima della pubblicazione, sostituisci il
segnaposto del titolare in `LICENSE` con il titolare effettivo dei diritti e
verifica di poter applicare queste condizioni a tutti i materiali inclusi.
