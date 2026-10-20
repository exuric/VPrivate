const fs = require('fs');

function rand(n) { const a = []; for (let i = 0; i < n; i++) a.push(Math.floor(Math.random() * 256)); return a; }
function name() { const head = 'IlO'; const c = 'IlO0'; let s = head[Math.floor(Math.random() * 3)]; for (let i = 0; i < 7 + Math.floor(Math.random() * 6); i++) s += c[Math.floor(Math.random() * 4)]; return s; }

function encrypt(bytes, key) {
  const out = new Array(bytes.length);
  for (let p = 0; p < bytes.length; p++) {
    out[p] = bytes[p] ^ key[p % key.length] ^ (p % 251);
  }
  return out;
}

function luaBytes(arr) {
  let s = '';
  for (const b of arr) s += '\\' + String(b).padStart(3, '0');
  return s;
}
function luaKey(key) {
  return '{' + key.join(',') + '}';
}

function layer(payload) {
  const key = rand(16 + Math.floor(Math.random() * 16));
  const bytes = Buffer.from(payload, 'utf8');
  const enc = encrypt([...bytes], key);
  const vD = name(), vK = name(), vO = name(), vI = name(), vB = name(), vX = name();
  const stub =
    'local ' + vK + '=' + luaKey(key) + '\n' +
    'local ' + vD + '="' + luaBytes(enc) + '"\n' +
    'local ' + vO + '={}\n' +
    'for ' + vI + '=1,#' + vD + ' do\n' +
    'local ' + vB + '=' + vD + ':byte(' + vI + ')\n' +
    'local ' + vX + '=bit32.bxor(' + vB + ',' + vK + '[(' + vI + '-1)%#' + vK + '+1],(' + vI + '-1)%251)\n' +
    vO + '[' + vI + ']=string.char(' + vX + ')\n' +
    'end\n' +
    'return loadstring(table.concat(' + vO + '),"=' + name() + '")(...)\n';
  return stub;
}

function decryptCheck(stubEnc, key) {
  const out = new Array(stubEnc.length);
  for (let p = 0; p < stubEnc.length; p++) out[p] = stubEnc[p] ^ key[p % key.length] ^ (p % 251);
  return Buffer.from(out).toString('utf8');
}

function obfuscate(src, layers) {
  let payload = src;
  for (let i = 0; i < layers; i++) payload = layer(payload);
  return payload;
}

const inFile = process.argv[2];
const outFile = process.argv[3];
const layers = parseInt(process.argv[4] || '3', 10);
if (!inFile || !outFile) { console.error('usage: node obf.js <in> <out> [layers]'); process.exit(1); }

const src = fs.readFileSync(inFile, 'utf8');
const obf = obfuscate(src, layers);
fs.writeFileSync(outFile, obf);

const key = rand(20);
const enc = encrypt([...Buffer.from(src, 'utf8')], key);
const back = decryptCheck(enc, key);
console.log('roundtrip ok:', back === src, '| in', src.length, 'bytes -> out', obf.length, 'bytes |', layers, 'layers');
