const express = require("express");
const fs = require("fs");
const os = require("os");
const path = require("path");

// Constants
const PORT = process.env.PORT || 3000;
const HOST = "0.0.0.0";
const PAGE_TEMPLATE = fs.readFileSync(
  path.join(__dirname, "views", "index.html"),
  "utf8"
);
const SERVER_STARTED_AT = new Date();

// App
const app = express();
app.use("/assets", express.static(path.join(__dirname, "public", "assets")));

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (character) => {
    const entities = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    };
    return entities[character];
  });
}

function formatUptime(totalSeconds) {
  const seconds = Math.floor(totalSeconds);
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;

  if (hours > 0) {
    return `${hours}h ${minutes}m ${remainingSeconds}s`;
  }
  if (minutes > 0) {
    return `${minutes}m ${remainingSeconds}s`;
  }
  return `${remainingSeconds}s`;
}

function renderPage() {
  const runtimeValues = {
    HOSTNAME: os.hostname(),
    NODE_VERSION: process.version,
    SERVER_STARTED_AT: SERVER_STARTED_AT.toISOString(),
    UPTIME: formatUptime(process.uptime()),
  };

  return PAGE_TEMPLATE.replace(/\{\{([A-Z_]+)\}\}/g, (placeholder, key) =>
    escapeHtml(runtimeValues[key] || "")
  );
}

app.get("/", (req, res) => {
  res.type("html").send(renderPage());
});

let server = app.listen(PORT, () => {
  console.log(`Running on http://${HOST}:${PORT}`);
});

module.exports = server;
