//
//  main.swift
//  Prime Collapse — headless loop simulator entry point
//
//  Runs 100 games over the real engine and writes docs/simulation/{report.md,data.json}.
//  Build & run with tools/loop-sim/run.sh (compiles the real engine source files in place).
//

import Foundation

/// Run `body` with stdout redirected to /dev/null. The real engine prints
/// "DATA INTEGRITY: …" on the hot path (validateGameState runs on every
/// getCurrentUpgradeCost call), which otherwise floods the simulator output and
/// slows the run to a crawl on terminal I/O. The report is written to files, so it
/// is unaffected. (That hot-path logging is itself a finding — see the report.)
func silencingStdout<T>(_ body: () -> T) -> T {
    fflush(stdout)
    let saved = dup(STDOUT_FILENO)
    let devnull = open("/dev/null", O_WRONLY)
    dup2(devnull, STDOUT_FILENO)
    defer {
        fflush(stdout)
        dup2(saved, STDOUT_FILENO)
        close(devnull)
        close(saved)
    }
    return body()
}

let sim = LoopSimulator()
let results = silencingStdout { sim.runAll() }

let md = sim.markdown(results)
let jsonText = sim.json(results)

let outDir = URL(fileURLWithPath: "docs/simulation", isDirectory: true)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
do {
    try md.write(to: outDir.appendingPathComponent("loop-validation-report.md"), atomically: true, encoding: .utf8)
    try jsonText.write(to: outDir.appendingPathComponent("loop-validation-data.json"), atomically: true, encoding: .utf8)
} catch {
    FileHandle.standardError.write(Data("Failed to write report: \(error)\n".utf8))
}

print(sim.headline(results))
print("\nFull report -> docs/simulation/loop-validation-report.md")
print("Raw data    -> docs/simulation/loop-validation-data.json")
