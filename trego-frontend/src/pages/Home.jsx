import { useNavigate } from "react-router-dom";

export default function Home() {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-black text-white">
      <h1 className="text-4xl font-bold text-yellow-400 mb-10">
        Welcome to Trego 🚀
      </h1>

      <div className="flex gap-8">
        <div
          onClick={() => navigate("/driver")}
          className="bg-gray-900 hover:bg-yellow-400 hover:text-black transition-all duration-300 p-8 rounded-xl cursor-pointer shadow-lg w-48 text-center"
        >
          <div className="text-3xl mb-3">🚗</div>
          <h2 className="text-xl font-semibold">Driver</h2>
        </div>

        <div
          onClick={() => navigate("/rider")}
          className="bg-gray-900 hover:bg-yellow-400 hover:text-black transition-all duration-300 p-8 rounded-xl cursor-pointer shadow-lg w-48 text-center"
        >
          <div className="text-3xl mb-3">🧍</div>
          <h2 className="text-xl font-semibold">Rider</h2>
        </div>
      </div>
    </div>
  );
}
