from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

import os
import json
from google import genai
from google.genai import types
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
from pymongo import MongoClient

load_dotenv()

app = FastAPI(title="AI Outfit Matcher API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Gemini Client
try:
    client = genai.Client()
except Exception as e:
    client = None
    print(f"Warning: Could not initialize Gemini Client. Error: {e}")

# Initialize MongoDB Client
MONGO_URI = os.getenv("MONGO_URI")
if MONGO_URI:
    mongo_client = MongoClient(MONGO_URI)
    db = mongo_client["outfit_matcher"]
    wardrobe_collection = db["wardrobe"]
    print("Connected to MongoDB!")
else:
    wardrobe_collection = None
    print("Warning: MONGO_URI not found. Using in-memory fallback database.")

class Garment(BaseModel):
    id: str
    imageUrl: str
    category: str
    color: str
    styleTags: List[str]

# Fallback database if MongoDB is not connected
fake_db = [
    Garment(
        id="1",
        imageUrl="https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500",
        category="Tops",
        color="White",
        styleTags=["Casual", "Basic"]
    ),
    Garment(
        id="2",
        imageUrl="https://images.unsplash.com/photo-1542272604-787c3835535d?w=500",
        category="Bottoms",
        color="Blue",
        styleTags=["Casual", "Denim"]
    )
]

@app.get("/")
async def root():
    return {"message": "Welcome to AI Outfit Matcher API (MongoDB Edition)"}

@app.get("/wardrobe", response_model=List[Garment])
async def get_wardrobe():
    if wardrobe_collection is not None:
        docs = wardrobe_collection.find()
        garments = []
        for doc in docs:
            doc.pop('_id', None) # Remove MongoDB's internal ID
            garments.append(Garment(**doc))
        return garments
    return fake_db

@app.post("/upload")
async def upload_garment(garment: Garment):
    if wardrobe_collection is not None:
        doc = garment.model_dump()
        wardrobe_collection.insert_one(doc)
    else:
        fake_db.append(garment)
    return {"message": "Garment uploaded successfully", "garment": garment}

@app.post("/recommendations", response_model=List[Garment])
async def get_recommendations(base_item: Garment):
    if not client:
        raise HTTPException(status_code=500, detail="Gemini API is not configured.")
        
    if wardrobe_collection is not None:
        docs = wardrobe_collection.find({"id": {"$ne": base_item.id}})
        available_items = []
        for doc in docs:
            doc.pop('_id', None)
            available_items.append(Garment(**doc))
    else:
        available_items = [g for g in fake_db if g.id != base_item.id]
    
    if not available_items:
        return []
        
    available_items_json = [g.model_dump() for g in available_items]
    
    # Fetch the actual image so Gemini can physically "look" at it
    import urllib.request
    image_bytes = None
    try:
        req = urllib.request.Request(base_item.imageUrl, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            image_bytes = response.read()
    except Exception as e:
        print(f"Warning: Could not fetch image for AI analysis: {e}")

    prompt = f"""
    You are an expert, high-end fashion stylist. 
    I have provided an image of the exact base garment I want to wear. 
    Please physically analyze the image—look at the specific shade of color, the pattern, the texture, the fabric, and the overall vibe.

    Based on your deep visual analysis of that image, find the absolute best matching items from my available wardrobe below:
    {json.dumps(available_items_json, indent=2)}
    
    Select 1 to 2 items that would make a perfect outfit with the garment in the image.
    Consider color theory (analogous, complementary), style matching, and category balance.
    
    Return ONLY a JSON list of the 'id's of the recommended items. For example: ["2", "4"]
    """
    
    try:
        # Pass both the image AND the text prompt to Gemini
        contents = []
        if image_bytes:
            contents.append(types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"))
        contents.append(prompt)

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=contents,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            ),
        )
        recommended_ids = json.loads(response.text)
        recommendations = [g for g in available_items if g.id in recommended_ids]
        return recommendations
    except Exception as e:
        print(f"Error calling Gemini: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate recommendations")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
