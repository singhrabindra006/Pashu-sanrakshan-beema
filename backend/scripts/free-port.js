const { execSync } = require('child_process');

const port = Number(process.env.PORT || 4000);

function listeningPids(listenPort) {
  if (process.platform === 'win32') {
    try {
      const out = execSync(`netstat -ano | findstr :${listenPort}`, { encoding: 'utf8' });
      const pids = new Set();
      for (const line of out.split(/\r?\n/)) {
        if (!/LISTENING/i.test(line)) continue;
        const parts = line.trim().split(/\s+/);
        const pid = Number(parts[parts.length - 1]);
        if (pid && pid !== process.pid) pids.add(pid);
      }
      return [...pids];
    } catch {
      return [];
    }
  }

  try {
    const out = execSync(`lsof -ti tcp:${listenPort} -sTCP:LISTEN`, { encoding: 'utf8' });
    return out
      .split(/\s+/)
      .map((value) => Number(value))
      .filter((pid) => pid && pid !== process.pid);
  } catch {
    return [];
  }
}

function killPid(pid) {
  if (process.platform === 'win32') {
    execSync(`taskkill /PID ${pid} /F`, { stdio: 'ignore' });
    return;
  }
  execSync(`kill -9 ${pid}`, { stdio: 'ignore' });
}

const pids = listeningPids(port);
for (const pid of pids) {
  try {
    killPid(pid);
    console.info(`[port] freed ${port} (stopped pid ${pid})`);
  } catch (error) {
    console.warn(`[port] could not stop pid ${pid}: ${error.message}`);
  }
}

if (pids.length === 0) {
  console.info(`[port] ${port} is free`);
}
