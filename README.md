# GSM Remote

App Flutter Android/iOS interamente locale, con quattro comandi personalizzabili.
I comandi aprono il **compositore SMS nativo** con destinatario e testo compilati:
l'utente preme Invio nella schermata di sistema. Non servono account o backend.
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
Non è imposto un limite di 160 caratteri: codifica, segmentazione e scelta della
SIM vengono gestite dal compositore di sistema.

## Scaricare e installare l'APK

1. Apri la pagina [Release di GSM Remote su GitHub](https://github.com/nicolotrebino/sms-remote/releases/latest).
2. Nella sezione **Assets**, scarica il file `.apk` della versione più recente. Il file `.sha1` contiene solo l'impronta di verifica e non installa l'app.
3. Apri l'APK scaricato sul telefono Android e conferma l'installazione. Se richiesto, autorizza temporaneamente il browser o il file manager usato per scaricarlo a installare app sconosciute.

Se Android segnala che l'app proviene da una fonte esterna, verifica di aver scaricato l'APK dalla Release ufficiale indicata sopra prima di proseguire.

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
