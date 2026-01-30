import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Spinner from "../components/Spinner";

export default function PaymentPage() {
  const navigate = useNavigate();
  const [amount, setAmount] = useState("");
  const [method, setMethod] = useState("card");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const savedMethod = localStorage.getItem("paymentMethod");
    if (savedMethod) setMethod(savedMethod);
  }, []);

  const handlePay = async () => {
    setLoading(true);
    localStorage.setItem("paymentMethod", method);

    try {
      const res = await fetch("/api/pay", {  
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ amount, method })
      });

      const data = await res.json();
      navigate("/result", { state: data });
    } catch (err) {
      navigate("/result", { state: { status: "failed" } });
    }

    setLoading(false);
  };

  return (
    <div className="container">
      <h2>💸 Payment</h2>

      <input
        type="number"
        placeholder="Amount"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
      />

      <select value={method} onChange={(e) => setMethod(e.target.value)}>
        <option value="card">Credit Card</option>
        <option value="wallet">Wallet</option>
      </select>

      {method === "card" && (
        <>
          <input placeholder="Card Number" />
          <input placeholder="MM/YY" />
          <input placeholder="CVV" />
        </>
      )}

      {method === "wallet" && <input placeholder="Wallet Number" />}

      <button onClick={handlePay} disabled={loading}>
        {loading ? <Spinner /> : "Pay Now"}
      </button>
    </div>
  );
}
