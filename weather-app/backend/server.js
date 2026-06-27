const express = require("express");
const app = express();

const PORT = process.env.PORT || 3000;

// Health check MUST be first and lightweight
app.get("/health", (req, res) => {
  res.status(200).send("ok");
});

app.get("/", (req, res) => {
  res.send("ok");
});

// Start server LAST
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on ${PORT}`);
});