import logger from "../config/logger.js";

const requestLogger = (req, res, next) => {
  const start = Date.now();
  const { method, originalUrl } = req;

  // Log response when it finishes
  res.on("finish", () => {
    const duration = Date.now() - start;
    const { statusCode } = res;

    logger.info({
      message: `${method} ${originalUrl} ${statusCode} ${duration}ms`,
      method,
      url: originalUrl,
      statusCode,
      duration,
    });
  });

  next();
};

export default requestLogger;
