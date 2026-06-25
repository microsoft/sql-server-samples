import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import {
  DefaultAzureCredential,
  getBearerTokenProvider,
} from "@azure/identity";
import { AzureOpenAI } from "openai";
import { loadConfig } from "./config.js";

// ---------------------------------------------------------------------------
// Resolve paths relative to this file (ESM equivalent of __dirname)
// ---------------------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const BATCH_SIZE = 20;

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main(): Promise<void> {
  // 1. Load config (SQL vars not required for embedding generation)
  const config = loadConfig(false);

  // 2. Read raw hotel data (no vectors)
  const inputPath = resolve(__dirname, "../../data/HotelsData.JSON");
  const outputPath = resolve(__dirname, "../../data/HotelsData_Vector.json");
  const hotels: Record<string, unknown>[] = JSON.parse(
    readFileSync(inputPath, "utf-8")
  );
  console.log(`Generating embeddings for ${hotels.length} hotels...`);

  // 3. Set up Azure OpenAI client with DefaultAzureCredential
  const credential = new DefaultAzureCredential();
  const azureADTokenProvider = getBearerTokenProvider(
    credential,
    "https://cognitiveservices.azure.com/.default"
  );
  const openaiClient = new AzureOpenAI({
    endpoint: config.azureOpenAiEndpoint,
    azureADTokenProvider,
    apiVersion: "2024-10-21",
    timeout: 30_000,
    maxRetries: 3,
  });

  // 4. Generate embeddings in batches
  const descriptions = hotels.map((h) => h["Description"] as string);
  const allEmbeddings: number[][] = [];

  for (let i = 0; i < descriptions.length; i += BATCH_SIZE) {
    const batch = descriptions.slice(i, i + BATCH_SIZE);
    const response = await openaiClient.embeddings.create({
      model: config.azureOpenAiEmbeddingDeployment,
      input: batch,
    });
    for (const item of response.data) {
      allEmbeddings.push(item.embedding);
    }
    console.log(
      `  Embedded ${Math.min(i + BATCH_SIZE, descriptions.length)}/${descriptions.length}`
    );
  }

  // 5. Attach vectors to hotel data and write output
  const hotelsWithVectors = hotels.map((hotel, idx) => ({
    ...hotel,
    DescriptionVector: allEmbeddings[idx],
  }));

  writeFileSync(outputPath, JSON.stringify(hotelsWithVectors, null, 2), "utf-8");
  console.log(`Done. Wrote HotelsData_Vector.json`);
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
