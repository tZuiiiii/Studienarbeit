import tkinter as tk
from PIL import Image, ImageTk
import os
import sys
from heart_rate_simulator import start_simulation as simulate_heart_rate
from moods import Mood
from mood_change_simulator import start_simulation as simulate_mood_change

# --- CONST ---
WIDTH = 1200
HEIGHT = 800
BACKGROUND_COLOR = "black"
HEART_COLOR = "white"
HEART_WIDTH = 6
BASE_RADIUS = 100
NUM_POINTS = 100
HEART_PNG = "assets/heart.png"

# --- PULSE CONST ---
BASE_IMG_SIZE = 200
MAX_SCALE_FACTOR = 1.15
STEP_DURATION_MS = 25
NUM_STEPS = 6
# --------------------

def _calculate_pulse_period(bpm):
    if bpm <= 0:
        return int(60_000 / 60)
    return int(60_000 / bpm)


class SmartMirrorUI(tk.Tk):
    def __init__(self):
        super().__init__()

        self.is_fullscreen = True
        self.title("Smart Mirror")
        self.geometry(f"{WIDTH}x{HEIGHT}")
        self.attributes("-fullscreen", self.is_fullscreen)
        self.configure(bg=BACKGROUND_COLOR)
        self.bind('<Escape>', self.toggle_fullscreen)

        self.original_img_pil = None
        self.heart_img_tk = None
        self.heart_png_canvas_id = None
        self.bpm_display_id = None

        self.bpm = 80
        self.pulse_period_ms = _calculate_pulse_period(self.bpm)
        self.animation_job_id = None
        self.simulation_job_id = None
        self.current_step = 0
        self.is_expanding = True
        self.pulse_center_x = 0
        self.pulse_center_y = 0

        self.canvas = tk.Canvas(self, bg=BACKGROUND_COLOR, highlightthickness=0)
        self.canvas.pack(fill="both", expand=True)

        self.current_mood = None
        self.mood_simulation_job_id = None
        self.image_label = tk.Label(self)
        self.image_label.pack(pady=20)
        self.mood_png_canvas_id = None

        for mood in Mood:
            tk.Button(self,
                      text=f"{mood.name}",
                      command=lambda m=mood: self.update_mood_image(m)
                      ).pack(side=tk.RIGHT, padx=5)

        self.canvas.after(50, self.setup_ui)

    def toggle_fullscreen(self, event=None):
        self.is_fullscreen = not self.is_fullscreen
        self.attributes('-fullscreen', self.is_fullscreen)

    def update_mood_image(self, mood: Mood):
        img = Image.open(mood.value).resize((BASE_IMG_SIZE, BASE_IMG_SIZE), Image.LANCZOS)
        mood = ImageTk.PhotoImage(img)

        self.current_mood = mood

        width = self.canvas.winfo_width()
        height = self.canvas.winfo_height()

        self.mood_png_canvas_id = self.canvas.create_image(
            width - (width / 8),
            height / 4,
            image=self.current_mood,
            anchor="center"
        )
        self.image_label.image = self.current_mood

    def set_bpm(self, new_bpm):
        if self.bpm == new_bpm or new_bpm <= 0:
            return

        self.bpm = new_bpm
        self.pulse_period_ms = _calculate_pulse_period(new_bpm)

        self.canvas.itemconfig(self.bpm_display_id, text=f"{self.bpm}")

        if self.animation_job_id:
            self.after_cancel(self.animation_job_id)

        self.current_step = 0
        self.is_expanding = True
        self.start_pulse()

    def load_base_image(self):
        if getattr(sys, 'frozen', False):
            base_path = sys._MEIPASS
        else:
            base_path = os.path.dirname(os.path.abspath(__file__))

        png_path = os.path.join(base_path, HEART_PNG)

        try:
            self.original_img_pil = Image.open(png_path).resize(
                (BASE_IMG_SIZE, BASE_IMG_SIZE), Image.LANCZOS
            )
            return True
        except FileNotFoundError:
            print(f"Error: Image '{png_path}' not found.")
            return False

    def animate_pulse(self):
        if not self.original_img_pil:
            return

        max_scale_range = MAX_SCALE_FACTOR - 1.0

        if self.is_expanding:
            scale_progress = self.current_step / NUM_STEPS
        else:
            scale_progress = 1.0 - (self.current_step / NUM_STEPS)

        current_scale = 1.0 + (max_scale_range * scale_progress)

        new_size = int(BASE_IMG_SIZE * current_scale)

        new_size = max(1, new_size)

        resized_img = self.original_img_pil.resize((new_size, new_size), Image.LANCZOS)

        self.heart_img_tk = ImageTk.PhotoImage(resized_img)
        self.canvas.itemconfig(self.heart_png_canvas_id, image=self.heart_img_tk)

        if self.current_step < NUM_STEPS:
            self.current_step += 1
            delay = STEP_DURATION_MS
        else:
            self.current_step = 1
            self.is_expanding = not self.is_expanding

            if self.is_expanding:
                pulse_time = (NUM_STEPS * STEP_DURATION_MS) * 2
                delay = self.pulse_period_ms - pulse_time
                if delay < 0: delay = 0
            else:
                delay = STEP_DURATION_MS

        self.animation_job_id = self.after(delay, self.animate_pulse)

    def start_pulse(self):
        self.animate_pulse()

    def setup_ui(self):
        width = self.canvas.winfo_width()
        height = self.canvas.winfo_height()

        self.pulse_center_x = width / 6
        self.pulse_center_y = height / 4

        if not self.load_base_image():
            self.canvas.create_text(
                self.pulse_center_x, self.pulse_center_y,
                text="PNG-Error: heart.png not found.",
                fill="red", font=("Helvetica", 20)
            )
            return

        self.heart_img_tk = ImageTk.PhotoImage(self.original_img_pil)

        self.heart_png_canvas_id = self.canvas.create_image(
            self.pulse_center_x,
            self.pulse_center_y,
            image=self.heart_img_tk,
            anchor="center",
        )

        self.bpm_display_id = self.canvas.create_text(
            self.pulse_center_x,
            self.pulse_center_y + 10,
            text=f"{self.bpm}",
            fill="white",
            font=("Helvetica", 20, "bold"),
            tags="bpm_text"
        )

        self.start_pulse()

        self.update_mood_image(Mood.SMILE)

if __name__ == '__main__':
    app = SmartMirrorUI()

    app.after(100, lambda: simulate_heart_rate(app))
    app.after(100, lambda: simulate_mood_change(app))

    app.mainloop()
