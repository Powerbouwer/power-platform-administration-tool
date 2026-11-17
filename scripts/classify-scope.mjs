import { appendFileSync, readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";

const classifyScope = (paths) => ({
    dev: paths.some((path) => path.startsWith("solutions/")),
    docs: paths.some((path) => path.startsWith("docs/")),
    project: paths.some(
      (path) => !path.startsWith("solutions/") && !path.startsWith("docs/"),
    ),
    solutionNames: [
      ...new Set(
        paths
          .filter((path) => path.startsWith("solutions/"))
          .map((path) => {
            const [, solutionName] = path.split("/");
            return solutionName;
          }),
      ),
    ],
  }),
  getChangedPaths = (range) =>
    // Include both sides of renames; NUL separators preserve unusual filenames.
    execFileSync(
      "git",
      ["diff", "--no-renames", "--name-only", "-z", ...range],
      {
        encoding: "utf8",
        // Increase max buffer to handle large diffs
        maxBuffer: 16_777_216,
      },
    )
      .split("\0")
      .filter(Boolean),
  getDiffRange = (event) => {
    if (event.pull_request) {
      return [
        `${event.pull_request.base.sha}...${event.pull_request.head.sha}`,
      ];
    }
    return [event.before, event.after];
  },
  getSolutionMetadata = async (solutionUniqueName) => {
    const { parse } = await import("yaml"),
      solutionManifest = parse(
        readFileSync(
          `solutions/${solutionUniqueName}/solutions/${solutionUniqueName}/solution.yml`,
          "utf8",
        ),
      ).ImportExportXml.SolutionManifest,
      solutionVersion = solutionManifest.Version,
      versionedFilename = `${solutionUniqueName}_${solutionVersion.replaceAll(".", "_")}`;

    if (
      solutionManifest.UniqueName !== solutionUniqueName ||
      !/^\d+\.\d+\.\d+\.0$/u.test(solutionVersion)
    ) {
      throw new Error(`Expected ${solutionUniqueName} with version X.Y.Z.0.`);
    }
    if (
      execFileSync("git", ["tag", "--list", versionedFilename], {
        encoding: "utf8",
      }).trim()
    ) {
      throw new Error(`Tag ${versionedFilename} already exists.`);
    }
    return {
      filename: versionedFilename,
      name: solutionUniqueName,
      tag: versionedFilename,
      version: solutionVersion,
    };
  },
  writeWorkflowOutputs = (scope) => {
    appendFileSync(
      process.env.GITHUB_OUTPUT,
      Object.entries(scope)
        .map(([key, value]) => `${key}=${JSON.stringify(value)}\n`)
        .join(""),
    );
  };

{
  const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, "utf8")),
    scope = classifyScope(getChangedPaths(getDiffRange(event)));

  if (!event.pull_request) {
    scope.solutions = await Promise.all(
      scope.solutionNames.map(getSolutionMetadata),
    );
  }
  writeWorkflowOutputs(scope);
}
