#!/usr/bin/env python3
"""Fill an emulator's MyReciBook folder with a believable cookbook.

A fresh emulator is empty, and empty screens make useless screenshots. This
writes the same layout the app writes — the architecture §4 shape — straight
into the folder the app was granted, so the app finds it on the next scan:

    <root>/<id>.json              one recipe per file
    <root>/tags.json              the tag catalog
    <root>/images/<id>-cover.jpg  covers, when photos are supplied
    <root>/pantry/<stem>.json     one product per file
    <root>/diary/<date>.json      one logged day per file

Nothing here talks to the app. It writes files and lets the store read them,
which is the whole point of recipes being plain files.

Usage:
    tools/seed_emulator.py                          # push to the device
    tools/seed_emulator.py --clear                  # wipe the folder first
    tools/seed_emulator.py --photos ~/food-pics     # attach covers
    tools/seed_emulator.py --out /tmp/seed          # write locally, no adb

Covers are matched by filename stem to a recipe's slug, so `bounty-bars.jpg`
becomes the cover of "Homemade Bounty Bars". `--photos` reports every recipe
it could not match, and every photo it could not place.
"""

from __future__ import annotations

import argparse
import json
import random
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

# The folder the app holds a SAF grant for. Check the real one with:
#   adb shell dumpsys activity permissions | grep -A2 recibook
DEFAULT_ROOT = "/sdcard/Myrecibook"

SEED = 20260909  # fixed, so a reseed reproduces the same cookbook


# ── helpers ──────────────────────────────────────────────────────────────────

def slug(text: str) -> str:
    """The app's own slug shape (product.dart slugifyProductName)."""
    out = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return out or "item"


# Fixed namespace: a title always maps to the same id, so reseeding overwrites
# its own files instead of laying a second cookbook on top of the first.
NAMESPACE = uuid.UUID("6f1c0d3e-4a2b-4c8d-9e10-5eed00000001")


def rid(name: str) -> str:
    """Stable uuid per recipe, so reseeding overwrites instead of duplicating."""
    return str(uuid.uuid5(NAMESPACE, name))


def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def ingredient(raw: str, qty=None, unit=None, item=None, note=None, group=None,
               confidence=0.97) -> dict:
    return {
        "raw": raw, "qty": qty, "unit": unit, "item": item,
        "note": note, "group": group, "confidence": confidence,
    }


def step(raw: str, confidence=1.0) -> dict:
    return {"raw": raw, "confidence": confidence}


def nutriments(kcal=None, fat=None, sat=None, carbs=None, sugars=None,
               protein=None, salt=None, **extra) -> dict:
    out = {}
    for key, value in (("kcal", kcal), ("fat", fat), ("saturated_fat", sat),
                       ("carbs", carbs), ("sugars", sugars),
                       ("protein", protein), ("salt", salt)):
        if value is not None:
            out[key] = value
    out.update({k: v for k, v in extra.items() if v is not None})
    return out


# ── the tag catalog ──────────────────────────────────────────────────────────
# Icons are catalog keys from domain/tag_icons.dart; colours from TagColor.
# A tag with an icon and showLabel false draws as a circle on a grid cover,
# which is the only form that fits beside the heart.

TAGS = [
    {"name": "Weeknight", "icon": "quick", "color": "amber"},
    {"name": "Baking", "icon": "bakery", "color": "orange"},
    {"name": "Dessert", "icon": "cake", "color": "purple"},
    {"name": "Breakfast", "icon": "breakfast", "color": "teal"},
    {"name": "Pasta", "icon": "pasta", "color": "red"},
    {"name": "Soup", "icon": "soup", "color": "green"},
    {"name": "Vegetarian", "icon": "vegetarian", "color": "green"},
    {"name": "Make ahead", "icon": "make_ahead", "color": "blue"},
    {"name": "Sunday", "icon": "family"},
    {"name": "Tried it", "icon": "favorite", "color": "red"},
]


# ── the cookbook ─────────────────────────────────────────────────────────────
# Titles in the voice of things actually rescued from a camera roll: blog
# posts, Instagram captions, a screenshot of a friend's message. `source.type`
# is one of screenshot / link / manual, matching the real import doors.

