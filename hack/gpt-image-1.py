import os
import base64
from io import BytesIO
from PIL import Image
import openai

from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY") or "your-api-key-here"
)

# Set your OpenAI API key
# openai.api_key = os.getenv("OPENAI_API_KEY") or "your-api-key-here"

# Define your prompt
prompt = """
Action Panel Description: "The Gambit - SES Banner of Sol Firing Sequence"
POV: Overhead perspective — like you're looking down from the Termind spore ship. You're seeing through the chaos: broken ship parts, glowing cracks along the super destroyer's hull where the spore ship has gripped it.
Foreground (Bottom Third of Panel): Our subject — a woman with sharp, defined features (strong jawline, high cheekbones, similar to reference images), fair complexion, and piercing dark eyes. Her dark hair is pulled back into a neat, severe updo/bun. She stands firmly on the exposed bridge deck of the SES Banner of Sol. Her expression is calm, resolved, and intensely focused — a "I outplayed you" look — almost smiling, but dead serious. She wears a highly structured, white high-couture military-style uniform coat/dress with sharp shoulders and tailoring (inspired by reference images), slightly tattered from battle but still retaining its immaculate form. Wind from decompression whips loose strands of her hair and potentially a cape (if applicable to uniform) behind her. She wears white gloves. Pose: Standing strong, one hand raised forward, giving the firing order. Eyes: Piercing directly up at the spore ship (at us, from the POV).
Midground: Massive supercannon batteries (think retro-futuristic, cold steel, mechanical gears exposed). Mounted along the damaged dorsal side of the destroyer. Barrel cracks glowing with energy — retro energy style, lots of rings and charge lines. Already mid-firing sequence: bright lances of light forming. Cables whipping, sparks flying, damaged antennae flailing in the vacuum.
Background: The Termind spore ship: Monstrous organic blob, with tendrils gripping parts of the super destroyer's hull. Outer layer of the spore ship cracking and blistering as the cannon charges — signaling imminent destruction. Pieces of biomass and organic armor already burning away from earlier hits.
Effects: Energy distortion lines traveling along the cannon barrels toward the spore ship. Harsh lighting from cannon blasts reflecting off armor and debris. Small Super Earth skull emblems visible on torn flags and broken metal debris floating around. Dark space backdrop — stars scattered like dust across blackness.
Mood: Final move energy — total commitment to survival and domination. Sacrifice hanging in the air — but victory first and foremost.
Dialogue (small but sharp, from our subject): "FIRE."
Aesthetics: gritty-realistic, industrial retro-futurism, not stylized anime. Cinematic. Reference images provided for subject's facial features and uniform style.
"""

# Generate the image
response = client.images.generate(
    model="gpt-image-1",
    prompt=prompt,
    n=1,
    size="1024x1024",
    moderation="low"  # Set moderation level to 'low'
)

# Decode and save the image
image_data = base64.b64decode(response.data[0].b64_json)
image = Image.open(BytesIO(image_data))
image.save("ses_banner_of_sol.png")
print("Image saved as 'ses_banner_of_sol.png'")
