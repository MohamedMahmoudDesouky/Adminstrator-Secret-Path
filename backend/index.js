const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();
app.use(cors());
app.use(express.json());

// Add this middleware to strip /api prefix
app.use((req, res, next) => {
  if (req.url.startsWith('/api')) {
    req.url = req.url.substring(4);
  }
  next();
});

const pool = new Pool({
  host: "postgres",
  port: 5432,
  user: "postgres",
  password: "postgres",
  database: "payments",
});



app.post("/pay", async (req, res) => {
  const { amount, method } = req.body;

  try {
    // Validate input
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }
    if (!['card', 'wallet'].includes(method)) {
      return res.status(400).json({ error: "Invalid payment method" });
    }

    const result = await pool.query(
      "INSERT INTO payments(amount, method, status) VALUES($1,$2,$3) RETURNING id",
      [amount, method, "success"]
    );

    res.json({
      status: "success",
      transactionId: result.rows[0].id,
      amount,
    });
  } catch (err) {
    console.error("Payment error:", err);
    res.status(500).json({ error: "Payment processing failed" });
  }
});

app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

app.listen(3000, () => console.log("Backend running on port 3000"));