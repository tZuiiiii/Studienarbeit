#!/usr/bin/env python3
import rospy
import cv2
from sensor_msgs.msg import Image
from std_msgs.msg import String
from cv_bridge import CvBridge

class MoodDetectorIndustryCamera:
    def __init__(self):
        rospy.init_node('mood_detector')
        self.bridge = CvBridge()
        
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.smile_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_smile.xml')
        
        self.mood_pub = rospy.Publisher('/detected_mood', String, queue_size=10)
        
        self.image_sub = rospy.Subscriber('/pylon_camera_node/image_raw', Image, self.callback)

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