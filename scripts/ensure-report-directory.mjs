import fs from "node:fs";

const reportDirectory = "lint-reports";

fs.mkdirSync(reportDirectory, { recursive: true });
