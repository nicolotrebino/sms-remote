"use strict";

function buildIOSConfiguration(phone, commands) {
  const normalizedPhone = phone.replace(/[\s()-]/g, "");
  if (!/^\+?[0-9]{3,15}$/.test(normalizedPhone)) {
    throw new Error("Inserisci un numero valido: da 3 a 15 cifre e un eventuale + iniziale.");
  }
  if (commands.length !== 4) throw new Error("Sono necessari quattro comandi.");
  const names = commands.map(({ name }) => name.trim());
  if (names.some((name) => !name || name.length > 40)) {
    throw new Error("Ogni nome deve contenere da 1 a 40 caratteri.");
  }
  if (new Set(names).size !== 4) throw new Error("Usa quattro nomi diversi per i comandi.");
  if (commands.some(({ message }) => !message.trim())) {
    throw new Error("Inserisci il testo SMS di tutti e quattro i comandi.");
  }
  return {
    version: 1,
    phone: normalizedPhone,
    names,
    messages: Object.fromEntries(commands.map(({ message }, index) => [names[index], message])),
  };
}

if (typeof module !== "undefined") module.exports = { buildIOSConfiguration };
