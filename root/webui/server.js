const express = require('express');
const { exec, spawn } = require('child_process');
const app = express();
const port = 3000;

let rosProcess = null;

app.use(express.static('public'));

app.get('/startHeadMovement', (req, res) => {
    if (!rosProcess) {
        rosProcess = spawn('bash', ['-c', 'source ../PulsMeasurementStudien2/start_head_movement.sh']);
        
        rosProcess.stdout.on('data', (data) => console.log(`ROS: ${data}`));
        rosProcess.stderr.on('data', (data) => console.error(`ROS Error: ${data}`));

        res.send({ status: "Puls-Messung gestartet" });
    } else {
        res.send({ status: "Läuft bereits" });
    }
});

app.get('/startEulerianMotion', (req, res) => {
    if (!rosProcess) {
        rosProcess = spawn('bash', ['-c', 'source ../PulsMeasurementStudien2/start_eulerian_motion.sh']);
        
        rosProcess.stdout.on('data', (data) => console.log(`ROS: ${data}`));
        rosProcess.stderr.on('data', (data) => console.error(`ROS Error: ${data}`));

        res.send({ status: "Puls-Messung gestartet" });
    } else {
        res.send({ status: "Läuft bereits" });
    }
});

app.get('/startLegacyMeasurement', (req, res) => {
    if (!rosProcess) {
        rosProcess = spawn('bash', ['-c', 'source ../PulsMeasurementStudien2/start_legacy_measurement.sh']);
        
        rosProcess.stdout.on('data', (data) => console.log(`ROS: ${data}`));
        rosProcess.stderr.on('data', (data) => console.error(`ROS Error: ${data}`));

        res.send({ status: "Puls-Messung gestartet" });
    } else {
        res.send({ status: "Läuft bereits" });
    }
});

app.get('/stop', (req, res) => {
    if (rosProcess) {
        exec('pkill -f roslaunch', (err) => {
            rosProcess = null;
            res.send({ status: "System gestoppt" });
        });
    } else {
        res.send({ status: "Nichts aktiv" });
    }
});

app.listen(port, () => {
    console.log(`Smart Mirror Server läuft auf http://localhost:${port}`);
    
    const startServer = (process.platform === 'darwin' ? 'open' : process.platform === 'win32' ? 'start' : 'xdg-open');
    exec(`${startServer} http://localhost:${port}`);
});