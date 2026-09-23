const fs = require('fs');
const path = require('path');
const { primaryLanIPv4, lanIPv4s } = require('../src/core/utils/lanAddresses');

const port = Number(process.env.PORT || 4000);
const ip = primaryLanIPv4();
const payload = {
  API_BASE_URL: `http://${ip}:${port}/api/v1`,
};

const dest = path.resolve(__dirname, '..', '.vscode-api.json');
fs.writeFileSync(dest, `${JSON.stringify(payload, null, 2)}\n`);
console.info(`[api] wrote ${dest}`);
console.info(`[api] phone-on-Wi-Fi URL: ${payload.API_BASE_URL}`);
for (const extra of lanIPv4s().filter((value) => value !== ip)) {
  console.info(`[api] also on this PC: http://${extra}:${port}/api/v1`);
}