RECIPES = [
    {
        "title": "Homemade Bounty Bars",
        "tags": ["Dessert", "Baking", "Make ahead"],
        "favorite": True,
        "source": "screenshot",
        "servings": (18, "makes about 18 bars"),
        "times": {"prep_min": 25, "cook_min": None, "total_min": 135,
                  "raw": "25 min + 1 hr 50 min chilling",
                  "extra": [{"label": "Chill", "min": 110}]},
        "ingredients": [
            ingredient("200 g desiccated coconut", 200, "g", "desiccated coconut"),
            ingredient("160 ml condensed milk", 160, "ml", "condensed milk"),
            ingredient("2 tbsp coconut oil, melted", 2, "tbsp", "coconut oil", "melted"),
            ingredient("1 tsp vanilla extract", 1, "tsp", "vanilla extract"),
            ingredient("300 g dark chocolate", 300, "g", "dark chocolate", group="To coat"),
            ingredient("1 tsp coconut oil", 1, "tsp", "coconut oil", group="To coat"),
        ],
        "steps": [
            step("Stir the coconut, condensed milk, melted coconut oil and vanilla until it holds together when squeezed."),
            step("Press into a lined tin, flatten hard, and freeze for 30 minutes."),
            step("Cut into bars and freeze another 20 minutes — cold bars do not fall apart in the chocolate."),
            step("Melt the chocolate with the teaspoon of coconut oil."),
            step("Dip each bar, lift with a fork, let the excess run off, set on baking paper."),
            step("Chill for an hour. They keep a fortnight in the fridge."),
        ],
        "notes": "Freezing between the two steps is the whole trick. Warm bars crumble.",
    },
    {
        "title": "White Chocolate and Rhubarb Muffins",
        "tags": ["Baking", "Dessert"],
        "source": "link",
        "url": "https://www.bbcgoodfood.com/recipes/rhubarb-white-chocolate-muffins",
        "servings": (12, "12 muffins"),
        "times": {"prep_min": 20, "cook_min": 25, "total_min": 45, "raw": "45 min"},
        "ingredients": [
            ingredient("300 g plain flour", 300, "g", "plain flour"),
            ingredient("2 tsp baking powder", 2, "tsp", "baking powder"),
            ingredient("150 g caster sugar", 150, "g", "caster sugar"),
            ingredient("2 eggs", 2, None, "eggs"),
            ingredient("240 ml buttermilk", 240, "ml", "buttermilk"),
            ingredient("100 g butter, melted", 100, "g", "butter", "melted"),
            ingredient("250 g rhubarb, in 1 cm pieces", 250, "g", "rhubarb", "in 1 cm pieces"),
            ingredient("150 g white chocolate, chopped", 150, "g", "white chocolate", "chopped"),
        ],
        "steps": [
            step("Heat the oven to 190°C and line a muffin tin."),
            step("Whisk the dry things in one bowl, the wet in another."),
            step("Fold them together until only just combined — lumps are correct, a smooth batter makes tough muffins."),
            step("Fold in the rhubarb and most of the chocolate."),
            step("Fill the cases high, scatter the last chocolate on top."),
            step("Bake 22–25 minutes until the tops spring back."),
        ],
        "notes": "Rhubarb weeps. Bake the day you want them.",
    },
    {
        "title": "Tomato and Cottage Cheese Sandwich",
        "tags": ["Breakfast", "Weeknight", "Vegetarian"],
        "favorite": True,
        "source": "screenshot",
        "app_hint": "Instagram",
        "servings": (2, "serves 2"),
        "times": {"prep_min": 5, "cook_min": None, "total_min": 5, "raw": "5 min"},
        "ingredients": [
            ingredient("4 slices sourdough", 4, None, "sourdough"),
            ingredient("200 g cottage cheese", 200, "g", "cottage cheese"),
            ingredient("2 ripe tomatoes, thickly sliced", 2, None, "tomatoes", "thickly sliced"),
            ingredient("olive oil", None, None, "olive oil"),
            ingredient("flaky salt and black pepper", None, None, "flaky salt and black pepper"),
            ingredient("a few basil leaves", None, None, "basil leaves", "a few"),
        ],
        "steps": [
            step("Toast the bread hard."),
            step("Salt the tomato slices and leave them two minutes — this is not optional, it is the difference."),
            step("Spread the cottage cheese thickly, lay the tomatoes on, oil, pepper, basil."),
        ],
        "notes": "Cold tomatoes taste of nothing. Room temperature or don't bother.",
    },
    {
        "title": "Lemon-Blueberry Tiramisu",
        "tags": ["Dessert", "Make ahead", "Tried it"],
        "source": "screenshot",
        "app_hint": "TikTok",
        "servings": (12, "serves 10–12"),
        "times": {"prep_min": 35, "cook_min": None, "total_min": 515,
                  "raw": "35 min + overnight",
                  "extra": [{"label": "Refrigerate", "min": 480}]},
        "ingredients": [
            ingredient("500 g mascarpone", 500, "g", "mascarpone"),
            ingredient("300 ml double cream", 300, "ml", "double cream"),
            ingredient("120 g icing sugar", 120, "g", "icing sugar"),
            ingredient("2 lemons, zest and juice", 2, None, "lemons", "zest and juice"),
            ingredient("400 g blueberries", 400, "g", "blueberries"),
            ingredient("2 tbsp caster sugar", 2, "tbsp", "caster sugar", group="Blueberry layer"),
            ingredient("250 g savoiardi", 250, "g", "savoiardi"),
            ingredient("200 ml limoncello, or lemon syrup", 200, "ml", "limoncello", "or lemon syrup"),
        ],
        "steps": [
            step("Warm half the blueberries with the caster sugar until they burst. Cool completely."),
            step("Whip the cream to soft peaks. Beat the mascarpone with icing sugar, lemon zest and juice, then fold the cream through."),
            step("Dip each savoiardi in the limoncello for one second. One. They drink faster than you think."),
            step("Layer: biscuits, cream, blueberry compote, repeat, finish with cream."),
            step("Cover and refrigerate overnight. It is not tiramisu until the next day."),
            step("Scatter the raw blueberries just before serving."),
        ],
    },
    {
        "title": "Overnight Oats That Don't Taste Like Wallpaper Paste",
        "tags": ["Breakfast", "Make ahead", "Vegetarian"],
        "source": "link",
        "url": "https://www.seriouseats.com/overnight-oats",
        "servings": (1, "serves 1"),
        "times": {"prep_min": 5, "cook_min": None, "total_min": 485,
                  "raw": "5 min + overnight",
                  "extra": [{"label": "Refrigerate", "min": 480}]},
        "ingredients": [
            ingredient("60 g rolled oats", 60, "g", "rolled oats"),
            ingredient("150 ml milk", 150, "ml", "milk"),
            ingredient("80 g Greek yoghurt", 80, "g", "Greek yoghurt"),
            ingredient("1 tbsp chia seeds", 1, "tbsp", "chia seeds"),
            ingredient("1 tsp honey", 1, "tsp", "honey"),
            ingredient("a pinch of salt", None, None, "salt", "a pinch"),
        ],
        "steps": [
            step("Stir everything in the jar you will eat it from."),
            step("Refrigerate overnight."),
            step("The salt and the yoghurt are what stop it tasting of nothing. Do not skip either."),
        ],
        "notes": "Doubling the chia makes it a pudding, not oats. Learned that the hard way.",
    },
    {
        "title": "Bacon, Egg, Cheese and Potato Breakfast Burritos",
        "tags": ["Breakfast", "Make ahead"],
        "favorite": True,
        "source": "screenshot",
        "app_hint": "Pinterest",
        "servings": (10, "makes 10 burritos"),
        "times": {"prep_min": 20, "cook_min": 40, "total_min": 60, "raw": "1 hr"},
        "ingredients": [
            ingredient("800 g potatoes, diced small", 800, "g", "potatoes", "diced small"),
            ingredient("400 g streaky bacon", 400, "g", "streaky bacon"),
            ingredient("12 eggs", 12, None, "eggs"),
            ingredient("200 g cheddar, grated", 200, "g", "cheddar", "grated"),
            ingredient("10 large flour tortillas", 10, None, "flour tortillas", "large"),
            ingredient("2 tbsp neutral oil", 2, "tbsp", "neutral oil"),
            ingredient("salt, pepper, smoked paprika", None, None, "salt, pepper, smoked paprika"),
        ],
        "steps": [
            step("Roast the potatoes at 220°C for 35 minutes until the edges are genuinely crisp."),
            step("Cook the bacon, drain, chop."),
            step("Scramble the eggs softly and stop while they still look underdone."),
            step("Let everything cool. Warm filling steams the tortilla and you get a wet burrito."),
            step("Fill, fold, wrap each in foil."),
            step("Freeze. Reheat from frozen: 2 minutes microwave, then 5 minutes in a dry pan for the crust."),
        ],
        "notes": "The pan step after the microwave is the difference between this and a sad school lunch.",
    },
    {
        "title": "Cacio e Pepe, Properly",
        "tags": ["Pasta", "Weeknight", "Vegetarian", "Tried it"],
        "source": "link",
        "url": "https://www.bonappetit.com/recipe/cacio-e-pepe",
        "servings": (2, "serves 2"),
        "times": {"prep_min": 5, "cook_min": 12, "total_min": 17, "raw": "17 min"},
        "ingredients": [
            ingredient("200 g tonnarelli or spaghetti", 200, "g", "tonnarelli"),
            ingredient("120 g Pecorino Romano, finely grated", 120, "g", "Pecorino Romano", "finely grated"),
            ingredient("2 tsp black peppercorns, cracked", 2, "tsp", "black peppercorns", "cracked"),
        ],
        "steps": [
            step("Toast the cracked pepper in a dry pan until it smells of pepper rather than dust."),
            step("Boil the pasta in half the usual water, so the water goes properly starchy."),
            step("Make a paste with the pecorino and a little cool pasta water. Cool. Boiling water makes a rope of cheese and nothing will save it."),
            step("Drain the pasta, let the pan drop off the heat for thirty seconds, then toss everything with more pasta water until it turns glossy."),
        ],
        "notes": "Three ingredients means there is nowhere to hide. Temperature is the whole recipe.",
    },
    {
        "title": "Roast Chicken and the Stock That Follows It",
        "tags": ["Sunday", "Make ahead"],
        "source": "manual",
        "servings": (4, "serves 4, plus stock"),
        "times": {"prep_min": 15, "cook_min": 80, "total_min": 95, "raw": "1 hr 35 min"},
        "ingredients": [
            ingredient("1 chicken, about 1.6 kg", 1, None, "chicken", "about 1.6 kg"),
            ingredient("1 lemon, halved", 1, None, "lemon", "halved"),
            ingredient("1 head garlic, halved across", 1, None, "garlic", "halved across"),
            ingredient("2 tbsp butter, softened", 2, "tbsp", "butter", "softened"),
            ingredient("flaky salt", None, None, "flaky salt"),
            ingredient("1 onion, 2 carrots, 2 celery sticks", None, None, "onion, carrots, celery", group="For the stock"),
            ingredient("2 bay leaves", 2, None, "bay leaves", group="For the stock"),
        ],
        "steps": [
            step("Salt the bird all over and leave it uncovered in the fridge for a few hours, or overnight if you have it."),
            step("Butter the skin, put the lemon and garlic inside, roast at 200°C for 70–80 minutes."),
            step("Rest it 20 minutes. Carve."),
            step("Put the carcass, the vegetables and the bay in a pot, cover with cold water, bring up slowly and never let it boil."),
            step("Simmer three hours, strain, cool, lift the fat off the next day."),
        ],
        "notes": "Salting the day before is the single biggest improvement available to a roast chicken.",
    },
    {
        "title": "Tomato Soup Worth the Tin",
        "tags": ["Soup", "Weeknight", "Vegetarian"],
        "source": "screenshot",
        "servings": (4, "serves 4"),
        "times": {"prep_min": 10, "cook_min": 35, "total_min": 45, "raw": "45 min"},
        "ingredients": [
            ingredient("2 × 400 g tins plum tomatoes", 800, "g", "plum tomatoes"),
            ingredient("1 onion, sliced", 1, None, "onion", "sliced"),
            ingredient("4 garlic cloves", 4, None, "garlic cloves"),
            ingredient("2 tbsp olive oil", 2, "tbsp", "olive oil"),
            ingredient("1 tsp sugar", 1, "tsp", "sugar"),
            ingredient("300 ml vegetable stock", 300, "ml", "vegetable stock"),
            ingredient("100 ml double cream, optional", 100, "ml", "double cream", "optional"),
        ],
        "steps": [
            step("Roast the tinned tomatoes with the onion, garlic, oil and sugar at 200°C for 30 minutes until the edges catch."),
            step("The catching is the point. Pale tomatoes make pale soup."),
            step("Blend with the stock, loosen with more if it is too thick."),
            step("Cream at the end, off the heat, if you want it."),
        ],
    },
    {
        "title": "Miso Butter Mushrooms on Toast",
        "tags": ["Weeknight", "Vegetarian", "Breakfast"],
        "source": "screenshot",
        "app_hint": "Instagram",
        "servings": (2, "serves 2"),
        "times": {"prep_min": 5, "cook_min": 12, "total_min": 17, "raw": "17 min"},
        "ingredients": [
            ingredient("400 g mixed mushrooms, torn", 400, "g", "mushrooms", "torn"),
            ingredient("40 g butter", 40, "g", "butter"),
            ingredient("1 tbsp white miso", 1, "tbsp", "white miso"),
            ingredient("1 garlic clove, grated", 1, None, "garlic clove", "grated"),
            ingredient("2 thick slices bread", 2, None, "bread", "thick slices"),
            ingredient("chives", None, None, "chives"),
        ],
        "steps": [
            step("Dry pan, hot, mushrooms in one layer. Do not touch them for four minutes."),
            step("When they have colour, add the butter, miso and garlic and toss until everything is coated."),
            step("Pile onto toast, chives over."),
        ],
        "notes": "Crowding the pan steams them grey. Two batches if you have to.",
    },
    {
        "title": "Focaccia With No Kneading At All",
        "tags": ["Baking", "Make ahead", "Vegetarian"],
        "source": "link",
        "url": "https://www.kingarthurbaking.com/recipes/no-knead-focaccia",
        "servings": (12, "one large tray, 12 pieces"),
        "times": {"prep_min": 20, "cook_min": 25, "total_min": 1145,
                  "raw": "20 min + overnight rise",
                  "extra": [{"label": "Rise", "min": 1100}]},
        "ingredients": [
            ingredient("500 g strong white flour", 500, "g", "strong white flour"),
            ingredient("400 ml cool water", 400, "ml", "water", "cool"),
            ingredient("10 g fine salt", 10, "g", "fine salt"),
            ingredient("4 g instant yeast", 4, "g", "instant yeast"),
            ingredient("6 tbsp olive oil", 6, "tbsp", "olive oil"),
            ingredient("flaky salt and rosemary", None, None, "flaky salt and rosemary"),
        ],
        "steps": [
            step("Mix flour, water, salt and yeast to a shaggy mess. No kneading."),
            step("Cover and refrigerate 12–18 hours."),
            step("Oil the tray generously, tip the dough in, leave two hours at room temperature."),
            step("Dimple it hard with wet fingers, right to the bottom of the tray."),
            step("Oil, flaky salt, rosemary, bake at 230°C for 22–25 minutes."),
        ],
        "notes": "Too much oil in the tray is the correct amount of oil in the tray.",
    },
    {
        "title": "Dad's Chilli, Written Down at Last",
        "tags": ["Sunday", "Make ahead", "Tried it"],
        "source": "manual",
        "servings": (8, "serves 8"),
        "times": {"prep_min": 25, "cook_min": 150, "total_min": 175, "raw": "2 hr 55 min"},
        "ingredients": [
            ingredient("1 kg beef shin, diced", 1, "kg", "beef shin", "diced"),
            ingredient("2 onions, diced", 2, None, "onions", "diced"),
            ingredient("4 garlic cloves", 4, None, "garlic cloves"),
            ingredient("2 tbsp smoked paprika", 2, "tbsp", "smoked paprika"),
            ingredient("1 tbsp ground cumin", 1, "tbsp", "ground cumin"),
            ingredient("2 dried ancho chillies", 2, None, "dried ancho chillies"),
            ingredient("400 g tin chopped tomatoes", 400, "g", "chopped tomatoes"),
            ingredient("400 g tin kidney beans", 400, "g", "kidney beans"),
            ingredient("30 g dark chocolate", 30, "g", "dark chocolate"),
            ingredient("500 ml beef stock", 500, "ml", "beef stock"),
        ],
        "steps": [
            step("Brown the beef properly, in batches. This takes longer than you want it to."),
            step("Soften the onions, add garlic and the dry spices, cook until fragrant."),
            step("Everything except the beans and chocolate back in the pot, cover, 2 hours at 150°C."),
            step("Beans in for the last 30 minutes."),
            step("Chocolate stirred in off the heat. Nobody tastes chocolate, everybody tastes the difference."),
            step("Better the next day. Always."),
        ],
        "notes": "He never measured anything. These are my numbers, not his.",
    },
]


