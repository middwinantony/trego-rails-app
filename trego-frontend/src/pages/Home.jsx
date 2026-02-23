import { useNavigate } from "react-router-dom";

export default function Home() {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-white
     text-white">
      <div className="text-3xl mb-3">🚗</div>
      <h1 className="text-3xl sm:text-4xl font-bold text-blue-500 mb-10">
        Welcome to Trego
      </h1>
      <h3 className="text-1xl sm:text-1xl font-light text-gray-400 mb-5">
        Fair, transparent, reliable rides
      </h3>

      <div className="flex flex-col sm:flex-row gap-6 sm:gap-8 max-w-md sm:max-w-none">
        <div
          onClick={() => navigate("/driver")}
          className="bg-blue-500 hover:bg-yellow-400 hover:text-black transition-all duration-300 p-8 rounded-xl cursor-pointer shadow-lg w-full sm:w-48 text-center"
        >

          <h2 className="text-xl font-semibold">Continue as driver</h2>
        </div>

        <div
          onClick={() => navigate("/rider")}
          className="bg-blue-500 hover:bg-yellow-400 hover:text-black transition-all duration-300 p-8 rounded-xl cursor-pointer shadow-lg w-full sm:w-48 text-center"
        >
          <h2 className="text-xl font-semibold">Continue as rider</h2>
        </div>
        <h4 className="text-1xl sm:text-1xl font-light text-gray-400 mb-5">
          by continuing, you agree to our Terms of Service and Privacy Policy
        </h4>
      </div>
    </div>
  );
}
