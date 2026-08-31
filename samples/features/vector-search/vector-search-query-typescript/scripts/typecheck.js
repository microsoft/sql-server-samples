/**
 * Runs tsc and filters out errors from node_modules.
 *
 * @azure/msal-node@5.x has a packaging bug where dist/index.d.ts imports
 * raw ../src/*.ts files, causing type errors that skipLibCheck cannot
 * suppress (it only covers .d.ts). This wrapper filters those errors so
 * builds pass cleanly when user code has no issues.
 *
 * Usage:
 *   node scripts/typecheck.js            # tsc (emit + filter)
 *   node scripts/typecheck.js --no-emit  # tsc --noEmit (check only)
 */
import { execSync } from "node:child_process";

const noEmit = process.argv.includes("--no-emit");
const cmd = noEmit ? "npx tsc --noEmit" : "npx tsc";

try {
  execSync(cmd, { stdio: "pipe" });
  // Clean build — no errors at all
  process.exit(0);
} catch (e) {
  const out = (e.stdout?.toString() ?? "") + (e.stderr?.toString() ?? "");
  const lines = out.split(/\r?\n/);

  // Separate src errors from node_modules errors
  const srcErrors = lines.filter(
    (l) => l.includes("error TS") && !l.startsWith("node_modules/")
  );
  const nmErrors = lines.filter(
    (l) => l.includes("error TS") && l.startsWith("node_modules/")
  );

  if (srcErrors.length > 0) {
    // Real errors in user code — show them and fail
    const relevant = lines.filter((l) => !l.startsWith("node_modules/"));
    console.error(relevant.join("\n"));
    process.exit(1);
  }

  // Only node_modules errors — safe to ignore
  console.log(
    `✅ Type check passed (${nmErrors.length} node_modules warning${nmErrors.length === 1 ? "" : "s"} from @azure/msal-node filtered)`
  );
  process.exit(0);
}
