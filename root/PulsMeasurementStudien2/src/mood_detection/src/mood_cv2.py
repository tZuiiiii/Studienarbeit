import rospy
import cv2
from std_msgs.msg import String
from sensor_msgs.msg import Image
from cv_bridge import CvBridge, CvBridgeError

class MoodDetector:
    def __init__(self):
        rospy.init_node('mood_detector', anonymous=True)
        
        self.mood_pub = rospy.Publisher('/mood', String, queue_size=10)
        
        self.bridge = CvBridge()
        
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.smile_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_smile.xml')

        self.image_sub = rospy.Subscriber("/webcam/image_raw", Image, self.image_callback)
        
        print("Mood Detection waiting for pictures... (Headless mode)")

    def image_callback(self, data):
        try:
            frame = self.bridge.imgmsg_to_cv2(data, "bgr8")
        except CvBridgeError as e:
            print(f"Error during image conversion: {e}")
            return

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
        
        status = "Neutral"
        
        for (x, y, w, h) in faces:
            roi_gray = gray[y:y+h, x:x+w]
            
            smiles = self.smile_cascade.detectMultiScale(roi_gray, 1.8, 20)
            
            if len(smiles) > 0:
                status = "Smiling"

        self.mood_pub.publish(status)

if __name__ == '__main__':
    try:
        md = MoodDetector()
        rospy.spin()
    except KeyboardInterrupt:
        print("Shutdown...")