const express = require("express");
const axios = require("axios");
const cors = require("cors");
require("dotenv").config();

const app = express();

app.use(cors());
app.use(express.json());

// Debug: confirm env is loading
console.log("API KEY LOADED:", !!process.env.OPENWEATHER_API_KEY);

const API_KEY = process.env.OPENWEATHER_API_KEY;

// Health check route (important for testing)
app.get("/", (req, res) => {
  res.send("Weather API is running");
});

// Weather route
app.get("/weather", async (req, res) => {
  const city = req.query.city || "London";

  if (!API_KEY) {
    return res.status(500).json({
      error: "Missing OPENWEATHER_API_KEY in .env file",
    });
  }

  try {
    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather`,
      {
        params: {
          q: city,
          appid: API_KEY,
          units: "metric",
        },
      }
    );

    res.json(response.data);
  } catch (error) {
    res.status(500).json({
      error: "Weather fetch failed",
      details: error.response?.data || error.message,
    });
  }
});

// Start server
const PORT = 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});