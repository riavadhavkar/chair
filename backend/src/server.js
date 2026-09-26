require("dotenv").config();
const express = require("express");
const { router: nearbyRouter } = require("./routes/nearby");
const { router: askRouter } = require("./routes/ask");
const { router: goRouter } = require("./routes/go");

const app = express();

app.get("/health", (_req, res) => res.json({ ok: true }));
app.use(nearbyRouter);
app.use(askRouter);
app.use(goRouter);

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Set Watch backend listening on port ${port}`);
});
