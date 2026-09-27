require("dotenv").config();
const { createApp } = require("./app");
const { createStore } = require("./store");

const port = process.env.PORT || 8080;

createStore()
  .then((store) => {
    createApp({ store }).listen(port, () => {
      console.log(`chair backend listening on port ${port} (${store.kind} store)`);
    });
  })
  .catch((error) => {
    console.error("Failed to start:", error);
    process.exit(1);
  });
