import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { Connection, Request, TYPES } from "tedious";
import {
  DefaultAzureCredential,
  getBearerTokenProvider,
  type AccessToken,
} from "@azure/identity";
import { AzureOpenAI } from "openai";
import { loadConfig } from "./config.js";

// ---------------------------------------------------------------------------
// Resolve paths relative to this file (ESM equivalent of __dirname)
// ---------------------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ---------------------------------------------------------------------------
// Hotel data type (subset of fields we use from the JSON)
// ---------------------------------------------------------------------------
interface HotelData {
  HotelId: string;
  HotelName: string;
  Description: string;
  Category: string;
  Rating: number;
  DescriptionVector: number[];
}

// ---------------------------------------------------------------------------
// Azure SQL helpers (tedious)
// ---------------------------------------------------------------------------
function connectToSql(
  server: string,
  database: string,
  credential: DefaultAzureCredential
): Promise<Connection> {
  return new Promise((resolve, reject) => {
    const config = {
      server,
      authentication: {
        type: "azure-active-directory-access-token" as const,
        options: {
          token: "", // set dynamically below
        },
      },
      options: {
        database,
        encrypt: true,
        port: 1433,
        rowCollectionOnDone: true,
        rowCollectionOnRequestCompletion: true,
      },
    };

    // NOTE: Token acquired once (~1h lifetime). For long-running operations with large datasets, consider refreshing the token.
    // Acquire a token for Azure SQL
    credential
      .getToken("https://database.windows.net/.default")
      .then((tokenResponse: AccessToken) => {
        config.authentication.options.token = tokenResponse.token;
        const connection = new Connection(config);

        const errorHandler = (err: Error) => reject(err);
        connection.on("connect", (err) => {
          connection.removeListener("error", errorHandler);
          if (err) {
            reject(err);
          } else {
            resolve(connection);
          }
        });

        connection.on("error", errorHandler);
        connection.connect();
      })
      .catch(reject);
  });
}

function executeSql(
  connection: Connection,
  sql: string,
  parameters?: Array<{ name: string; type: unknown; value: unknown }>
): Promise<Record<string, unknown>[]> {
  return new Promise((resolve, reject) => {
    const rows: Record<string, unknown>[] = [];
    const request = new Request(sql, (err, _rowCount, resultRows) => {
      if (err) {
        reject(err);
        return;
      }
      // Build rows from column metadata
      if (resultRows) {
        for (const row of resultRows) {
          const obj: Record<string, unknown> = {};
          for (const col of row) {
            obj[col.metadata.colName] = col.value;
          }
          rows.push(obj);
        }
      }
      resolve(rows);
    });

    if (parameters) {
      for (const p of parameters) {
        request.addParameter(p.name, p.type as any, p.value);
      }
    }

    connection.execSql(request);
  });
}

// ---------------------------------------------------------------------------
// Tedious transaction helpers (callback → Promise wrappers)
// ---------------------------------------------------------------------------
function beginTransaction(connection: Connection): Promise<void> {
  return new Promise((resolve, reject) => {
    connection.beginTransaction((err) => {
      if (err) reject(err);
      else resolve();
    });
  });
}

function commitTransaction(connection: Connection): Promise<void> {
  return new Promise((resolve, reject) => {
    connection.commitTransaction((err) => {
      if (err) reject(err);
      else resolve();
    });
  });
}

function rollbackTransaction(connection: Connection): Promise<void> {
  return new Promise((resolve, reject) => {
    connection.rollbackTransaction((err) => {
      if (err) reject(err);
      else resolve();
    });
  });
}

// ---------------------------------------------------------------------------
// Azure OpenAI helper
// ---------------------------------------------------------------------------
async function generateEmbeddings(
  client: AzureOpenAI,
  deployment: string,
  texts: string[]
): Promise<number[][]> {
  const response = await client.embeddings.create({
    model: deployment,
    input: texts,
  });
  return response.data.map((item) => item.embedding);
}

