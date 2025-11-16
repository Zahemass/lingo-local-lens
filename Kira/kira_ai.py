from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
import json
import datetime
from lingo_dev import Lingo   # 🔥 Lingo.dev SDK

# ------------------ KEYS ------------------
client = OpenAI(api_key="YOUR_OPENAI_KEY_HERE")
lingo = Lingo(api_key="YOUR_LINGO_API_KEY_HERE")

app = Flask(__name__)
CORS(app)


# ------------------ LOGGING ------------------
def log_kira(user_text, kira_response):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    log_entry = {
        "time": timestamp,
        "user_input": user_text,
        "kira_output": kira_response
    }

    with open("kira_logs.txt", "a", encoding="utf-8") as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")

    print("-------------- KIRA LOG --------------")
    print("Time:", timestamp)
    print("User Input:", user_text)
    print("Kira Response:", json.dumps(kira_response, ensure_ascii=False, indent=2))
    print("--------------------------------------")


# ------------------ LINGO HELPERS ------------------
def detect_language(text):
    """Detects input language using Lingo.dev."""
    detection = lingo.detect_language(text)
    return detection["detectedLocale"]  # ex: "ta", "te", "hi", "fr", "de", "en"


def translate_to_english(text, src_lang):
    """Translate any language → English."""
    result = lingo.batch_localize_text(text, {
        "sourceLocale": src_lang,
        "targetLocales": ["en"]
    })
    return result[0]


def translate_from_english(text, target_lang):
    """Translate English → user's language."""
    result = lingo.batch_localize_text(text, {
        "sourceLocale": "en",
        "targetLocales": [target_lang]
    })
    return result[0]


# ------------------ MAIN AI ROUTE ------------------
@app.route("/kira", methods=["POST"])
def kira():
    data = request.json
    user_text = data.get("prompt", "").strip()

    if not user_text:
        return jsonify({"error": "No prompt provided"}), 400

    # 1️⃣ Detect user language first
    user_lang = detect_language(user_text)

    # 2️⃣ Translate user → English
    english_input = translate_to_english(user_text, user_lang)

    # 3️⃣ Build messages for OpenAI (English only)
    messages = [
        {
            "role": "system",
            "content": (
                "You are Kira, an empathetic and friendly AI.\n\n"

                "Your tasks:\n"
                "1️⃣ Detect the user's mood.\n"
                "2️⃣ Choose ONE category from the list:\n"
                "['Foodie Finds','Funny Tail','History Whishpers','Hidden spots',"
                "'Art & Culture','Legends & Myths','Shopping Gems','Festive Movements'].\n\n"

                "3️⃣ Generate a friendly human-like response **ONLY IN ENGLISH**.\n"
                "   (Do NOT translate. Translation happens later.)\n\n"

                "Return STRICT JSON ONLY:\n"
                "{\n"
                "  \"mood\": \"<mood>\",\n"
                "  \"reply\": \"<english reply>\",\n"
                "  \"category\": \"<category>\",\n"
                "  \"language\": \"en\"\n"
                "}"
            )
        },
        {"role": "user", "content": english_input}
    ]

    # 4️⃣ OpenAI Response
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            temperature=0.7,
            max_tokens=300,
        )

        english_json = response.choices[0].message.content.strip()

        # Parse JSON from OpenAI
        kira_reply = json.loads(english_json)

        # 5️⃣ Translate reply → user language
        translated_reply = translate_from_english(
            kira_reply["reply"],
            user_lang
        )

        # Update final JSON
        kira_reply["reply"] = translated_reply
        kira_reply["language"] = user_lang

        log_kira(user_text, kira_reply)
        return jsonify(kira_reply)

    except Exception as e:
        error_msg = {"error": str(e)}
        log_kira(user_text, error_msg)
        return jsonify(error_msg), 500


# ------------------ RUN SERVER ------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5005, debug=True)
