---
applyTo: "samples/features/vector-search/**"
---

# Azure SQL Vector Search — Sample Constitution

**Status:** ACTIVE
**Version:** 1.0
**Scope:** `samples/features/vector-search/**` in this repository
**Canonical scenario:** Vector search (scenario 1 of the Azure SQL vector sample program; no scenario 2 exists yet)
**Canonical implementation:** [`vector-search-query-typescript`](/samples/features/vector-search/vector-search-query-typescript), merged via microsoft/sql-server-samples#1479
**Purpose:** This is technical/sample governance for future implementation, review, and expansion of Azure SQL vector search samples in this repository. It is **not** a Microsoft Learn editorial style guide — it does not define article prose, Learn metadata, or Mosaic/editorial conventions. Editorial rules belong to the Microsoft Learn content pipeline, not here.

This file uses `applyTo` frontmatter so GitHub Copilot and other tooling that honor `.github/instructions/*.instructions.md` automatically scope it to this sample's path.

---

## 0. Governance

- **0.1 (MUST)** Every requirement below has a stable ID (`ASV-CORE-#`, `ASV-VS-#`, `ASV-LANG-*-#`). Do not renumber or reuse an ID; superseded requirements are marked `SUPERSEDED` and kept for history, not deleted.
- **0.2 (MUST)** A requirement is binding only if it is traceable to one of the evidence sources in [§7 Evidence and source log](#7-evidence-and-source-log). Requirements without a source citation are marked `OPEN` and are not enforceable until resolved.
- **0.3 (MUST)** Layer inheritance is top-down: [§2 Article 1 — Program-wide requirements](#2-article-1-program-wide-requirements-all-azure-sql-vector-work) binds every scenario and language. [§3 Article 2 — Vector search scenario](#3-article-2-vector-search-scenario-canonical-scenario-1) binds every language implementing vector search. [§4 Article 3 — Language-specific requirements](#4-article-3-language-specific-requirements) binds one language at a time. A more specific article may narrow or add to a broader one but MUST NOT contradict it; any conflict is a documentation defect, not an implicit override — raise it as a new row in [§6 Conflicts and open decisions](#6-conflicts-and-open-decisions).
- **0.4 (MUST)** Amending this constitution requires: (a) a stated rationale, (b) the evidence source for the new claim, (c) a version bump, (d) a dated changelog entry in [§8 Changelog](#8-changelog).
- **0.5 (MUST NOT)** Do not claim a language, platform, dataset, or index type is "implemented" or "supported" in this repository unless a merged, runnable sample under `samples/features/vector-search/` proves it. Planning documents, Teams meeting notes, and product announcements are directional, not implementation evidence.

---

## 1. Reality snapshot (read this first)

As of this constitution's authoring date (2026-09-15), the **only implemented language** in this sample tree is **TypeScript** (`vector-search-query-typescript/`), covering **Azure SQL Database** only, using the **50-hotel `HotelsData_Vector.json` dataset**, with **exact (kNN) search as the default** and **DiskANN as an opt-in that requires ≥1,000 rows and falls back to exact automatically below that threshold**. Every other platform (SQL Server 2025, SQL database in Fabric, Azure SQL Managed Instance) and every other language (.NET, Python, Java, Go) named in the source plan is **not yet implemented** in this repository. Treat every such reference below as a target for future work, not a current capability.

---

## 2. Article 1 — Program-wide requirements (all Azure SQL vector work)

These requirements apply to every current and future Azure SQL vector sample in this repository, regardless of scenario or language.

### Platform scope

- **ASV-CORE-1 (MUST)** State the platform(s) a sample targets explicitly in its README "applies to" section. Do not imply a platform works by omission.
- **ASV-CORE-2 (Evidence: implemented)** The only platform with a merged, runnable sample is **Azure SQL Database** (`infra/sql-database.bicep`, `Microsoft.Sql/servers` + `Microsoft.Sql/servers/databases`).
- **ASV-CORE-3 (OPEN — source: plan PDF p.1–2)** The source plan named four target platforms: SQL Server 2025, Azure SQL Database, SQL database in Fabric, Azure SQL Managed Instance, with Fabric Data Warehouse and Synapse explicitly out of scope. Only Azure SQL Database has shipped. Adding SQL Server 2025 (local Docker box), Fabric SQL database, or Managed Instance requires its own infra path (Fabric has no ARM path per the plan; box SQL Server 2025 may need instance-level `sp_configure`) and its own PR — do not fold multi-platform support into a single sample's scope without an explicit platform-switch design.
- **ASV-CORE-4 (MUST)** Fabric Data Warehouse and Synapse remain explicitly out of scope for this sample family. Do not add them without superseding this requirement.

### Data provenance and CELA gate

- **ASV-CORE-5 (MUST)** Every dataset shipped in `data/` MUST have a traceable, reusable-for-public-samples lineage. The current dataset (`data/HotelsData.JSON`, `data/HotelsData_Vector.json`) is the standard "Stay-Kay City Hotel"-style hotels dataset already used across other public Microsoft sample repositories (for example, Azure Cognitive Search and Cosmos DB/DocumentDB vector quickstarts). This lineage is evidence of prior reuse, **not** a substitute for an explicit CELA sign-off record.
- **ASV-CORE-6 (OPEN — source: plan PDF p.4, p.14; PR #914 evidence precedence)** No explicit CELA approval record for this specific dataset copy was found in the PDF, in PR #914, or in PR #1479. Before extending the dataset (adding rows, replacing it, or hosting it externally per the plan's "durable hosting" open question), confirm CELA/legal sign-off explicitly and record the approver and date here. Do not assume prior reuse elsewhere constitutes approval for this repository.
- **ASV-CORE-7 (MUST)** Do not depend on a PG-owned or team-owned public storage account for dataset hosting (per the plan's Derek/William concern about sandbox and storage takedown history). Prefer shipping the dataset in-repo (as the TypeScript sample does) or a durably-owned, CELA-cleared location.
- **ASV-CORE-8 (MUST)** Precomputed embeddings shipped in a dataset MUST record the exact embedding model and dimension count used to generate them (current: `text-embedding-3-small`, 1536 dimensions) so future language samples reproduce identical vectors rather than silently regenerating with a different model.

### Authentication and security

- **ASV-CORE-9 (MUST, Evidence: implemented)** Default to Microsoft Entra / managed-identity authentication (`DefaultAzureCredential` or language equivalent) against `https://database.windows.net/.default`. No sample may ship a default connection string containing a password.
- **ASV-CORE-10 (MUST, Evidence: implemented)** Provision the Azure SQL server with **Azure AD-only authentication** (`azureADOnlyAuthentication: true` in `infra/sql-database.bicep`) — no SQL-auth passwords in the default provisioning path.
- **ASV-CORE-11 (MUST)** A `.gitignore` scoped to each language sample MUST exclude `.env`, `.env.local`, `.env.*.local`, build output, and `node_modules`/equivalent language dependency caches. Follow the pattern in `vector-search-query-typescript/.gitignore`.
- **ASV-CORE-12 (SHOULD)** Document a SQL-auth or key-based fallback only as a clearly labeled alternative for constrained environments (for example, local Docker SQL Server 2025 has no Entra path) — never as the default.
- **ASV-CORE-13 (SHOULD, source: plan PDF p.16)** Document least-privilege database permissions (`db_datareader`, `db_datawriter`, and `db_ddladmin` only if the sample creates/drops the vector index at runtime) alongside the broader-permissions convention used for learner-friction reduction, so a least-privilege reference exists even when the sample opens things up for learners.

### Infrastructure and configuration

- **ASV-CORE-14 (MUST, Evidence: implemented)** Provision via Azure Developer CLI (`azd up`) with Bicep templates under `infra/`. A sample's `azure.yaml` MUST document how to retrieve deployment outputs into the language sample's `.env` file (`azd env get-values`).
- **ASV-CORE-15 (MUST, Evidence: implemented)** The vector index (`CREATE VECTOR INDEX` / `DROP INDEX`) is a **data-plane** T-SQL DDL operation, not a control-plane/ARM resource. Do not model index creation/removal in Bicep; script it in the sample's own setup/query code.
- **ASV-CORE-16 (MUST)** Every environment variable a sample requires or accepts MUST be documented in a `sample.env` file with inline comments, and validated at startup with a clear error message naming the missing variable (see `vector-search-query-typescript/src/config.ts`).
- **ASV-CORE-17 (SHOULD, Evidence: implemented)** Azure OpenAI region selection is constrained by embedding-model availability; pin the allowed region list in Bicep (`@allowed([...])`) rather than allowing arbitrary regions, and document the quota-failure remediation steps (region change, SKU change, quota increase request).

### Cross-language parity

- **ASV-CORE-18 (MUST)** Every language implementation of the same scenario MUST use the same dataset, the same embedding model/dimension, and the same canonical search query so results are comparable across languages. Do not let one language's implementation silently diverge on any of these three.
- **ASV-CORE-19 (OPEN — source: plan PDF p.13, p.15)** The source plan calls for one fixed canonical query with a defined expected top result, to be used as the cross-language result-parity anchor (mirroring the Cosmos/DocumentDB "top result matches expected hotel name" pattern) with a defined tolerance for approximate-vs-exact ordering differences. No such canonical query/expected-result record exists yet in this repository. A future language sample MUST NOT invent its own expected-result contract; it must either reuse an existing one or add it here with an approver.
- **ASV-CORE-20 (MUST)** Approximate (DiskANN/ANN) search MAY return a different result ordering than exact (kNN) search for near-ties. Document this divergence per language rather than treating it as a bug, and do not assert bit-identical ordering between exact and approximate modes.

### Validation, expected output, and cleanup

- **ASV-CORE-21 (MUST, Evidence: implemented)** A sample's README MUST include a captured "Expected output" section from a real run, and MUST NOT present invented/hypothetical output as if it were captured.
- **ASV-CORE-22 (MUST, Evidence: implemented)** Provide at least 3 troubleshooting entries grounded in real failure modes (see [§3](#3-article-2-vector-search-scenario-canonical-scenario-1) for the current set); do not include speculative troubleshooting entries without a verified cause/fix pair.
- **ASV-CORE-23 (MUST, Evidence: implemented)** Provide explicit cleanup instructions for both sample-created data (`DROP INDEX` / `DROP TABLE`) and provisioned Azure resources (`azd down` or platform-specific deletion steps, for example Azure OpenAI resource deletion).
- **ASV-CORE-24 (MUST, Evidence: implemented)** CI for a language sample MUST run on `pull_request` and `push` scoped by `paths:` to that language's folder, use pinned action SHAs, skip fork PRs for any workflow that would need secrets, and cancel superseded runs via `concurrency`. Follow `.github/workflows/vector-search-typescript-ci.yml` as the reference pattern. CI MUST NOT provision live Azure resources merely to type-check/build a sample; that remains a manual/local verification step (see [§3, ASV-VS-8](#3-article-2-vector-search-scenario-canonical-scenario-1)) unless a future PR explicitly adds an approved live-integration CI path.

### Contribution acceptance criteria

- **ASV-CORE-25 (MUST)** A PR adding or changing a vector search sample in this tree is acceptable only if it: (a) does not silently expand platform/language claims beyond what it actually implements and runs, (b) updates `samples/features/vector-search/README.md`'s language table when adding a language, (c) includes a real captured "Expected output" from a run against the shared dataset and canonical query, (d) passes the scoped CI workflow for its language, (e) does not commit `.env` or other secret-bearing files, and (f) does not modify another language's sample as an unrelated side effect.
- **ASV-CORE-26 (MUST)** A PR that changes this constitution file MUST update [§8 Changelog](#8-changelog) and MUST NOT silently delete a requirement; supersede it instead (see [§0.1](#0-governance)).

---

## 3. Article 2 — Vector search scenario (canonical scenario 1)

This article narrows Article 1 to the specific "vector search" learner scenario: create a vector-capable table, load embeddings, run a similarity search, display results.

- **ASV-VS-1 (MUST, Evidence: implemented)** The scenario's end-to-end path is: create a table with a `VECTOR(n)` column → bulk-load precomputed embeddings → generate one fresh query embedding at search time → run a similarity search → display top-N results with score. Do not add embedding generation for the loaded dataset at sample runtime — embeddings are precomputed and shipped (per the source plan's explicit "embeddings are provided" scope decision and the current implementation's `data/HotelsData_Vector.json`).
- **ASV-VS-2 (MUST, Evidence: implemented)** Generating embeddings inside/outside the database for the bulk dataset, using external AI models beyond the one pinned embedding model, and chunking strategies are explicitly **out of scope** for this scenario (per plan PDF p.1, preserved in the current implementation, which only calls Azure OpenAI for the single query embedding, not the bulk dataset).
- **ASV-VS-3 (MUST, Evidence: implemented)** The dataset is the 50-row hotels dataset (`data/HotelsData_Vector.json`). Do not present this scenario as validated against a different or larger dataset unless that dataset is actually shipped and used by the sample under review.
- **ASV-VS-4 (MUST — dataset-size / algorithm gate, Evidence: implemented)** Two algorithms exist for this scenario:
  - **Exact (kNN) via `VECTOR_DISTANCE`** — works on any row count, no index required, 100% recall, is the default (`VECTOR_SEARCH_ALGORITHM=exact`).
  - **Approximate (ANN) via `VECTOR_SEARCH` with a `DiskANN` index** — requires **at least 1,000 rows with non-null vectors** to create the index. This is a hard product requirement, not a sample-imposed limit.
  - **With the current 50-row hotel dataset, DiskANN cannot be exercised as a genuinely successful end-to-end path.** The implemented sample detects this at runtime (row count `< 1000`), emits a warning, and **automatically falls back to exact search** even when a caller explicitly sets `VECTOR_SEARCH_ALGORITHM=diskann`. Do not describe DiskANN as "working" against the shipped 50-row dataset; describe it accurately as "falls back to exact below 1,000 rows," and do not claim an end-to-end DiskANN success path exists until an approved larger (≥1,000-row) dataset is loaded — see [ASV-VS-5](#3-article-2-vector-search-scenario-canonical-scenario-1).
- **ASV-VS-5 (OPEN)** No approved ≥1,000-row dataset exists yet for this scenario. Before any future PR claims a validated DiskANN path, it MUST: (a) load an approved (CELA-cleared, per [ASV-CORE-6](#2-article-1-program-wide-requirements-all-azure-sql-vector-work)) dataset of at least 1,000 rows with non-null embeddings, (b) capture a real run's output showing the DiskANN index actually created and used (not the fallback path), and (c) update this requirement from OPEN to an evidence-backed status with the dataset's source and row count cited.
- **ASV-VS-6 (MUST, Evidence: implemented)** When an ANN index exists but its `METRIC` does not match the query's requested metric, the query silently falls back to exact kNN. Samples MUST keep the index `METRIC` and the query `METRIC` identical (current: `cosine` for both) and MUST document this failure mode in troubleshooting.
- **ASV-VS-7 (MUST, Evidence: implemented)** The table schema for this scenario MUST include an application-level primary key/id, display fields (name/content, category, rating or equivalent), and one `VECTOR(n)` column. The current reference shape (TypeScript) is:
  ```sql
  CREATE TABLE dbo.<table_name> (
      id NVARCHAR(50) PRIMARY KEY,
      name NVARCHAR(200) NOT NULL,
      description NVARCHAR(MAX) NOT NULL,
      category NVARCHAR(100) NULL,
      rating FLOAT NULL,
      embedding VECTOR(1536) NULL
  );
  ```
  A future language sample MAY use idiomatic naming but MUST preserve the same conceptual columns and the same `VECTOR(1536)` dimension to stay comparable with the TypeScript reference (see [ASV-CORE-18](#2-article-1-program-wide-requirements-all-azure-sql-vector-work)).
- **ASV-VS-8 (MUST)** A live end-to-end run (provision → load → query → cleanup) against a real Azure SQL Database is the acceptance bar for "this scenario works" for a given language; a type-check/build-only CI pass is necessary but not sufficient to claim the scenario is validated.
- **ASV-VS-9 (SHOULD, Evidence: implemented)** Minimum verified troubleshooting entries for this scenario (do not remove without a replacement of equal or better specificity):
  1. Login/auth failure — Entra admin not configured on the SQL server, or stale `az login` session.
  2. Azure OpenAI authentication error — missing `Cognitive Services OpenAI User` role, or wrong endpoint/deployment name.
  3. SQL firewall error — client IP not allowlisted.
  4. `DiskANN index requires at least 1,000 rows` — expected on the 50-row dataset; sample falls back to exact automatically (see [ASV-VS-4](#3-article-2-vector-search-scenario-canonical-scenario-1)).
  5. Vector dimension mismatch — precomputed embeddings must match the column's `VECTOR(n)` dimension (1536 for `text-embedding-3-small`); regenerate embeddings if the model changes.

---

## 4. Article 3 — Language-specific requirements

Each language section inherits Article 1 and Article 2. A language section for a language with no merged sample is a **target contract**, not a description of existing code — do not write it as if the code exists.

### 4.1 TypeScript — IMPLEMENTED (reference implementation)

- **ASV-LANG-TS-1 (MUST, Evidence: implemented)** Runtime: Node.js 20.6+ (native `--env-file` support), ESM (`"type": "module"`), executed directly via `tsx` (no separate compile-then-run step for `npm start`); `npm run build` / `npm run check` run type-checking only (`scripts/typecheck.js`).
- **ASV-LANG-TS-2 (MUST, Evidence: implemented)** Driver: `tedious` for SQL Server/Azure SQL connectivity; `@azure/identity` (`DefaultAzureCredential`, `getBearerTokenProvider`) for both SQL and Azure OpenAI auth; `openai` SDK's `AzureOpenAI` class for embeddings. Pinned in `package.json`: `@azure/identity ^4.9.1`, `openai ^6.34.0`, `tedious ^19.0.0`.
- **ASV-LANG-TS-3 (MUST, Evidence: implemented)** Configuration is centralized in `src/config.ts`, which validates required vs. optional environment variables at startup and throws a descriptive error naming the missing variable and pointing to `sample.env`. Required: `AZURE_SQL_SERVER`, `AZURE_SQL_DATABASE`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_EMBEDDING_DEPLOYMENT`. Optional with defaults: `AZURE_SQL_TABLE_NAME` (default `hotels_typescript`), `VECTOR_SEARCH_ALGORITHM` (default `exact`), `SQL_DROP_TABLE` (default `false`).
- **ASV-LANG-TS-4 (MUST, Evidence: implemented)** Table name is validated against `^[a-zA-Z_][a-zA-Z0-9_]{0,114}$` before use (max 115 chars, to leave room for the derived index name `ix_{name}_embedding` under SQL Server's 128-char object-name limit). Any future language sample accepting a configurable table name MUST apply an equivalent validation, not string-concatenate untrusted input into DDL.
- **ASV-LANG-TS-5 (MUST, Evidence: implemented)** Bulk insert uses a single transaction with parameterized `INSERT` statements and an explicit rollback-on-error path; it does not use string-concatenated SQL for row values.
- **ASV-LANG-TS-6 (MUST, Evidence: implemented)** Algorithm selection and the DiskANN row-count gate are implemented exactly as specified in [ASV-VS-4](#3-article-2-vector-search-scenario-canonical-scenario-1): row count is checked before attempting `CREATE VECTOR INDEX`; below 1,000 rows the code logs a warning and executes the exact-kNN code path regardless of the requested algorithm.
- **ASV-LANG-TS-7 (MUST, Evidence: implemented)** Package manager is `npm` (`package-lock.json` committed); do not introduce `yarn`/`pnpm` lockfiles for this sample.
- **ASV-LANG-TS-8 (MUST, Evidence: implemented)** CI (`.github/workflows/vector-search-typescript-ci.yml`) type-checks on Node 22 with `npm ci` + `npm run build`, scoped to `samples/features/vector-search/vector-search-query-typescript/**`, with pinned action SHAs and a same-repo fork-PR guard.

### 4.2 .NET — NOT YET IMPLEMENTED (target contract only)

- **ASV-LANG-NET-1 (OPEN — source: plan PDF p.2)** The source plan prioritized .NET as a first-party, high-priority language (`Microsoft.Data.SqlClient`, no ODBC dependency, driver-level `VECTOR` support confirmed). **No .NET sample has been merged.** Do not present a .NET sample as available; if one is authored, it MUST implement [ASV-VS-1 through ASV-VS-9](#3-article-2-vector-search-scenario-canonical-scenario-1) and reuse the same dataset, embedding model, and column shape as the TypeScript reference.
- **ASV-LANG-NET-2 (OPEN)** Driver/version pin, target framework (the source plan left "8.0 LTS vs 9.0" open), and native `SqlVector<float>` binding vs. the JSON-string `CAST(@e AS VECTOR(n))` fallback pattern all remain unresolved until a real .NET implementation is built and evidenced here.

### 4.3 Python — NOT YET IMPLEMENTED (target contract only)

- **ASV-LANG-PY-1 (OPEN — source: plan PDF p.2–3)** The source plan prioritized Python (`pyodbc` + ODBC Driver 18, or `pymssql` as a less-standard alternative to evaluate). **No Python sample has been merged.** Do not present a Python sample as available.
- **ASV-LANG-PY-2 (OPEN)** Minimum Python version, `pyodbc` vs `pymssql` decision, and per-OS ODBC Driver 18 install documentation remain unresolved until implemented and evidenced here.

### 4.4 Java/JDBC — NOT YET IMPLEMENTED, reference-only priority

- **ASV-LANG-JAVA-1 (OPEN — source: plan PDF p.3)** The plan marked Java "reference — not v1 priority," with driver-level `VECTOR` support confirmed via the Microsoft JDBC Driver (no ODBC needed). No sample merged; treat as backlog, not a committed deliverable.

### 4.5 Go — NOT YET IMPLEMENTED, explicitly out of scope for v1

- **ASV-LANG-GO-1 (MUST, source: plan PDF p.3)** Go is explicitly out of scope for the first vector search scenario. Do not add a Go sample under this scenario's v1 scope without a separate, explicit decision superseding this requirement.

### 4.6 Adding a new language — process requirement

- **ASV-LANG-NEW-1 (MUST)** Before authoring a new language sample under this scenario: (a) read Articles 1 and 2 in full, (b) confirm the dataset/embedding-model/canonical-query parity requirements in [ASV-CORE-18](#2-article-1-program-wide-requirements-all-azure-sql-vector-work)/[ASV-CORE-19](#2-article-1-program-wide-requirements-all-azure-sql-vector-work), (c) add a new `4.N` subsection here recording the language's actual runtime, driver, auth pattern, and DiskANN-gate behavior with `Evidence: implemented` citations once merged, and (d) update [§1 Reality snapshot](#1-reality-snapshot-read-this-first) and `samples/features/vector-search/README.md`'s language table in the same PR.

---

## 5. Cleanup and lifecycle

- **ASV-CORE-27 (MUST, Evidence: implemented)** Data-only cleanup: `DROP INDEX IF EXISTS ix_<table>_embedding ON dbo.<table>; DROP TABLE IF EXISTS dbo.<table>;`.
- **ASV-CORE-28 (MUST, Evidence: implemented)** Resource cleanup: `azd down` for Azure SQL Database + Azure OpenAI provisioned via this sample's `infra/`. Platforms without an `azd`-managed lifecycle (local Docker SQL Server 2025, Fabric SQL database) MUST document their own explicit teardown steps once implemented (`docker rm -f <container>`; Fabric REST/portal deletion) rather than instructing a learner to run `azd down` against resources it didn't provision.

---

## 6. Conflicts and open decisions

Document a conflict here instead of silently resolving it by guessing. Do not delete a row; mark it resolved with an owner and date once actually decided.

| ID | Conflict | Source A | Source B | Status |
|---|---|---|---|---|
| CONF-1 | Language priority order | Plan PDF (p.2): .NET and Python are priority; TypeScript is "deferred to backlog" pending Pooja Kamath's confirmation of vector + managed-identity support in the Node.js ecosystem. | Actual shipped implementation (PR microsoft/sql-server-samples#1479): **TypeScript** is the only merged, canonical sample; .NET and Python have no merged sample. | **Open — documented, not resolved.** This constitution records the plan's stated priority in [§4.2](#42-net-not-yet-implemented-target-contract-only)/[§4.3](#43-python-not-yet-implemented-target-contract-only) and records reality in [§1](#1-reality-snapshot-read-this-first) and [§4.1](#41-typescript-implemented-reference-implementation). Do not silently reclassify TypeScript as having always been the priority language; if the team now intends TypeScript-first, record that decision explicitly with an owner and date. |
| CONF-2 | TypeScript VECTOR/managed-identity support | Plan PDF comment `Commented [PK1]` (Pooja Kamath, page 2): TypeScript/Node.js was **not** part of the original VECTOR driver onboarding effort (which covered .NET, JDBC, ODBC); VECTOR support in TypeScript was therefore unvalidated and "should not be treated as committed." A reply comment `Commented [DB2R1]` (Dina Berry) marks this "Fixed" without further detail in the extracted text. | The merged TypeScript sample (PR #1479) demonstrably uses native `VECTOR(1536)` columns and both `VECTOR_DISTANCE` and `VECTOR_SEARCH`/DiskANN successfully via `tedious`. | **Resolved by implementation evidence.** TypeScript VECTOR support is confirmed working as of the merged sample; the earlier PDF caveat is superseded by [ASV-LANG-TS-1 through ASV-LANG-TS-8](#41-typescript-implemented-reference-implementation). |
| CONF-3 | Dataset CELA/hosting approval | Plan PDF (p.4, p.14): dataset choice pending "OK to use" + CELA/hosting confirmation; two candidates discussed (Cosmos vector samples data, ZavaTax), neither the shipped hotels dataset by name. | Merged sample ships `data/HotelsData.JSON` / `data/HotelsData_Vector.json` in-repo with no CELA approval citation found in the PDF, PR #914, or PR #1479. | **Open.** See [ASV-CORE-5](#2-article-1-program-wide-requirements-all-azure-sql-vector-work)/[ASV-CORE-6](#2-article-1-program-wide-requirements-all-azure-sql-vector-work). Do not treat the dataset's presence in the repo as proof of CELA sign-off; confirm explicitly before extending or re-hosting it. |
| CONF-4 | Managed Instance DiskANN support | Plan PDF resolved-questions section (p.16), comment `Commented [PK8]` (Pooja Kamath): "It will be supported in MI now. Only SQL 2025 will have the older index and syntax" — i.e., MI now supports ANN like the other flavors. | No Managed Instance sample has been merged in this repository to confirm this in code. | **Open — unimplemented.** Record the plan's stated resolution here, but do not claim MI DiskANN support is validated in this repository until a merged MI sample provides evidence. |
| CONF-5 | Platform priority if not all four ship | Plan PDF comment `Commented [PK7]` (Pooja Kamath, p.16): "We should ship all. First pref to Azure SQL Hyperscale, followed by the others. If MI is too complex to setup, [minimum is] Azure SQL Hyperscale (PaaS) + SQL Server 2025 local docker." | Shipped implementation covers Azure SQL Database only (not explicitly Hyperscale-tier); no SQL Server 2025 local Docker sample exists yet. | **Open.** Confirm whether "Azure SQL Database" as provisioned (`sku: S0/Standard` in `infra/sql-database.bicep`) satisfies the "Hyperscale first" preference, or whether a future PR must change the provisioned SKU/tier to match this stated priority. |

---

## 7. Evidence and source log

| Locator | What it is | How it was used |
|---|---|---|
| `plan-2026-07-01-0842-azure-sql-vector-search-quickstart.pdf` (16 pages, exported from Word with visible comments) | Source plan from a 2026-07-01 Teams meeting ("Azure SQL + Vector DB quickstarts"), author Dina Berry via Copilot, with reviewer comments `Commented [PK1]`–`[PK8]` (Pooja Kamath) and `Commented [DB2R1]` (Dina Berry, reply) | Extracted in full with PyMuPDF (text + comment balloons render as inline page text in this export — no native PDF annotation objects were present). Every plan-derived requirement above cites a page number; every comment is quoted verbatim in [§6](#6-conflicts-and-open-decisions). |
| diberry/project-dina#914 ("(ignore) Plan Azure SQL vector constitutions") | Prior Plan-phase lifecycle record; recorded that the original SharePoint Word source was inaccessible (auth-blocked) and that Build never started | Confirmed this constitution supersedes that blocked attempt; reused its three-layer framing (program-wide / scenario / language) as the article structure here, adapted to a single repo-local file per the current task's explicit instruction. |
| microsoft/sql-server-samples#1479 ("Add Azure SQL vector search TypeScript quickstart sample"), merged 2026-08-31, into `samples/features/vector-search/` | The only canonical, implemented Azure SQL vector search sample | Read directly from `upstream/master` (tip `beaab06e`, fetched 2026-09-15) at: `samples/features/vector-search/README.md`, `vector-search-query-typescript/README.md`, `src/config.ts`, `src/index.ts`, `sample.env`, `.gitignore`, `package.json`, `azure.yaml`, `infra/main.bicep`, `infra/sql-database.bicep`, `data/HotelsData.JSON`, `.github/workflows/vector-search-typescript-ci.yml`. Every `Evidence: implemented` requirement above traces to one or more of these files. |

---

## 8. Changelog

- **1.0 (2026-09-15)** Initial constitution authored from the approved plan PDF and reconciled against the merged TypeScript sample (microsoft/sql-server-samples#1479) and the prior blocked hub plan (diberry/project-dina#914). Documents five source conflicts in [§6](#6-conflicts-and-open-decisions) rather than silently resolving them; leaves DiskANN end-to-end validation, multi-platform expansion, and .NET/Python/Java/Go implementations as `OPEN` per [§4](#4-article-3-language-specific-requirements).