# ── the pantry ───────────────────────────────────────────────────────────────
# Barcode-stemmed products read as scanned; slug-stemmed ones as typed in.
# Values are per 100 g / 100 ml, the label convention the app assumes.

PRODUCTS = [
    ("5000112637922", "Semi Skimmed Milk", "Tine", "1 L", "off",
     nutriments(kcal=47, fat=1.5, sat=1.0, carbs=4.8, sugars=4.8, protein=3.4, salt=0.1),
     [("1 glass (200 ml)", 200.0), ("1 dl", 100.0)], "1 glass (200 ml)"),
    ("7038010009457", "Greek Yoghurt Natural", "Q", "500 g", "off",
     nutriments(kcal=97, fat=5.0, sat=3.4, carbs=3.6, sugars=3.6, protein=9.0, salt=0.1),
     [("1 pot (150 g)", 150.0), ("1 tbsp", 15.0)], "1 pot (150 g)"),
    ("7035620038693", "Rolled Oats", "Axa", "1 kg", "off",
     nutriments(kcal=370, fat=7.0, sat=1.3, carbs=58.0, sugars=1.0, protein=13.0, salt=0.0,
                fiber=10.0),
     [("1 portion (60 g)", 60.0), ("1 dl", 35.0)], "1 portion (60 g)"),
    ("8076809513692", "Spaghetti No. 5", "Barilla", "500 g", "off",
     nutriments(kcal=359, fat=1.5, sat=0.3, carbs=71.2, sugars=3.5, protein=12.5, salt=0.0),
     [("1 portion (100 g)", 100.0)], "1 portion (100 g)"),
    ("7622210449283", "Dark Chocolate 70%", "Marabou", "200 g", "off",
     nutriments(kcal=592, fat=42.0, sat=25.0, carbs=33.0, sugars=28.0, protein=7.8, salt=0.0),
     [("1 square", 10.0), ("1 row", 40.0)], "1 square"),
    ("5701092107206", "Cottage Cheese Natural", "Arla", "400 g", "off",
     nutriments(kcal=79, fat=2.0, sat=1.3, carbs=3.0, sugars=3.0, protein=12.0, salt=0.7),
     [("1 pot (200 g)", 200.0), ("2 tbsp", 40.0)], "1 pot (200 g)"),
    ("7035110000103", "Free Range Eggs", "Prior", "12 pack", "off",
     nutriments(kcal=143, fat=9.5, sat=3.1, carbs=0.7, sugars=0.4, protein=12.6, salt=0.3),
     [("1 egg", 58.0), ("2 eggs", 116.0)], "1 egg"),
    ("5000354922404", "Sourdough Loaf", "Bakers", "800 g", "off",
     nutriments(kcal=247, fat=1.2, sat=0.3, carbs=48.0, sugars=2.1, protein=8.5, salt=1.2,
                fiber=3.5),
     [("1 slice", 45.0), ("2 slices", 90.0)], "1 slice"),
    ("8410076472106", "Extra Virgin Olive Oil", "Borges", "500 ml", "off",
     nutriments(kcal=824, fat=91.6, sat=13.0, carbs=0.0, sugars=0.0, protein=0.0, salt=0.0),
     [("1 tbsp", 14.0), ("1 tsp", 5.0)], "1 tbsp"),
    ("7038010068904", "Salted Butter", "Tine", "500 g", "off",
     nutriments(kcal=736, fat=81.0, sat=52.0, carbs=0.7, sugars=0.7, protein=0.6, salt=1.3),
     [("1 knob (10 g)", 10.0), ("1 tbsp", 14.0)], "1 knob (10 g)"),
    ("20047262", "Chicken Breast Fillet", None, "600 g", "off",
     nutriments(kcal=106, fat=1.4, sat=0.4, carbs=0.0, sugars=0.0, protein=23.0, salt=0.1),
     [("1 fillet", 150.0), ("100 g", 100.0)], "1 fillet"),
    ("8000500310427", "Pecorino Romano", None, "200 g", "off",
     nutriments(kcal=387, fat=31.0, sat=20.0, carbs=0.0, sugars=0.0, protein=26.0, salt=3.9,
                calcium=1100.0),
     [("1 tbsp grated", 6.0), ("50 g", 50.0)], "1 tbsp grated"),
    # Typed in by hand — no barcode, so the stem is a slug.
    (None, "Blueberries", None, "punnet", "manual",
     nutriments(kcal=57, fat=0.3, sat=0.0, carbs=12.1, sugars=10.0, protein=0.7, salt=0.0,
                fiber=2.4, vitamin_c=9.7),
     [("1 handful", 60.0), ("1 punnet", 125.0)], "1 handful"),
    (None, "Bananas", None, "loose", "manual",
     nutriments(kcal=89, fat=0.3, sat=0.1, carbs=22.8, sugars=12.2, protein=1.1, salt=0.0,
                fiber=2.6, potassium=358.0),
     [("1 medium", 118.0), ("1 small", 90.0)], "1 medium"),
    (None, "Coffee, black", None, None, "manual",
     nutriments(kcal=2, fat=0.0, sat=0.0, carbs=0.0, sugars=0.0, protein=0.1, salt=0.0),
     [("1 cup", 240.0), ("1 double espresso", 60.0)], "1 cup"),
    (None, "Cherry Tomatoes", None, "250 g", "manual",
     nutriments(kcal=18, fat=0.2, sat=0.0, carbs=3.9, sugars=2.6, protein=0.9, salt=0.0,
                fiber=1.2),
     [("1 handful", 80.0), ("1 tomato", 17.0)], "1 handful"),
]


