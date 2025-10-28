import random
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from smart_mirror_ui import SmartMirrorUI

    AppType = SmartMirrorUI
else:
    AppType = object


def simulate_bpm_changes(app: AppType):
    new_bpm = random.randint(40, 220)

    app.set_bpm(new_bpm)

    app.simulation_job_id = app.after(3000, lambda: simulate_bpm_changes(app))


def start_simulation(app: AppType):
    app.after(1000, lambda: simulate_bpm_changes(app))