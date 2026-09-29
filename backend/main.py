from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

import os
import json
from google import genai
from google.genai import types
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware

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
# It will automatically use the GEMINI_API_KEY environment variable.
try:
    client = genai.Client()
except Exception as e:
    client = None
    print(f"Warning: Could not initialize Gemini Client. Make sure GEMINI_API_KEY is set. Error: {e}")

class Garment(BaseModel):
    id: str
    imageUrl: str
    category: str
    color: str
    styleTags: List[str]

# Temporary in-memory storage until we add a real database
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
    ),
    Garment(
        id="3",
        imageUrl="https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500",
        category="Outerwear",
        color="Black",
        styleTags=["Edgy", "Night Out"]
    ),
    Garment(
        id="4",
        imageUrl="https://images.unsplash.com/photo-1549298916-b41d501d3772?w=500",
        category="Shoes",
        color="White",
        styleTags=["Sporty", "Casual"]
    )
]

@app.get("/")
async def root():
    return {"message": "Welcome to AI Outfit Matcher API"}

@app.get("/wardrobe", response_model=List[Garment])
async def get_wardrobe():
    return fake_db

@app.post("/upload")
async def upload_garment(garment: Garment):
    fake_db.append(garment)
    return {"message": "Garment uploaded successfully", "garment": garment}

@app.post("/recommendations", response_model=List[Garment])
async def get_recommendations(base_item: Garment):
    if not client:
        raise HTTPException(status_code=500, detail="Gemini API is not configured.")
        
    # Get all other items in the wardrobe
    available_items = [g for g in fake_db if g.id != base_item.id]
    
    if not available_items:
        return []
        
    # Create a prompt for Gemini
    available_items_json = [g.model_dump() for g in available_items]
    base_item_json = base_item.model_dump()
    
    prompt = f"""
    You are an expert fashion stylist. The user wants to wear the following base item:
    {json.dumps(base_item_json, indent=2)}
    
    Here are the other items available in their wardrobe:
    {json.dumps(available_items_json, indent=2)}
    
    Select 1 to 2 items from the available wardrobe that would make a great outfit with the base item.
    Consider color theory, style tags, and category balance (e.g., if the base is a top, recommend bottoms or shoes).
    
    Return ONLY a JSON list of the 'id's of the recommended items. For example: ["2", "4"]
    """
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            ),
        )
        
        # Parse the response
        recommended_ids = json.loads(response.text)
        
        # Filter the available items to match the recommended IDs
        recommendations = [g for g in available_items if g.id in recommended_ids]
        return recommendations
        
    except Exception as e:
        print(f"Error calling Gemini: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate recommendations")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
