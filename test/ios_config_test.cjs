const { test } = require('node:test');
const assert = require('node:assert/strict');
const { buildIOSConfiguration } = require('../docs/ios-config-core.js');
const commands = ['Melodia', 'Luce', 'Chiesa', '__proto__'].map(name => ({name, message: '  À "&+"\nON  '}));
test('normalizza il numero, preserva testo e chiavi senza alterazioni nel JSON', () => {
  const config = JSON.parse(JSON.stringify(buildIOSConfiguration('+39 (333) 123-4567', commands)));
  assert.equal(config.phone, '+393331234567');
  assert.equal(config.version, 1);
  assert.deepEqual(config.names, commands.map(c => c.name));
  commands.forEach(c => assert.equal(config.messages[c.name], c.message));
});
test('rifiuta numeri non validi', () => {
  for (const phone of ['12', '1234567890123456', '12+345', '+39abc123', '']) {
    assert.throws(() => buildIOSConfiguration(phone, commands));
  }
});
test('rifiuta nomi duplicati o vuoti, messaggi vuoti e numero errato di comandi', () => {
  assert.throws(() => buildIOSConfiguration('123', commands.slice(1)));
  for (const replacement of [{name:' ', message:'ON'}, {name:'Luce', message:'ON'}, {name:'x'.repeat(41), message:'ON'}, {name:'Valido', message:' \n '}]) {
    assert.throws(() => buildIOSConfiguration('123', [replacement, ...commands.slice(1)]));
  }
});
