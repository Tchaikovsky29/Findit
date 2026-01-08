import requests
from flask import Flask, request, jsonify
import base64
import json
import logging

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)

# Your existing API details (keep these as-is)
api_key = "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"
url = "https://openrouter.ai/api/v1/chat/completions"

@app.route('/analyze_image', methods=['POST'])
def analyze_image():
    try:
        # Expect the image as base64-encoded string in the request JSON
        data = request.get_json()
        if not data or 'image_base64' not in data:
            return jsonify({"error": "Missing 'image_base64' in request"}), 400
        
        image_base64 = data['image_base64']
        
        # Prepare the payload (reusing your existing logic)
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Analyze this image and respond using the JSON schema."},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{image_base64}"
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
            response_data = response.json()
        except requests.exceptions.Timeout:
            logging.exception('OpenRouter request timed out')
            return jsonify({"error": "LLM request timed out"}), 504
        except Exception as e:
            logging.exception('Error calling OpenRouter')
            return jsonify({"error": f"LLM request failed: {e}"}), 502
        
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
            return jsonify({"error": "Failed to get response from LLM"}), 500
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Disable the reloader/debugger for stability when receiving large requests from mobile devices
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)