# ── the diary ────────────────────────────────────────────────────────────────
# A believable eater, not a spreadsheet: breakfast almost daily, lunch usually,
# dinner most nights, snacks sometimes, and days that are simply missing —
# a day with nothing in it has no file, which is the store's own rule.

# One logged row: (product ref, name, brand, serving label, grams, kcal/100).
# Rows are grouped into plates rather than picked one at a time, because a
# breakfast of dry oats and nothing else is not a breakfast anyone ate.

OATS = ("7035620038693", "Rolled Oats", "Axa", "1 portion (60 g)", 60.0, 370)
MILK = ("5000112637922", "Semi Skimmed Milk", "Tine", "1 glass (200 ml)", 200.0, 47)
YOGHURT = ("7038010009457", "Greek Yoghurt Natural", "Q", "1 pot (150 g)", 150.0, 97)
SOURDOUGH = ("5000354922404", "Sourdough Loaf", "Bakers", "2 slices", 90.0, 247)
SOURDOUGH_SIDE = ("5000354922404", "Sourdough Loaf", "Bakers", "1 slice", 45.0, 247)
BUTTER = ("7038010068904", "Salted Butter", "Tine", "1 knob (10 g)", 10.0, 736)
EGGS = ("7035110000103", "Free Range Eggs", "Prior", "2 eggs", 116.0, 143)
COTTAGE = ("5701092107206", "Cottage Cheese Natural", "Arla", "1 pot (200 g)", 200.0, 79)
CHICKEN = ("20047262", "Chicken Breast Fillet", None, "1 fillet", 150.0, 106)
PASTA = ("8076809513692", "Spaghetti No. 5", "Barilla", "1 portion (100 g)", 100.0, 359)
PECORINO = ("8000500310427", "Pecorino Romano", None, "1 tbsp grated", 6.0, 387)
OLIVE_OIL = ("8410076472106", "Extra Virgin Olive Oil", "Borges", "1 tbsp", 14.0, 824)
TOMATOES = ("cherry-tomatoes", "Cherry Tomatoes", None, "1 handful", 80.0, 18)
BANANA = ("bananas", "Bananas", None, "1 medium", 118.0, 89)
BLUEBERRIES = ("blueberries", "Blueberries", None, "1 handful", 60.0, 57)
CHOCOLATE = ("7622210449283", "Dark Chocolate 70%", "Marabou", "1 row", 40.0, 592)
COFFEE = ("coffee-black", "Coffee, black", None, "1 cup", 240.0, 2)

