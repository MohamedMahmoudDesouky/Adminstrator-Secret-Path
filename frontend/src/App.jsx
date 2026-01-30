import { Routes, Route } from "react-router-dom";
import PaymentPage from "./pages/PaymentPage";
import ResultPage from "./pages/ResultPage";

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<PaymentPage />} />
      <Route path="/result" element={<ResultPage />} />
    </Routes>
  );
}
