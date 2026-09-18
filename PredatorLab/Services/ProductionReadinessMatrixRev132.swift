import Foundation

enum ProductionGateStateRev132:String,Codable,Sendable {case sourceValidated,runtimeRequired,physicalRequired}
struct ProductionGateRev132:Identifiable,Equatable,Sendable {let id:String;let name:String;let state:ProductionGateStateRev132;let requirement:String}
enum ProductionReadinessMatrixRev132 {
 static let gates:[ProductionGateRev132]=[
  .init(id:"static",name:"Source/static integrity",state:.sourceValidated,requirement:"Hygiene, duplicate, iOS surface, routes and Swift parse gates."),
  .init(id:"xcode",name:"Xcode Swift 6 build",state:.runtimeRequired,requirement:"Compile/typecheck on supported Apple toolchain."),
  .init(id:"tests",name:"XCTest/XCUITest",state:.runtimeRequired,requirement:"Execute unit, deterministic Golden Corpus journey and persistence/relaunch tests."),
  .init(id:"perf",name:"100k/1M/5M performance",state:.runtimeRequired,requirement:"Measure frame/render latency and memory on target iPhone/iPad."),
  .init(id:"device",name:"Signed physical iPhone",state:.runtimeRequired,requirement:"Install, launch and exercise primary forensic route."),
  .init(id:"gt500",name:"Physical GT500/MPVI4 campaign",state:.physicalRequired,requirement:"Measure exact configuration behavior and promote only observed/verified evidence."),
  .init(id:"dct",name:"DCT validation",state:.physicalRequired,requirement:"Acquire verified shaft/clutch/gear evidence before slip-energy or phase promotion."),
  .init(id:"can",name:"Raw CAN validation",state:.physicalRequired,requirement:"Controlled passive captures and multi-log candidate verification; no invented IDs/scales.")]
}