BREAKFAST_PLATES = [
    (OATS, MILK, BLUEBERRIES),
    (YOGHURT, OATS, BANANA),
    (SOURDOUGH, BUTTER, EGGS),
    (EGGS, SOURDOUGH, TOMATOES),
    (YOGHURT, BLUEBERRIES, BANANA),
]

LUNCH_PLATES = [
    (SOURDOUGH, COTTAGE, TOMATOES),
    (CHICKEN, PASTA, OLIVE_OIL),
    (PASTA, PECORINO, OLIVE_OIL),
    (CHICKEN, SOURDOUGH, BUTTER),
    (COTTAGE, SOURDOUGH, BANANA),
]

SNACKS = [BANANA, BLUEBERRIES, CHOCOLATE, YOGHURT, TOMATOES]


def build_recipes(photos: dict[str, Path]) -> tuple[list[dict], list[str], list[str]]:
    """Returns (recipe json objects, recipes without a photo, unused photos)."""
    out, uncovered = [], []
    used = set()
    now = datetime.now(timezone.utc)
    for index, spec in enumerate(RECIPES):
        title = spec["title"]
        recipe_id = rid(title)
        stem = slug(title)
        imported = now - timedelta(days=len(RECIPES) - index, hours=index * 3 % 20)

        cover = None
        photo = photos.get(stem)
        if photo is not None:
            cover = f"images/{recipe_id}-cover{photo.suffix.lower()}"
            used.add(stem)
        else:
            uncovered.append(title)

        source = {
            "type": spec["source"],
            "imported_at": iso(imported),
            "original_images": ([f"images/{recipe_id}-0.jpg"]
                                if spec["source"] == "screenshot" else None),
            "app_hint": spec.get("app_hint"),
        }
        if spec.get("url"):
            source["url"] = spec["url"]

        amount, raw_servings = spec["servings"]
        body = {
            "schema_version": 1,
            "id": recipe_id,
            "title": title,
            "lang": "en",
            "source": source,
            "servings": {"amount": amount, "raw": raw_servings},
            "times": spec["times"],
            "ingredients": spec["ingredients"],
            "steps": spec["steps"],
            "tags": spec["tags"],
            "notes": spec.get("notes"),
            "extraction": {
                "model": "gemini-2.5-flash",
                "mode": "image" if spec["source"] == "screenshot" else "text",
                "extracted_at": iso(imported),
            },
        }
        if spec.get("favorite"):
            body["favorite"] = True
        if cover:
            body["cover"] = cover
        out.append({"id": recipe_id, "stem": stem, "json": body, "photo": photo})

    unused = sorted(set(photos) - used)
    return out, uncovered, unused


