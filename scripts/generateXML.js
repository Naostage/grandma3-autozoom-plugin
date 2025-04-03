// <?xml version="1.0" encoding="UTF-8"?>
// <GMA3 DataVersion="2.1.1.2">
// <UserPlugin Name="GMA3_AutoZoom" Version="1.0.0" Author="Naostage">
//     <ComponentLua FileName="autozoom-grandma3.lua" />
// </UserPlugin>
// </GMA3>

// Generate the XML file in /out/<name>.xml

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const outDir = path.join(__dirname, "../out");

// Retrieve info from package.json
var packageJson = require("../package.json");
const name = packageJson.plugin_name;
const filename = packageJson.filename;
const version = packageJson.version;
const author = packageJson.author;
const description = packageJson.description;
const gma3DataVersion = packageJson.gma3DataVersion;
const xmlFile = path.join(outDir, `${filename}.xml`);

const xmlContent = `<?xml version="1.0" encoding="UTF-8"?>
<GMA3 DataVersion="${gma3DataVersion}">
<UserPlugin Name="${name}" Version="${version}" Author="${author}">
    <ComponentLua FileName="${filename}.lua" />
</UserPlugin>
</GMA3>`;

// Write to the file the XML content
fs.mkdirSync(outDir, { recursive: true });
fs.writeFile(xmlFile, xmlContent, (err) => {
    if (err) {
        console.error("Error writing XML file:", err);
    } else {
        console.log(`XML file generated at ${xmlFile}`);
    }
});

