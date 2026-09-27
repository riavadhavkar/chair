// A default premade ElevenLabs voice; override with ELEVENLABS_VOICE_ID.
const DEFAULT_VOICE_ID = "JBFqnCBsd6RMkjVDRZzb";

function isConfigured() {
  return Boolean(process.env.ELEVENLABS_API_KEY);
}

/// Text -> MP3 bytes.
async function synthesize(text) {
  const voiceID = process.env.ELEVENLABS_VOICE_ID || DEFAULT_VOICE_ID;
  const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceID}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "audio/mpeg",
      "xi-api-key": process.env.ELEVENLABS_API_KEY
    },
    body: JSON.stringify({ text, model_id: process.env.ELEVENLABS_MODEL_ID || "eleven_multilingual_v2" }),
    signal: AbortSignal.timeout(30000)
  });
  if (!response.ok) throw new Error(`ElevenLabs request failed: ${response.status}`);
  return Buffer.from(await response.arrayBuffer());
}

module.exports = { isConfigured, synthesize };