# Pantry shelves. Names come from kProductCategories in
# domain/product_categories.dart — a free string works, but an off-catalog one
# makes a shelf of its own, which is not what a stocked pantry looks like.
CATEGORIES = {
    "Semi Skimmed Milk": "Dairy",
    "Greek Yoghurt Natural": "Dairy",
    "Salted Butter": "Dairy",
    "Cottage Cheese Natural": "Cheese",
    "Pecorino Romano": "Cheese",
    "Free Range Eggs": "Eggs",
    "Chicken Breast Fillet": "Chicken",
    "Rolled Oats": "Breakfast",
    "Spaghetti No. 5": "Pasta & grains",
    "Sourdough Loaf": "Bread",
    "Extra Virgin Olive Oil": "Oils",
    "Dark Chocolate 70%": "Sweets",
    "Blueberries": "Berries",
    "Bananas": "Fruit",
    "Cherry Tomatoes": "Veggies",
    "Coffee, black": "Coffee & tea",
}


def build_products() -> list[dict]:
    now = datetime.now(timezone.utc)
    out = []
    for index, (barcode, name, brand, quantity, source, values, servings,
                default_serving) in enumerate(PRODUCTS):
        stem = barcode or slug(name)
        body = {
            "schema_version": 1,
            "barcode": barcode,
            "name": name,
            "brand": brand,
            "quantity": quantity,
            "source": source,
            "added_at": iso(now - timedelta(days=40 - index)),
            "nutriments": values,
            "servings": [{"label": label, "grams": grams} for label, grams in servings],
            # An INDEX into servings, not a label — the log sheet preselects by
            # position (product.dart: `final int? defaultServing`). A string
            # here makes the whole file unreadable and the pantry says so.
            "default_serving": next(
                (i for i, (label, _) in enumerate(servings) if label == default_serving), 0),
        }
        category = CATEGORIES.get(name)
        if category:
            body["tags"] = [category]
        if source == "manual":
            body["user_edited"] = True
        out.append({"stem": stem, "json": body})
    return out


