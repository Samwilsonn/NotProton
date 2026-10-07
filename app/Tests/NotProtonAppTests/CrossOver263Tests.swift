import Foundation
import Testing
@testable import NotProtonApp

@Suite("Experimental CrossOver 26.3")
struct CrossOver263Tests {
    @Test("Recognizes the exact installed 26.3 loader")
    func recognizesStableLoader() throws {
        let build = try #require(SupportedRunners.build(loaderSHA256:
            "b5edb0444b5b25ba0aa5091be1cba11680130895c338cc8044101bce98802a63"))
        #expect(build.bundleVersion == "26.3.0.39832")
        #expect(build.cleanNtdll.keys.count == 2)
    }

    @Test("Each stable patch applies to its original binary and refuses a changed one",
          .enabled(if: FileManager.default.fileExists(atPath: ProcessInfo.processInfo.environment["CROSSOVER263_ROOT"] ?? "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver")))
    func patchesStableBinaries() throws {
        let root = URL(filePath: ProcessInfo.processInfo.environment["CROSSOVER263_ROOT"] ?? "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver")
        let build = try #require(SupportedRunners.build(id: "26.3.0.39832"))
        let patches = try #require(NtdllPatcher.byBuild[build.id])
        for patch in patches {
            let original = try Data(contentsOf: root.appending(path: "lib/wine/\(patch.arch.rawValue)/ntdll.dll"))
            let payload = try NtdllPatcher.payload(for: patch)
            let modified = try NtdllPatcher.apply(patch, to: original, payload: payload)
            #expect(Digest.sha256(of: modified) == build.patchedNtdll[patch.arch])
            let temp = FileManager.default.temporaryDirectory.appending(path: "notproton263-test-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: temp) }
            let source = temp.appending(path: "ntdll.dll")
            let destination = temp.appending(path: "patched.dll")
            var changed = original
            changed[changed.count - 1] ^= 1
            try changed.write(to: source)
            #expect(throws: StepFailure.self) {
                try NtdllPatcher.write(patch, build: build, from: source, to: destination)
            }
            #expect(!FileManager.default.fileExists(atPath: destination.path))
            var corrupted = original
            corrupted[0x3c] = 0xff
            #expect(throws: (any Error).self) {
                try NtdllPatcher.apply(patch, to: corrupted, payload: payload)
            }
        }
    }
}
