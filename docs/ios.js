"use strict";

const defaultNames = ["Melodia", "Luce", "Chiesa", "Distesa"];
const tabs = [...document.querySelectorAll('[role="tab"]')];
const previewNames = [...document.querySelectorAll(".command-name")];
const previewMessages = previewNames.map((name) => {
  const message = document.createElement("span");
  message.className = "command-message";
  name.after(message);
  return message;
});
const fields = document.querySelector("#ios-commands");
defaultNames.forEach((name, index) => {
  const fieldset = document.createElement("fieldset");
  fieldset.innerHTML = `<legend>Comando ${index + 1}</legend>
    <label for="name-${index}">Nome del pulsante</label>
    <input id="name-${index}" name="name-${index}" maxlength="40" required>
    <label for="message-${index}">Testo SMS</label>
    <textarea id="message-${index}" name="message-${index}" rows="2" required placeholder="Inserisci il comando esatto del dispositivo"></textarea>`;
  fieldset.querySelector("input").value = name;
  fields.append(fieldset);
});

function updatePreview() {
  const ios = !document.querySelector("#panel-ios").hidden;
  previewNames.forEach((name, index) => {
    name.textContent = ios ? document.querySelector(`#name-${index}`).value : defaultNames[index];
    previewMessages[index].textContent = ios ? document.querySelector(`#message-${index}`).value : "";
  });
}

function selectPlatform(platform) {
  tabs.forEach((tab) => {
    const selected = tab.id === `tab-${platform}`;
    tab.setAttribute("aria-selected", String(selected));
    tab.tabIndex = selected ? 0 : -1;
    document.getElementById(tab.getAttribute("aria-controls")).hidden = !selected;
  });
  document.querySelector(".release-tag").textContent = platform === "ios" ? "iOS · Comandi Rapidi" : "Android · 1.1.0";
  updatePreview();
}

tabs.forEach((tab, index) => {
  tab.addEventListener("click", () => selectPlatform(tab.id.slice(4)));
  tab.addEventListener("keydown", (event) => {
    if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
    event.preventDefault();
    const next = event.key === "Home" ? tabs[0] : event.key === "End" ? tabs[1] : tabs[1 - index];
    next.click();
    next.focus();
  });
});

const form = document.querySelector("#ios-form");
const status = document.querySelector("#ios-status");
const importLink = document.querySelector("#ios-import");
const importHelp = document.querySelector("#ios-import-help");
const manualCopy = document.querySelector("#ios-manual-copy");
const jsonField = document.querySelector("#ios-json");
const installAvailable = /^https:\/\/www\.icloud\.com\/shortcuts\/[a-f0-9]{32}$/i.test(GSM_IOS.installUrl);
if (installAvailable) {
  const installLink = document.querySelector("#ios-install");
  installLink.href = GSM_IOS.installUrl;
  installLink.hidden = false;
  document.querySelector("#ios-unavailable").hidden = true;
}
importLink.href = `shortcuts://run-shortcut?name=${encodeURIComponent(GSM_IOS.shortcutName)}&input=clipboard`;

function configurationText() {
  if (!form.reportValidity()) return null;
  try {
    return JSON.stringify(buildIOSConfiguration(document.querySelector("#ios-phone").value,
      defaultNames.map((_, index) => ({
        name: document.querySelector(`#name-${index}`).value,
        message: document.querySelector(`#message-${index}`).value,
      }))), null, 2);
  } catch (error) {
    status.textContent = error.message;
    return null;
  }
}

let revision = 0;
form.addEventListener("submit", async (event) => {
  event.preventDefault();
  importLink.hidden = importHelp.hidden = true;
  manualCopy.hidden = true;
  const text = configurationText();
  if (text === null) return;
  const currentRevision = revision;
  try {
    await navigator.clipboard.writeText(text);
    if (currentRevision !== revision) return;
    status.textContent = installAvailable
      ? "Configurazione copiata. Dopo aver installato GSM Remote, tocca Importa in Comandi Rapidi."
      : "Configurazione copiata. L’importazione sarà disponibile quando verrà pubblicato il Comando Rapido.";
  } catch {
    if (currentRevision !== revision) return;
    jsonField.value = text;
    manualCopy.hidden = false;
    jsonField.focus();
    jsonField.select();
    status.textContent = "La copia automatica non è disponibile. Copia manualmente tutto il testo qui sotto prima di importare.";
  }
  importLink.hidden = importHelp.hidden = !installAvailable;
});

document.querySelector("#ios-download").addEventListener("click", () => {
  const text = configurationText();
  if (text === null) return;
  const url = URL.createObjectURL(new Blob([text], { type: "application/json;charset=utf-8" }));
  const link = document.createElement("a");
  link.href = url;
  link.download = "gsm-remote-config.json";
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 60000);
  status.textContent = "Download della configurazione avviato. Conserva il file: contiene numero e testi SMS personali.";
});

form.addEventListener("input", () => {
  revision += 1;
  importLink.hidden = importHelp.hidden = manualCopy.hidden = true;
  jsonField.value = "";
  status.textContent = "";
  updatePreview();
});
const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent)
  || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
selectPlatform(isIOS ? "ios" : "android");
