// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

struct ScannerConfiguredChannel:Identifiable,Equatable,Sendable {
    let id:String
    let displayName:String
    let parameterID:String?
    let source:String?
    let pollingInterval:String?
    let transform:String?
}

struct ScannerConfigurationAnalysis:Equatable,Sendable {
    let channels:[ScannerConfiguredChannel]
    let warnings:[String]
    let provenance:String
    let boundary:String
}

enum VCMScannerConfigurationAnalyzer {
    /// Tolerant metadata extraction for user-supplied Scanner XML. It does not claim a universal HP Tuners schema.
    static func analyze(data:Data,provenance:String)->ScannerConfigurationAnalysis {
        #if canImport(FoundationXML)
        let delegate=ScannerXMLDelegate()
        let parser=XMLParser(data:data);parser.delegate=delegate
        let ok=parser.parse()
        let warning=ok ? []:["XML parser reported an error; extracted metadata may be incomplete."]
        return .init(channels:delegate.channels,warnings:warning,provenance:provenance,
                     boundary:"Extracted names/IDs/source/polling/transform are artifact metadata. Presence does not establish vehicle applicability or semantic correctness.")
        #else
        return .init(channels:[],warnings:["FoundationXML unavailable in this build environment."],provenance:provenance,
                     boundary:"No XML semantics inferred.")
        #endif
    }
}

#if canImport(FoundationXML)
private final class ScannerXMLDelegate:NSObject,XMLParserDelegate {
    var channels:[ScannerConfiguredChannel]=[]
    private var attrs:[String:String]=[:]
    private var text=""
    private var depth=0
    func parser(_ parser:XMLParser,didStartElement elementName:String,namespaceURI:String?,qualifiedName qName:String?,attributes attributeDict:[String:String]=[:]) {
        depth += 1;text="";attrs=attributeDict
        let lower=elementName.lowercased()
        if lower.contains("channel") || lower.contains("parameter") {
            let name=attributeDict.firstValue(keys:["name","displayname","label"]) ?? elementName
            let pid=attributeDict.firstValue(keys:["id","parameterid","pid"])
            let source=attributeDict.firstValue(keys:["source","module"])
            let poll=attributeDict.firstValue(keys:["pollinginterval","interval","pollrate"])
            let transform=attributeDict.firstValue(keys:["transform","expression"])
            if pid != nil || attributeDict.count > 1 {
                channels.append(.init(id:"xml-\(channels.count)",displayName:name,parameterID:pid,source:source,pollingInterval:poll,transform:transform))
            }
        }
    }
    func parser(_ parser:XMLParser,foundCharacters string:String){text += string}
    func parser(_ parser:XMLParser,didEndElement elementName:String,namespaceURI:String?,qualifiedName qName:String?){depth=max(0,depth-1)}
}
private extension Dictionary where Key==String,Value==String {
    func firstValue(keys:[String])->String? {
        for key in keys { if let x=first(where:{$0.key.lowercased()==key})?.value{return x} }
        return nil
    }
}
#endif
