import Razorpay from "razorpay";

let razorpayInstance = null;

export const getRazorpayClient = () => {
  if (razorpayInstance) {
    return razorpayInstance;
  }

  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;

  if (!key_id || !key_secret) {
    if (process.env.NODE_ENV === "test") {
      return null;
    }

    const error = new Error("Razorpay credentials are missing");
    error.statusCode = 500;
    throw error;
  }

  razorpayInstance = new Razorpay({ key_id, key_secret });
  return razorpayInstance;
};

const razorpay = new Proxy(
  {},
  {
    get(_target, property) {
      const client = getRazorpayClient();
      if (!client) {
        const error = new Error("Razorpay client is unavailable in test mode");
        error.statusCode = 503;
        throw error;
      }

      const value = client[property];
      return typeof value === "function" ? value.bind(client) : value;
    },
  },
);

export default razorpay;
