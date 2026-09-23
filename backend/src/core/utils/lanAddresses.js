const os = require('os');

function isWifiName(name) {
  return /wi-?fi|wlan|wireless|wi fi/i.test(name);
}

/** Non-loopback IPv4 addresses on this machine (changes when Wi-Fi changes). */
function lanIPv4s() {
  const wifi = [];
  const other = [];
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      const family = net.family === 4 || net.family === 'IPv4';
      if (!family || net.internal || !net.address) continue;
      if (isWifiName(name)) wifi.push(net.address);
      else other.push(net.address);
    }
  }
  return [...new Set([...wifi, ...other])];
}

function primaryLanIPv4() {
  return lanIPv4s()[0] || '127.0.0.1';
}

module.exports = { lanIPv4s, primaryLanIPv4 };
