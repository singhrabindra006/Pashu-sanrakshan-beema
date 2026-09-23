const { execFile } = require('child_process');

/**
 * Best-effort `adb reverse tcp:<port> tcp:<port>` so a phone on USB can reach
 * this API at http://127.0.0.1:<port> regardless of the laptop's Wi-Fi IPv4.
 * Silently skips when adb is missing or no device is attached.
 */
function adbReverse(port) {
  return new Promise((resolve) => {
    execFile(
      'adb',
      ['reverse', `tcp:${port}`, `tcp:${port}`],
      { timeout: 8000, windowsHide: true },
      (error, stdout, stderr) => {
        if (error) {
          const reason = (stderr || error.message || '').trim().split(/\r?\n/)[0];
          console.info(`[adb] USB reverse not set (${reason || 'adb unavailable'})`);
          resolve(false);
          return;
        }
        console.info(`[adb] USB phone can use http://127.0.0.1:${port}`);
        resolve(true);
      },
    );
  });
}

module.exports = { adbReverse };
