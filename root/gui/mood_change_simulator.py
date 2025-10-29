import random
from moods import Mood
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from smart_mirror_ui import SmartMirrorUI

    AppType = SmartMirrorUI
else:
    AppType = object

def simulate_mood_change(app: AppType):
    all_moods = list(Mood)

    random_mood = random.choice(all_moods)

    app.update_mood_image(random_mood)

    app.mood_simulation_job_id = app.after(5000, lambda: simulate_mood_change(app))

def start_simulation(app: AppType):
    app.after(1000, lambda: simulate_mood_change(app))