import { check, sleep } from "k6";
import http from "k6/http";

export const options = {
  stages: [
    { duration: "30s", target: 10 },
    { duration: "1m", target: 50 },
    { duration: "30s", target: 10 },
  ],
};

export default function () {
  const res = http.get(
    "http://localhost:5000/api/profile/e6910703-4110-45b0-b991-9de398201f30",
    {
      headers: {
        Authorization: `Bearer eyJhbGciOiJIUzI1NiIsImtpZCI6InB1SjVrZlFsKy9lTExOM0oiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2p5cGlybmxtY2VvcXVmeHRoa3dwLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiI2NDEwOWRmNi0wNzU0LTRmMGUtODYwYy1hYjA5YmYyYTRkOWQiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzcxNDE2MTE5LCJpYXQiOjE3NzE0MTI1MTksImVtYWlsIjoidmdlY3dvcmtAZ21haWwuY29tIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJnb29nbGUiLCJwcm92aWRlcnMiOlsiZ29vZ2xlIl19LCJ1c2VyX21ldGFkYXRhIjp7ImF2YXRhcl91cmwiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJSmx3V20zYUFTbGxIOFgyU1Q3ZkhYYlF6dENqWTc5YV9paURGYTlvd0lwU3ZvYmc9czk2LWMiLCJlbWFpbCI6InZnZWN3b3JrQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJNZWV0IEJodXZhIiwiaXNzIjoiaHR0cHM6Ly9hY2NvdW50cy5nb29nbGUuY29tIiwibmFtZSI6Ik1lZXQgQmh1dmEiLCJwaG9uZV92ZXJpZmllZCI6ZmFsc2UsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJSmx3V20zYUFTbGxIOFgyU1Q3ZkhYYlF6dENqWTc5YV9paURGYTlvd0lwU3ZvYmc9czk2LWMiLCJwcm92aWRlcl9pZCI6IjEwNzUwNDIxMTEzMTkyNTk0OTYzNSIsInN1YiI6IjEwN`,
      },
    },
  );

  check(res, {
    "status is 200": (r) => r.status === 200,
    "response time < 500ms": (r) => r.timings.duration < 500,
  });

  sleep(1);
}
