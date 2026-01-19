import requests
from flask import Flask, request, jsonify
import base64
import json
import logging
import os

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)

# API configuration from environment variables (required for security)
api_key = os.getenv('OPENROUTER_API_KEY')
if not api_key:
    raise ValueError("OPENROUTER_API_KEY environment variable is not set")

url = "https://openrouter.ai/api/v1/chat/completions"


@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"}), 200

@app.route('/analyze_image', methods=['POST'])
def analyze_image():
    try:
        # Expect the image as base64-encoded string in the request JSON
        data = request.get_json()
        if not data or 'image_base64' not in data:
            return jsonify({"error": "Missing 'image_base64' in request"}), 400
        
        image_base64 = data['image_base64']
        
        # Prepare the payload (reusing your existing logic)
        # Build a proper data URI for the image. Accept either a full data URL or raw base64.
        if isinstance(image_base64, str) and image_base64.strip().startswith("data:"):
            image_data_uri = image_base64
        else:
            mime = "image/jpeg"
            try:
                # decode a small prefix to detect file signature
                sig = base64.b64decode(image_base64[:32])
                if sig.startswith(b"\x89PNG"):
                    mime = "image/png"
                elif sig.startswith(b"\xff\xd8"):
                    mime = "image/jpeg"
            except Exception:
                mime = "image/jpeg"
            image_data_uri = f"data:{mime};base64,{image_base64}"

        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Analyze this image and respond using the JSON schema."},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": image_data_uri
                        }
                    }
                ]
            }
        ]
        
        payload = {
            "model": "google/gemini-3-flash-preview",
            "messages": messages,
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "image_description",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "properties": {
                            "object": {
                                "type": "string",
                                "description": "Main object detected in the image"
                            },
                            "adjectives": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "List of adjectives describing as many distinguishing features of the specific object as possible such as its color, size, shape, condition, brand, identifying marks, and any other notable characteristics"
                            },
                            "description": {
                                "type": "string",
                                "description": "A detailed description of the object in the image with all it's features that can be used to identify that particular object from others of its kind"
                            }
                        },
                        "required": ["object", "adjectives", "description"],
                        "additionalProperties": False
                    }
                }
            },
            "max_tokens": 1024
        }
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        # Make the API call (add timeout and error handling)
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=60)
        except requests.exceptions.Timeout:
            logging.exception('OpenRouter request timed out')
            return jsonify({"error": "LLM request timed out"}), 504
        except Exception as e:
            logging.exception('Error calling OpenRouter')
            return jsonify({"error": f"LLM request failed: {e}"}), 502

        # Log status and body for debugging
        try:
            logging.info('LLM response status: %s', response.status_code)
            logging.debug('LLM response body: %s', response.text)
        except Exception:
            logging.exception('Failed to log LLM response')

        # Attempt to parse JSON response
        try:
            response_data = response.json()
        except Exception:
            logging.exception('Failed to parse LLM response as JSON')
            return jsonify({"error": "Failed to parse LLM response", "status": response.status_code, "body": response.text}), 502

        # If the LLM endpoint returned non-200, surface that for debugging
        if response.status_code != 200:
            return jsonify({"error": "LLM request returned non-200 status", "status": response.status_code, "body": response_data}), 502

        # Extract and return the LLM's response (assuming it's in response_data['choices'][0]['message']['content'])
        if 'choices' in response_data and response_data['choices']:
            llm_content = response_data['choices'][0].get('message', {}).get('content')
            parsed = None
            # If LLM returned a JSON string, parse it. Otherwise wrap the text.
            if isinstance(llm_content, str):
                try:
                    parsed = json.loads(llm_content)
                except Exception:
                    # Try to extract a JSON object inside the string if present
                    try:
                        import re
                        m = re.search(r'(\{.*\})', llm_content, re.S)
                        if m:
                            parsed = json.loads(m.group(1))
                        else:
                            parsed = {"text": llm_content}
                    except Exception:
                        parsed = {"text": llm_content}
            elif isinstance(llm_content, dict):
                parsed = llm_content
            else:
                parsed = {"text": llm_content}

            return jsonify({"result": parsed})
        else:
            logging.error('No choices in LLM response: %s', response_data)
            return jsonify({"error": "Failed to get response from LLM", "body": response_data}), 500
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Disable the reloader/debugger for stability when receiving large requests from mobile devices
    # Use PORT env var if set (Railway.app and other platforms set this)
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False, use_reloader=False)