// Converts a number[] embedding to the JSON-array string format that
// Azure SQL's VECTOR type accepts, e.g. "[0.123,0.456,...]"
function vectorToString(embedding: number[]): string {
  return "[" + embedding.join(",") + "]";
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main(): Promise<void> {
  console.log("=== Azure SQL Vector Search — TypeScript Quickstart ===\n");

  // 1. Load configuration (SQL vars required for main script)
  const config = loadConfig(true);
  console.log(`Server:     ${config.azureSqlServer}`);
  console.log(`Database:   ${config.azureSqlDatabase}`);
  console.log(`OpenAI:     ${config.azureOpenAiEndpoint}`);
  console.log(`Deployment: ${config.azureOpenAiEmbeddingDeployment}`);
  console.log(`Algorithm:  ${config.vectorSearchAlgorithm}`);
  console.log(`Table:      dbo.${config.tableName}\n`);

  // 2. Load hotel data with pre-computed vectors from JSON file
  const dataPath = resolve(__dirname, "../../data/HotelsData_Vector.json");
  const hotels: HotelData[] = JSON.parse(readFileSync(dataPath, "utf-8"));
  console.log(`Loaded ${hotels.length} hotels from data file.\n`);

  // Validate vector dimensions for ALL hotels
  const VECTOR_DIMENSIONS = 1536; // text-embedding-3-small output dimensions
  const badVectors = hotels
    .map((h, i) => ({ index: i, id: h.HotelId, dim: h.DescriptionVector?.length }))
    .filter((v) => !v.dim || v.dim !== VECTOR_DIMENSIONS);
  if (badVectors.length > 0) {
    const examples = badVectors
      .slice(0, 3)
      .map((v) => `  Hotel ${v.id} (index ${v.index}): ${v.dim ?? "missing"}`)
      .join("\n");
    console.error(
      `Error: ${badVectors.length} hotel(s) have invalid or missing vector dimensions ` +
      `(expected ${VECTOR_DIMENSIONS}):\n${examples}\n` +
      `Re-run 'npm run embed' with a ${VECTOR_DIMENSIONS}-dimension model, ` +
      `or update the VECTOR column size.`
    );
    process.exit(1);
  }

  // 3. Authenticate with DefaultAzureCredential (used for both SQL and OpenAI)
  const credential = new DefaultAzureCredential();

  // 4. Connect to Azure SQL
  console.log("Connecting to Azure SQL Database...");
  let conn: Connection;
  try {
    conn = await connectToSql(
      config.azureSqlServer!,
      config.azureSqlDatabase!,
      credential
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg.includes("Login failed") || msg.includes("token")) {
      console.error(
        "Authentication failed. Ensure:\n" +
        "  1. You are signed in: az login\n" +
        "  2. Your identity is set as Microsoft Entra admin on the SQL server\n" +
        "  3. Your client IP is in the SQL server firewall rules\n"
      );
    }
    throw err;
  }
  console.log("Connected.\n");

  try {
  // 5. Create the hotels table with a VECTOR(1536) column
  const tableName = config.tableName;
  console.log(`Creating table dbo.${tableName} (if not exists)...`);
  await executeSql(
    conn,
    `IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'${tableName}' AND schema_id = SCHEMA_ID('dbo'))
     BEGIN
       CREATE TABLE dbo.[${tableName}] (
         id NVARCHAR(50) PRIMARY KEY,
         name NVARCHAR(200) NOT NULL,
         description NVARCHAR(MAX) NOT NULL,
         category NVARCHAR(100) NULL,
         rating FLOAT NULL,
         embedding VECTOR(1536) NULL
       );
     END`
  );
  console.log("Table ready.\n");

  // 6. Insert hotel data with pre-computed vectors (batched for performance)
  console.log("Inserting hotel data with pre-computed embeddings...");

  // Uses tedious native transaction methods (not raw SQL) to avoid
  // sp_executesql scope mismatch with BEGIN/COMMIT TRANSACTION statements.
  await beginTransaction(conn);
  try {
    await executeSql(conn, `DELETE FROM dbo.[${tableName}]`);

    // Batch inserts: group rows into single INSERT statements with
    // numbered parameters to minimize network round-trips.
    const BATCH_SIZE = 10;
    for (let i = 0; i < hotels.length; i += BATCH_SIZE) {
      const batch = hotels.slice(i, i + BATCH_SIZE);
      const valuesClauses = batch.map((_, j) =>
        `(@id${j}, @name${j}, @desc${j}, @cat${j}, @rating${j}, CAST(@emb${j} AS VECTOR(1536)))`
      );
      const sql = `INSERT INTO dbo.[${tableName}] (id, name, description, category, rating, embedding)\n         VALUES ${valuesClauses.join(",\n                ")}`;
      const params = batch.flatMap((hotel, j) => [
        { name: `id${j}`, type: TYPES.NVarChar, value: hotel.HotelId },
        { name: `name${j}`, type: TYPES.NVarChar, value: hotel.HotelName },
        { name: `desc${j}`, type: TYPES.NVarChar, value: hotel.Description },
        { name: `cat${j}`, type: TYPES.NVarChar, value: hotel.Category },
        { name: `rating${j}`, type: TYPES.Float, value: hotel.Rating },
        { name: `emb${j}`, type: TYPES.NVarChar, value: vectorToString(hotel.DescriptionVector) },
      ]);
      await executeSql(conn, sql, params);
    }

    await commitTransaction(conn);
  } catch (insertErr) {
    await rollbackTransaction(conn).catch((rollbackErr: unknown) => { console.error("Warning: Transaction rollback failed:", rollbackErr instanceof Error ? rollbackErr.message : String(rollbackErr)); });
    throw insertErr;
  }
  console.log(`Inserted ${hotels.length} hotels.\n`);

  // 7. Generate query embedding with Azure OpenAI
  const searchQuery = "luxury beachfront hotel with ocean views and spa";
  console.log(`Searching for: "${searchQuery}"\n`);

  const azureADTokenProvider = getBearerTokenProvider(
    credential,
    "https://cognitiveservices.azure.com/.default"
  );
  const openaiClient = new AzureOpenAI({
    endpoint: config.azureOpenAiEndpoint,
    azureADTokenProvider,
    apiVersion: "2024-10-21",
    timeout: 30_000,    // 30s timeout for embedding generation
    maxRetries: 3,      // Retry transient failures
  });

  let queryEmbeddings: number[][];
  try {
    queryEmbeddings = await generateEmbeddings(
      openaiClient,
      config.azureOpenAiEmbeddingDeployment,
      [searchQuery]
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg.includes("401") || msg.includes("403") || msg.includes("AuthenticationError")) {
      console.error(
        "Azure OpenAI authentication failed. Ensure:\n" +
        "  1. You are signed in: az login\n" +
        "  2. You have the 'Cognitive Services OpenAI User' role on the Azure OpenAI resource\n" +
        `  3. The endpoint is correct: ${config.azureOpenAiEndpoint}\n` +
        `  4. The deployment exists: ${config.azureOpenAiEmbeddingDeployment}\n`
      );
    }
    throw err;
  }

  const queryVector = queryEmbeddings[0];
  if (!queryVector || queryVector.length !== VECTOR_DIMENSIONS) {
    throw new Error(
      `Query embedding has unexpected dimensions: ${queryVector?.length ?? 0} ` +
      `(expected ${VECTOR_DIMENSIONS}). Check your Azure OpenAI deployment ` +
      `"${config.azureOpenAiEmbeddingDeployment}".`
    );
  }
  const queryVectorStr = vectorToString(queryVector);

  // 8. Determine effective algorithm (DiskANN may fall back to exact if row count is too low)
  let algorithm = config.vectorSearchAlgorithm;
  if (algorithm === "diskann") {
    const countResult = await executeSql(
      conn,
      `SELECT COUNT(*) AS cnt FROM dbo.[${tableName}] WHERE embedding IS NOT NULL`
    );
    const rowCount = Number(countResult[0]?.cnt ?? 0);
    if (rowCount < 1000) {
      console.warn(
        `⚠ DiskANN index requires at least 1,000 rows with non-null vectors, ` +
        `but table has only ${rowCount}. Falling back to exact (VECTOR_DISTANCE) search.\n`
      );
      algorithm = "exact";
    } else {
      console.log("Creating DiskANN vector index (if not exists)...");
      await executeSql(
        conn,
        `IF NOT EXISTS (
           SELECT * FROM sys.indexes
           WHERE name = N'ix_${tableName}_embedding' AND object_id = OBJECT_ID('dbo.[${tableName}]')
         )
         BEGIN
           CREATE VECTOR INDEX [ix_${tableName}_embedding]
           ON dbo.[${tableName}](embedding)
           WITH (type = 'DiskANN', metric = 'cosine');
         END`
      );
      console.log("DiskANN index ready.\n");
    }
  }

  // 9. Run vector similarity search
  let results: Record<string, unknown>[];

  if (algorithm === "diskann") {
    // Approximate nearest neighbor via VECTOR_SEARCH + DiskANN index
    results = await executeSql(
      conn,
      `SELECT TOP 3
         vs.distance,
         h.name, h.description, h.category, h.rating
       FROM VECTOR_SEARCH(
         dbo.[${tableName}], embedding,
         CAST(@queryVector AS VECTOR(1536)),
         'cosine', 3
       ) AS vs
       INNER JOIN dbo.[${tableName}] h ON vs.$rowid = h.$rowid
       ORDER BY vs.distance`,
      [
        {
          name: "queryVector",
          type: TYPES.NVarChar,
          value: queryVectorStr,
        },
      ]
    );
  } else {
    // Exact kNN via VECTOR_DISTANCE (default)
    results = await executeSql(
      conn,
      `SELECT TOP 3
         name,
         description,
         category,
         rating,
         VECTOR_DISTANCE('cosine', embedding, CAST(@queryVector AS VECTOR(1536))) AS distance
       FROM dbo.[${tableName}]
       ORDER BY distance`,
      [
        {
          name: "queryVector",
          type: TYPES.NVarChar,
          value: queryVectorStr,
        },
      ]
    );
  }

  // 10. Display results
  const algorithmLabel =
    algorithm === "diskann"
      ? "Approximate (DiskANN) via VECTOR_SEARCH"
      : "Exact (kNN) via VECTOR_DISTANCE";
  console.log(`--- Search Results — ${algorithmLabel} (Top 3 by Cosine Distance) ---\n`);
  for (const row of results) {
    const distance = Number(row["distance"]);
    const similarity = (1 - distance).toFixed(4);
    console.log(`  Hotel:       ${row["name"]}`);
    console.log(`  Category:    ${row["category"]}`);
    console.log(`  Rating:      ${row["rating"]}`);
    console.log(`  Description: ${(row["description"] as string).substring(0, 100)}...`);
    console.log(`  Distance:    ${distance.toFixed(4)}`);
    console.log(`  Similarity:  ${similarity}`);
    console.log();
  }

  // 11. Cleanup: optionally drop table
  if (config.dropTable) {
    console.log(`Dropping table dbo.[${tableName}]...`);
    if (algorithm === "diskann") {
      await executeSql(conn, `DROP INDEX IF EXISTS [ix_${tableName}_embedding] ON dbo.[${tableName}]`);
    }
    await executeSql(conn, `DROP TABLE IF EXISTS dbo.[${tableName}]`);
    console.log("Table dropped — no artifacts left behind.\n");
  } else {
    console.log(`Table dbo.[${tableName}] retained (set SQL_DROP_TABLE=true to clean up).\n`);
  }

  } finally {
    conn.close();
    console.log("Done. Connection closed.");
  }
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
