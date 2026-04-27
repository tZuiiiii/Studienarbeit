const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const port = Number(process.env.PORT || 3001);
const rosWorkspace = path.resolve(__dirname, '..', 'PulsMeasurementStudien2');
const startScript = path.join(rosWorkspace, 'start_mood_detection.sh');

let rosStackProcess = null;
let rosStackStartedAt = null;
let rosStackExit = null;
let kioskProcess = null;

app.use(express.static(path.join(__dirname, 'public')));

const roslibBuildPath = path.join(__dirname, 'node_modules', 'roslib', 'build');
if (fs.existsSync(roslibBuildPath)) {
  app.use('/vendor/roslib', express.static(roslibBuildPath));
}

function attachLogs(child, label) {
  child.stdout.on('data', (data) => process.stdout.write(`[${label}] ${data}`));
  child.stderr.on('data', (data) => process.stderr.write(`[${label} error] ${data}`));
}

function startRosStack() {
  if (rosStackProcess) {
    return { started: false, status: 'ROS stack already running' };
  }

  if (!fs.existsSync(startScript)) {
    rosStackExit = {
      code: null,
      signal: null,
      message: `Start script not found: ${startScript}`
    };
    console.error(rosStackExit.message);
    return { started: false, status: rosStackExit.message };
  }

  rosStackExit = null;
  rosStackStartedAt = new Date().toISOString();
  rosStackProcess = spawn('bash', [startScript], {
    cwd: rosWorkspace,
    env: process.env,
    detached: false
  });

  attachLogs(rosStackProcess, 'ros-stack');

  rosStackProcess.on('close', (code, signal) => {
    rosStackExit = {
      code,
      signal,
      message: `ROS stack stopped with code ${code} signal ${signal || '-'}`
    };
    console.log(rosStackExit.message);
    rosStackProcess = null;
  });

  return { started: true, status: 'ROS stack started' };
}

function stopRosStack() {
  if (!rosStackProcess) {
    return false;
  }

  rosStackProcess.kill('SIGTERM');
  return true;
}

function browserCommand() {
  const url = `http://localhost:${port}`;
  const browser = process.env.BROWSER || findBrowser();
  const kioskEnabled = process.env.KIOSK !== '0';

  if (!browser) {
    return null;
  }

  if (browser.includes('firefox')) {
    return {
      command: browser,
      args: kioskEnabled ? ['--kiosk', url] : [url]
    };
  }

  if (browser === 'xdg-open') {
    return {
      command: browser,
      args: [url]
    };
  }

  return {
    command: browser,
    args: kioskEnabled ? [
      '--kiosk',
      '--noerrdialogs',
      '--disable-infobars',
      '--disable-session-crashed-bubble',
      '--autoplay-policy=no-user-gesture-required',
      url
    ] : [url]
  };
}

function commandExists(command) {
  const paths = (process.env.PATH || '').split(path.delimiter);
  return paths.some((entry) => fs.existsSync(path.join(entry, command)));
}

function findBrowser() {
  return [
    'firefox',
    'firefox-esr',
    'chromium-browser',
    'chromium',
    'google-chrome',
    'xdg-open'
  ].find(commandExists);
}

function startKioskBrowser() {
  if (process.env.OPEN_BROWSER === '0' || kioskProcess) {
    return;
  }

  const browser = browserCommand();
  if (!browser) {
    console.warn('Kiosk browser not started: no supported browser found. Set BROWSER=firefox or install Chromium.');
    return;
  }

  const { command, args } = browser;
  kioskProcess = spawn(command, args, {
    detached: true,
    stdio: 'ignore'
  });
  kioskProcess.on('error', (error) => {
    console.error(`Kiosk browser failed to start (${command}): ${error.message}`);
    kioskProcess = null;
  });
  kioskProcess.unref();
  console.log(`Kiosk browser started: ${command} ${args.join(' ')}`);
}

app.get('/api/status', (req, res) => {
  res.json({
    rosStackRunning: Boolean(rosStackProcess),
    rosStackStartedAt,
    rosStackExit,
    rosbridgeUrl: `ws://${req.hostname}:9090`,
    pulseTopic: '/heart_rate',
    moodTopic: '/mood'
  });
});

app.post('/api/start', (req, res) => {
  res.json(startRosStack());
});

app.post('/api/stop', (req, res) => {
  res.json({
    stopped: stopRosStack()
  });
});

app.listen(port, () => {
  console.log(`Smart Mirror Kiosk WebUI running on http://localhost:${port}`);
  startRosStack();
  startKioskBrowser();
});

function shutdown(signal) {
  console.log(`Received ${signal}, shutting down`);
  stopRosStack();
  setTimeout(() => process.exit(0), 1500);
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
