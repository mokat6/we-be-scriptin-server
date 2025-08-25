const express = require("express");
const { exec } = require("child_process");
const path = require("path");
const { spawn } = require("child_process");

const app = express();
const PORT = 1234;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Serve the HTML for each tool
app.get("/:tool", (req, res) => {
  const toolName = req.params.tool;
  const htmlPath = path.join(__dirname, "tools", toolName, "front.html");
  res.sendFile(htmlPath, (err) => {
    if (err) res.status(404).send("Tool not found");
  });
});

// Handle running the script
app.post("/:tool/run", (req, res) => {
    const toolName = req.params.tool;
    const scriptPath = path.join(__dirname, "tools", toolName, "script.sh");
  
    const args = Object.entries(req.body)
      .filter(([_, val]) => val)
      .map(([key, val]) => `--${key} "${val}"`)
      .join(" ");
  
    // Split args string into array for spawn
    const argsArray = args.match(/(?:[^\s"]+|"[^"]*")+/g) || [];
  
    res.writeHead(200, {
      "Content-Type": "text/plain; charset=utf-8",
      "Transfer-Encoding": "chunked",
    });
  
    const child = spawn(scriptPath, argsArray, { shell: "/bin/bash" });
  
    child.stdout.on("data", (data) => {
      res.write(data.toString()); // send stdout immediately
    });
  
    child.stderr.on("data", (data) => {
      res.write(data.toString()); // send stderr immediately
    });
  
    child.on("close", (code) => {
      res.end(`\nProcess exited with code ${code}`);
    });
  });
  

// yt-dlp version
app.get("/yt-dlp/version", (req, res) => {
  const child = spawn("yt-dlp", ["--version"], { shell: "/bin/bash" });
  let output = "";

  child.stdout.on("data", (data) => { output += data.toString(); });
  child.stderr.on("data", (data) => { output += data.toString(); });
  child.on("close", () => res.send(output || "yt-dlp not found"));
});

// Update yt-dlp
app.post("/yt-dlp/update", (req, res) => {
  res.writeHead(200, {
    "Content-Type": "text/plain; charset=utf-8",
    "Transfer-Encoding": "chunked",
  });

  const cmd = `pip install --upgrade --force-reinstall "yt-dlp @ https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"`;
  const child = spawn(cmd, { shell: "/bin/bash" });

  child.stdout.on("data", (data) => res.write(data.toString()));
  child.stderr.on("data", (data) => res.write(data.toString()));

  child.on("close", (code) => {
    res.end(`\nUpdate process exited with code ${code}`);
  });
});



app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
