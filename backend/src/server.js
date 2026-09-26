require("dotenv").config();
const express = require("express");
const statusRoute = require("./routes/status");

const app = express();

app.get("/health", (_req, res) => res.json({ ok: true }));
app.use(statusRoute);

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Transit backend listening on port ${port}`);
});
