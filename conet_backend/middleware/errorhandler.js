import logger from "../config/logger.js";
import { constants } from "../constants.js";

const errorHandler = (err, req, res, next) => {
  // Prefer res.statusCode when it has been explicitly set by the controller
  // (i.e. controller called res.status(N) before throwing).
  // Fall back to err.statusCode set by the service layer, then 500.
  const statusCode =
    res.statusCode && res.statusCode !== 200 ?
      res.statusCode
    : (err.statusCode ?? 500);

  // Log the error details
  logger.error({
    message: err.message,
    stack: err.stack,
    statusCode,
    method: req.method,
    url: req.originalUrl,
  });

  const body = {
    message: err.message,
    stackTrace: process.env.NODE_ENV !== "production" ? err.stack : undefined,
  };

  switch (statusCode) {
    case constants.VALIDATION_ERROR:
      res.status(statusCode).json({ title: "Validation Failed", ...body });
      break;
    case constants.NOT_FOUND:
      res.status(statusCode).json({ title: "Not Found", ...body });
      break;
    case constants.UNAUTHORIZED:
      res.status(statusCode).json({ title: "Unauthorized", ...body });
      break;
    case constants.FORBIDDEN:
      res.status(statusCode).json({ title: "Forbidden", ...body });
      break;
    case constants.SERVER_ERROR:
      res.status(statusCode).json({ title: "Server Error", ...body });
      break;
    default:
      res.status(statusCode).json({ title: "Error", ...body });
      break;
  }
};

export default errorHandler;