def build_diary(days: int, recipes: list[dict]) -> list[dict]:
    """A believable eater over [days], not a spreadsheet.

    Days land around 2,000-2,400 kcal because that is what a person eats. A
    diary averaging 900 makes the Trends screen look like a starvation log,
    which is a worse screenshot than an empty one.
    """
    rng = random.Random(SEED)
    by_title = {r["json"]["title"]: r for r in recipes}
    dinner_pool = [by_title[t] for t in (
        "Cacio e Pepe, Properly",
        "Dad's Chilli, Written Down at Last",
        "Tomato Soup Worth the Tin",
        "Miso Butter Mushrooms on Toast",
        "Roast Chicken and the Stock That Follows It",
        "Bacon, Egg, Cheese and Potato Breakfast Burritos",
    ) if t in by_title]

    out = []
    today = date.today()
    for back in range(days):
        day = today - timedelta(days=back)
        # About one day in nine is simply not logged. Real diaries have holes.
        # Today and yesterday are exempt: the diary screen opens on Today, and
        # a screenshot of an empty Today is the thing we are here to stop
        # taking.
        if back > 1 and rng.random() < 0.11:
            continue

        meals = []

        if rng.random() < 0.94:
            plate = list(rng.choice(BREAKFAST_PLATES)) + [COFFEE]
            meals.append({
                "name": "Breakfast",
                "entries": [diary_entry(rng, *item, day, 7) for item in plate],
            })

        if rng.random() < 0.86:
            plate = list(rng.choice(LUNCH_PLATES))
            if rng.random() < 0.4:
                plate = plate + [COFFEE]
            meals.append({
                "name": "Lunch",
                "entries": [diary_entry(rng, *item, day, 12) for item in plate],
            })

        if rng.random() < 0.9 and dinner_pool:
            recipe = rng.choice(dinner_pool)
            # What a logged-from-recipe row looks like: nutrition frozen at log
            # time, never recomputed afterwards.
            per_serving = round(rng.uniform(560, 880))
            entries = [{
                "id": str(uuid.uuid4()),
                "name": recipe["json"]["title"],
                "source": "recipe",
                "ref": recipe["id"],
                "serving_label": "1 serving",
                "quantity": 1.0 if rng.random() < 0.7 else 1.5,
                "per_serving": nutriments(
                    kcal=float(per_serving),
                    fat=round(per_serving * rng.uniform(0.030, 0.048), 1),
                    sat=round(per_serving * rng.uniform(0.010, 0.020), 1),
                    carbs=round(per_serving * rng.uniform(0.075, 0.120), 1),
                    sugars=round(per_serving * rng.uniform(0.008, 0.030), 1),
                    protein=round(per_serving * rng.uniform(0.035, 0.070), 1),
                    salt=round(rng.uniform(0.6, 2.4), 1),
                ),
                "logged_at": iso(datetime.combine(day, datetime.min.time()).replace(
                    hour=rng.randint(18, 20), minute=rng.randint(0, 59),
                    tzinfo=timezone.utc)),
            }]
            if rng.random() < 0.35:
                entries.append(diary_entry(rng, *SOURDOUGH_SIDE, day, 19))
            meals.append({"name": "Dinner", "entries": entries})

        if rng.random() < 0.62:
            picks = rng.sample(SNACKS, rng.choice([1, 1, 2]))
            meals.append({
                "name": "Snacks",
                "entries": [diary_entry(rng, *item, day, 15) for item in picks],
            })

        if not meals:
            continue  # an empty day has no file
        out.append({
            "date": day.isoformat(),
            "json": {"schema_version": 1, "date": day.isoformat(), "meals": meals},
        })
    return out


def diary_entry(rng, ref, name, brand, label, grams, kcal_per_100, day, hour) -> dict:
    """One logged row, with its nutrition frozen at log time like the app does."""
    factor = grams / 100.0
    macros = {
        "rolled oats": (7.0, 1.3, 58.0, 1.0, 13.0, 0.0),
        "greek yoghurt natural": (5.0, 3.4, 3.6, 3.6, 9.0, 0.1),
        "sourdough loaf": (1.2, 0.3, 48.0, 2.1, 8.5, 1.2),
        "free range eggs": (9.5, 3.1, 0.7, 0.4, 12.6, 0.3),
        "cottage cheese natural": (2.0, 1.3, 3.0, 3.0, 12.0, 0.7),
        "chicken breast fillet": (1.4, 0.4, 0.0, 0.0, 23.0, 0.1),
        "spaghetti no. 5": (1.5, 0.3, 71.2, 3.5, 12.5, 0.0),
        "blueberries": (0.3, 0.0, 12.1, 10.0, 0.7, 0.0),
        "bananas": (0.3, 0.1, 22.8, 12.2, 1.1, 0.0),
        "dark chocolate 70%": (42.0, 25.0, 33.0, 28.0, 7.8, 0.0),
        "cherry tomatoes": (0.2, 0.0, 3.9, 2.6, 0.9, 0.0),
        "coffee, black": (0.0, 0.0, 0.0, 0.0, 0.1, 0.0),
    }
    fat, sat, carbs, sugars, protein, salt = macros.get(
        name.lower(), (2.0, 0.8, 10.0, 2.0, 4.0, 0.3))
    return {
        "id": str(uuid.uuid4()),
        "name": name,
        **({"brand": brand} if brand else {}),
        "source": "product",
        "ref": ref,
        "serving_label": label,
        "serving_grams": grams,
        "quantity": 1.0 if rng.random() < 0.8 else 2.0,
        "per_serving": nutriments(
            kcal=round(kcal_per_100 * factor, 1),
            fat=round(fat * factor, 1),
            sat=round(sat * factor, 1),
            carbs=round(carbs * factor, 1),
            sugars=round(sugars * factor, 1),
            protein=round(protein * factor, 1),
            salt=round(salt * factor, 2),
        ),
        "logged_at": iso(datetime.combine(day, datetime.min.time()).replace(
            hour=hour, minute=rng.randint(0, 59), tzinfo=timezone.utc)),
    }


