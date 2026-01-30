import { useLocation, useNavigate } from "react-router-dom";
import SuccessAnimation from "../components/SuccessAnimation";

export default function ResultPage() {
  const { state } = useLocation();
  const navigate = useNavigate();

  return (
    <div className="container">
      {state?.status === "success" ? (
        <>
          <SuccessAnimation />
          <h2>Payment Successful</h2>
          <p>Amount: ${state.amount}</p>
          <p>Transaction ID: {state.transactionId}</p>
        </>
      ) : (
        <h2>Payment Failed</h2>
      )}

      <button onClick={() => navigate("/")}>Back</button>
    </div>
  );
}
