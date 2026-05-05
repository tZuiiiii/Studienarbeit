#!/usr/bin/env python3
import rospy
import cv2
from pathlib import Path
from sensor_msgs.msg import Image
from std_msgs.msg import String
from cv_bridge import CvBridge

def load_cascade(filename, fallback_repo_path=None):
    candidates = []
    if hasattr(cv2, 'data') and hasattr(cv2.data, 'haarcascades'):
        candidates.append(Path(cv2.data.haarcascades) / filename)
    if fallback_repo_path:
        candidates.append(Path(fallback_repo_path))
    candidates.extend([
        Path('/usr/share/opencv4/haarcascades') / filename,
        Path('/usr/share/opencv/haarcascades') / filename,
    ])

    for candidate in candidates:
        if candidate.exists():
            cascade = cv2.CascadeClassifier(str(candidate))
            if not cascade.empty():
                return cascade

    raise RuntimeError(f'Could not load cascade: {filename}')

class MoodDetectorIndustryCamera:
    def __init__(self):
        rospy.init_node('mood_detector')
        self.bridge = CvBridge()
        image_topic = rospy.get_param("~image_topic", "/pylon_camera_node/image_raw")
        
        repo_cascade = Path(__file__).resolve().parents[2] / 'common' / 'config' / 'cascade.xml'
        self.face_cascade = load_cascade('haarcascade_frontalface_default.xml', repo_cascade)
        self.smile_cascade = load_cascade('haarcascade_smile.xml')
        
        self.mood_pub = rospy.Publisher('/mood', String, queue_size=10)
        
        self.image_sub = rospy.Subscriber(image_topic, Image, self.callback)
        print(f"Mood Detection waiting for pictures on {image_topic}... (Headless mode)")

    def callback(self, data):
        frame = self.bridge.imgmsg_to_cv2(data, "bgr8")
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
        current_mood = "Neutral"

        for (x, y, w, h) in faces:
            roi_gray = gray[y:y+h, x:x+w]
            smiles = self.smile_cascade.detectMultiScale(roi_gray, 1.8, 20)
            if len(smiles) > 0:
                current_mood = "Happy"
        
        self.mood_pub.publish(current_mood)

if __name__ == '__main__':
    node = MoodDetectorIndustryCamera()
    rospy.spin()
