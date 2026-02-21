import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import Driver from "./pages/LoginDriver";
import Rider from "./pages/LoginRider";

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-black text-white">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/driver" element={<Driver />} />
          <Route path="/rider" element={<Rider />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