# Photos are matched to recipes by filename slug. These are the ones whose
# filename says the dish rather than the recipe title — Arnar's own names from
# docs/MyReciBook Recipes Screenshots/. Add a line here rather than asking
# anyone to rename a photo.
PHOTO_ALIASES = {
    "bounty-bars": "Homemade Bounty Bars",
    "casio-pepe": "Cacio e Pepe, Properly",
    "dads-chilli": "Dad's Chilli, Written Down at Last",
    "focaccia": "Focaccia With No Kneading At All",
    "lemon-teramisu": "Lemon-Blueberry Tiramisu",
    "miso-bread": "Miso Butter Mushrooms on Toast",
    "roast-chicken": "Roast Chicken and the Stock That Follows It",
    "tomato-bread": "Tomato and Cottage Cheese Sandwich",
    "tomato-soup": "Tomato Soup Worth the Tin",
    "white-muffins": "White Chocolate and Rhubarb Muffins",
}


def collect_photos(folder: Path | None) -> dict[str, Path]:
    if folder is None:
        return {}
    if not folder.is_dir():
        sys.exit(f"--photos: {folder} is not a folder")
    out = {}
    for path in sorted(folder.iterdir()):
        if path.suffix.lower() not in (".jpg", ".jpeg", ".png", ".webp"):
            continue
        stem = slug(path.stem)
        title = PHOTO_ALIASES.get(stem)
        out[slug(title) if title else stem] = path
    return out


def write_tree(target: Path, recipes, products, diary) -> None:
    (target / "images").mkdir(parents=True, exist_ok=True)
    (target / "pantry").mkdir(parents=True, exist_ok=True)
    (target / "diary").mkdir(parents=True, exist_ok=True)

    for recipe in recipes:
        (target / f"{recipe['id']}.json").write_text(
            json.dumps(recipe["json"], ensure_ascii=False, indent=2), encoding="utf-8")
        if recipe["photo"] is not None:
            suffix = recipe["photo"].suffix.lower()
            shutil.copy(recipe["photo"], target / "images" / f"{recipe['id']}-cover{suffix}")

    (target / "tags.json").write_text(
        json.dumps({"schemaVersion": 1, "tags": TAGS}, ensure_ascii=False, indent=2),
        encoding="utf-8")

    for product in products:
        (target / "pantry" / f"{product['stem']}.json").write_text(
            json.dumps(product["json"], ensure_ascii=False, indent=2), encoding="utf-8")

    for day in diary:
        (target / "diary" / f"{day['date']}.json").write_text(
            json.dumps(day["json"], ensure_ascii=False, indent=2), encoding="utf-8")


def adb(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["adb", *args], capture_output=True, text=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=DEFAULT_ROOT,
                        help=f"folder on the device (default {DEFAULT_ROOT})")
    parser.add_argument("--photos", type=Path,
                        help="folder of cover photos, matched to recipes by filename")
    parser.add_argument("--days", type=int, default=90,
                        help="how many days back to log (default 90)")
    parser.add_argument("--clear", action="store_true",
                        help="delete the folder's contents before writing")
    parser.add_argument("--out", type=Path,
                        help="write to this local folder instead of pushing to a device")
    args = parser.parse_args()

    photos = collect_photos(args.photos)
    recipes, uncovered, unused = build_recipes(photos)
    products = build_products()
    diary = build_diary(args.days, recipes)

    if args.out:
        args.out.mkdir(parents=True, exist_ok=True)
        write_tree(args.out, recipes, products, diary)
        target = str(args.out)
    else:
        if adb("shell", "true").returncode != 0:
            sys.exit("no device: start the emulator, then try again")
        if args.clear:
            adb("shell", f"rm -rf {args.root}/*.json {args.root}/images "
                         f"{args.root}/pantry {args.root}/diary")
        with tempfile.TemporaryDirectory() as tmp:
            staged = Path(tmp) / "seed"
            write_tree(staged, recipes, products, diary)
            adb("shell", "mkdir", "-p", args.root)
            for child in sorted(staged.iterdir()):
                result = adb("push", str(child), f"{args.root}/")
                if result.returncode != 0:
                    sys.exit(f"push failed for {child.name}:\n{result.stderr}")
        target = args.root

    print(f"{len(recipes)} recipes, {len(TAGS)} tags, {len(products)} products, "
          f"{len(diary)} logged days → {target}")
    if photos:
        print(f"{len(photos) - len(unused)} covers attached")
    if uncovered:
        print("\nNo photo, so these fall back to a gradient cover:")
        for title in uncovered:
            print(f"  {slug(title)}.jpg   →  {title}")
    if unused:
        print("\nPhotos that matched no recipe:")
        for stem in unused:
            print(f"  {stem}")


if __name__ == "__main__":
    main()
