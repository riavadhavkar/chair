const express = require("express");
const { productionById } = require("../services/productionsService");

const router = express.Router();

function escapeHTML(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}

function staticMapURL({ lat, lon }) {
  const token = process.env.MAPBOX_ACCESS_TOKEN;
  if (!token) return null;
  const pin = `pin-l+ff453a(${lon},${lat})`;
  return `https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/${pin}/${lon},${lat},15.5,0/600x315@2x?access_token=${encodeURIComponent(token)}`;
}

// GET /go/:id — tiny page whose Open Graph tags make iMessage render a map
// preview card; tapping it forwards to Apple Maps walking directions.
router.get("/go/:id", async (req, res) => {
  const production = await productionById(req.params.id).catch(() => null);
  if (!production?.directionsURL) {
    res.status(404).type("text/plain").send("This shoot has wrapped or has no mappable location.");
    return;
  }

  const title = production.match?.title ?? production.titleHint ?? "Filming nearby";
  const description = `${production.location.display} — ${production.summary}`;
  const image = staticMapURL(production.location);
  const directions = escapeHTML(production.directionsURL);

  res.type("html").send(`<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHTML(title)}</title>
<meta property="og:title" content="${escapeHTML(`Walk to ${production.location.display}`)}">
<meta property="og:description" content="${escapeHTML(description)}">
${image ? `<meta property="og:image" content="${escapeHTML(image)}">` : ""}
<meta http-equiv="refresh" content="1;url=${directions}">
</head><body style="font-family:-apple-system,sans-serif;background:#000;color:#f5f5f7;padding:24px">
<p>${escapeHTML(production.summary)}</p>
<p><a style="color:#f5f5f7" href="${directions}">Open walking directions in Apple Maps</a></p>
</body></html>`);
});

module.exports = { router };
