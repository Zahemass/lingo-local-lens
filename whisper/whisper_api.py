from flask import Flask, request, jsonify, send_file
import whisper
from gtts import gTTS
import tempfile
import os
import logging
import subprocess

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

logger.info("🔄 Loading Whisper model...")
model = whisper.load_model("base")
logger.info("✅ Whisper model loaded.")

@app.route("/transcribe", methods=["POST"])
def transcribe():
    if "audio" not in request.files:
        logger.error("❌ No audio file in request")
        return jsonify({"error": "No audio file provided"}), 400

    file = request.files["audio"]
    filename = file.filename
    extension = os.path.splitext(filename)[1] or ".mp3"

    logger.info(f"🎧 Received audio file: {filename}")
    with tempfile.NamedTemporaryFile(delete=False, suffix=extension) as tmp:
        tmp_path = tmp.name
        file.save(tmp_path)
        logger.info(f"📁 Saved audio to: {tmp_path}")

    try:
        converted_path = tmp_path.replace(extension, ".wav")
        subprocess.run(["ffmpeg", "-y", "-i", tmp_path, converted_path], check=True)
        logger.info(f"🔄 Converted audio to WAV: {converted_path}")

        logger.info("🧠 Transcribing with Whisper...")
        result = model.transcribe(converted_path)
        logger.info("✅ Transcription complete.")
        logger.info(f"📝 Text: {result['text']}")
        logger.info(f"🌍 Language: {result['language']}")

        return jsonify({
            "text": result["text"],
            "language": result["language"]
        })

    except Exception as e:
        logger.exception("❌ Transcription failed:")
        return jsonify({"error": str(e)}), 500

    finally:
        try:
            os.remove(tmp_path)
            if os.path.exists(converted_path):
                os.remove(converted_path)
            logger.info("🧹 Deleted temporary files.")
        except Exception as e:
            logger.warning(f"[Warning] Could not delete temp files: {e}")

@app.route("/tts", methods=["POST"])
def text_to_speech():
    text = request.json.get("text")
    lang = request.json.get("lang", "en")
    logger.info(f"📥 TTS request - Text: {text}, Language: {lang}")

    try:
        tts = gTTS(text, lang=lang)
        out_file = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3")
        tts.save(out_file.name)
        logger.info(f"🔊 TTS audio saved at: {out_file.name}")
        return send_file(out_file.name, mimetype="audio/mpeg")

    except Exception as e:
        logger.exception("❌ TTS generation failed:")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    logger.info("🚀 Starting Flask server at http://0.0.0.0:5002")
    app.run(host="0.0.0.0", port=5002)
