const express = require('express');
const { exec, spawn } = require('child_process');
const app = express();
const port = 3000;

let rosProcess = null;
let moodProcess = null; 

app.use(express.static('public'));

app.get('/startHeadMovement', (req, res) => {
    if (!rosProcess) {
        rosProcess = spawn('bash', ['-c', 'source ../PulsMeasurementStudien2/start_head_movement.sh']);
        
        rosProcess.stdout.on('data', (data) => console.log(`ROS: ${data}`));
        rosProcess.stderr.on('data', (data) => console.error(`ROS Error: ${data}`));

        res.send({ status: "Pulse measurement started" });
    } else {
        res.send({ status: "ROS process already running" });
    }
});

app.get('/startEulerianMotion', (req, res) => {
    if (!rosProcess) {
        rosProcess = spawn('bash', ['-c', 'source ../PulsMeasurementStudien2/start_eulerian_motion.sh']);
        
        rosProcess.stdout.on('data', (data) => console.log(`ROS: ${data}`));
        rosProcess.stderr.on('data', (data) => console.error(`ROS Error: ${data}`));

        res.send({ status: "Pulse measurement started" });
    } else {
        res.send({ status: "ROS process already running" });
    }
});

app.get('/startLegacyMeasurement', (req, res) => {
    if (!rosProcess) {
        rosProcess = spawn('bash', ['-c', 'source ../PulsMeasurementStudien2/start_legacy_measurement.sh']);
        
        rosProcess.stdout.on('data', (data) => console.log(`ROS: ${data}`));
        rosProcess.stderr.on('data', (data) => console.error(`ROS Error: ${data}`));

        res.send({ status: "Pulse measurement started" });
    } else {
        res.send({ status: "ROS process already running" });
    }
});

app.get('/startMoodDetection', (req, res) => {
    if (!moodProcess) {
        moodProcess = spawn('bash', ['-c', 'source ../PulsMeasurementStudien2/start_mood_detection.sh']);
        
        moodProcess.stdout.on('data', (data) => console.log(`Mood Detection: ${data}`));
        moodProcess.stderr.on('data', (data) => console.error(`Mood Detection Error: ${data}`));

        moodProcess.on('close', (code) => {
            console.log(`Mood detection stopped (Code: ${code})`);
            moodProcess = null;
        });

        res.send({ status: "Mood detection started" });
    } else {
        res.send({ status: "Mood detection already running" });
    }
});

app.get('/stop', (req, res) => {
    let stoppedSomething = false;

    if (rosProcess) {
        exec('pkill -f roslaunch');
        rosProcess = null;
        stoppedSomething = true;
    }

    if (moodProcess) {
        exec('pkill -f mood_cv2.py'); 
        moodProcess = null;
        stoppedSomething = true;
    }

    if (stoppedSomething) {
        res.send({ status: "All systems stopped" });
    } else {
        res.send({ status: "Nothing active" });
    }
});

app.listen(port, () => {
    console.log(`Smart Mirror Server running on http://localhost:${port}`);
    
    const startServer = (process.platform === 'darwin' ? 'open' : process.platform === 'win32' ? 'start' : 'xdg-open');
    exec(`${startServer} http://localhost:${port}`);
});