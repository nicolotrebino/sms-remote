# Telecomando SMS

App Flutter Android/iOS interamente locale, con quattro comandi personalizzabili.
I comandi aprono il **compositore SMS nativo** con destinatario e testo compilati:
l'utente preme Invio nella schermata di sistema. Non servono account o backend.
La UI ha quattro accenti di colore e segue il tema chiaro/scuro di sistema.

## Avvio

Con Flutter stable installato e un dispositivo/emulatore disponibile:

```sh
flutter pub get
flutter run
```

Per iOS occorrono macOS e Xcode. Gli identificatori di progetto sono provvisori
(`com.example.sms_remote`); prima della distribuzione impostare gli identificatori
definitivi e la firma delle app. Le cartelle Android e iOS sono già generate.

## Utilizzo

Aprire l'ingranaggio nella Home, configurare il destinatario e i quattro comandi,
quindi premere **Salva impostazioni**. Ogni comando include nome, testo SMS e
interruttore di conferma. Puoi scegliere anche una delle cinque icone e uno dei sei
colori proposti per ciascun pulsante. Premi **Salva impostazioni** per applicare
le scelte alla Home e conservarle al riavvio. Le configurazioni precedenti
mantengono i colori; le icone ritirate vengono sostituite automaticamente:
accensione → regolazione, energia → luce, messaggio → melodia, porta → serratura. La Home ha esattamente quattro pulsanti comando grandi;
la navigazione alle impostazioni avviene dalla barra superiore.

Il numero accetta 3–15 cifre, un `+` iniziale facoltativo e separatori comuni
(spazi, trattini, parentesi), rimossi prima del salvataggio. Questa è una
validazione sintattica, non una verifica dell'esistenza del numero. I nomi sono
obbligatori e limitati a 40 caratteri. Il testo SMS non può essere vuoto o composto
solo da spazi; gli spazi e gli a capo del testo vengono conservati esattamente.
Non è imposto un limite di 160 caratteri: codifica, segmentazione e scelta della
SIM vengono gestite dal compositore di sistema.

## Struttura

```text
lib/
  main.dart
  models/
    app_settings.dart
    command_button_config.dart
  screens/
    home_screen.dart
    settings_screen.dart
  services/
    storage_service.dart
    sms_service.dart
  widgets/
    command_button.dart
    command_button_style.dart
```

`StorageService` salva un documento JSON versionato tramite
[`shared_preferences`](https://pub.dev/packages/shared_preferences), unica
dipendenza applicativa oltre a Flutter, usando `SharedPreferencesAsync`.
Nessun backend, database remoto o sincronizzazione applicativa. Il backup Android
è disabilitato nel manifest principale. I dati mancanti producono quattro comandi
iniziali; dati illeggibili o errori di lettura vengono segnalati senza sovrascrivere
silenziosamente la configurazione. Un errore di salvataggio mantiene le modifiche
nell'editor e la configurazione precedente nella Home.

## Invio SMS nativo

`SmsService.send` usa un `MethodChannel` (`sms_remote/sms`), senza nuovi pacchetti:

- **Android:** `ACTION_SENDTO` con `smsto:` e `sms_body` apre l'app SMS.
  Il risultato `opened` indica solo l'apertura: Android non restituisce un esito
  affidabile di invio da questo flusso. L'app non mostra quindi “SMS inviato”.
- **iOS:** `MFMessageComposeViewController` presenta il compositore di sistema e
  restituisce invio accettato, annullamento o errore. L'invio accettato non è una
  ricevuta di consegna. iOS richiede l'interazione dell'utente per inviare.

L'interruttore **Chiedi conferma** controlla il riepilogo interno prima di aprire
il compositore; disattivarlo non elimina la conferma di invio del sistema.
I pulsanti sono bloccati durante la richiesta per evitare aperture sovrapposte.
Dispositivi senza supporto SMS e assenza dell'app SMS mostrano un errore gestito.
Il testo viene passato direttamente alle API native: spazi, a capo e caratteri
speciali non subiscono codifiche URL. Nessun permesso `SEND_SMS` o accesso a rubrica
e messaggi ricevuti è richiesto.

Per SMS tradizionali serve un dispositivo con servizio telefonico SMS attivo;
si applicano le tariffe dell'operatore. L'app non usa Internet; il compositore di
sistema può scegliere iMessage/RCS in base alle impostazioni del dispositivo.
Per comandare un dispositivo che accetta solo SMS, verificare che il compositore
utilizzi SMS. Questa implementazione non forza il trasporto né invia in background.

Riferimenti: [Android messaging intents](https://developer.android.com/guide/components/intents-common#Messaging),
[Apple MessageUI](https://developer.apple.com/documentation/messageui/mfmessagecomposeviewcontroller).

Non sono necessarie connessioni Internet per usare l'app. Il download dell'SDK e
delle dipendenze durante lo sviluppo richiede la rete; il permesso Internet nei
manifest Android debug/profile generati da Flutter serve agli strumenti di debug,
mentre il manifest principale non lo richiede.

## Verifiche

```sh
dart format lib test
flutter analyze
flutter test
```

I test coprono persistenza tramite uno storage in memoria, dati corrotti,
validazione, aggiornamento della Home, conferme, errori di salvataggio,
annullamento modifiche e layout su schermo piccolo con testo ingrandito e tema
scuro, oltre al contratto del canale nativo (testo esatto, esiti ed errori).
I test automatici non inviano SMS reali.

Dopo modifiche al codice Kotlin/Swift serve un riavvio completo (`flutter run`),
non basta hot reload. Su telefoni reali verificare:

1. Compilazione esatta di destinatario e testo per ciascuno dei quattro comandi.
2. Conferma attiva/disattiva, annullamento e ritorno alla Home.
3. Invio a un numero di prova controllato e ricezione effettiva.
4. Comportamento senza servizio SMS e, su Android, selezione SIM se presente.

La build iOS e la prova su iPhone richiedono macOS/Xcode; il simulatore non è
sufficiente per verificare la consegna SMS.


## Branding e icone applicazione

Il marchio orizzontale trasparente `assets/images/trebino.png` è integrato
nella barra compatta della Home, sullo stesso sfondo del contenuto, accanto
all'accesso alle impostazioni. Gli accenti del tema riprendono l'oro Trebino;
i colori personalizzati dei comandi rimangono invariati.
Le icone comando disponibili sono Melodia, Regolazione, Luce, Serratura e Casa.

Le icone native Android (anche adattive) e iOS sono generate da
`assets/images/trebino_icon.png`, centrato senza deformazioni su fondo avorio.
I file sorgente non vengono modificati. Per rigenerarle con ImageMagick installato:

```sh
python3 tool/generate_app_icons.py
```

Le dimensioni del livello adattivo seguono la
[guida Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
L'icona di lancio è una risorsa nativa e non richiede registrazione in `pubspec.yaml`.
Dopo la modifica serve ricompilare e aggiornare l'app installata; hot reload non
aggiorna l'icona nel launcher.
