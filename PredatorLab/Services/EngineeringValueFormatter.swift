import Foundation

enum EngineeringValueFormatter {
    static func display(_ value: EngineeringValue, decimals: Int = 2) -> String {
        guard value.value.isFinite else { return "Missing" }
        return String(format: "%.*f %@", max(0, decimals), value.value, value.unit)
    }
    static func converted(_ value: EngineeringValue, to unit: String) -> EngineeringValue? {
        let from=value.unit.lowercased(), to=unit.lowercased(); var result=value
        switch (value.dimension,from,to) {
        case (.pressure,"psi","kpa"): result.value=value.value*6.894757; result.unit="kPa"
        case (.pressure,"kpa","psi"): result.value=value.value/6.894757; result.unit="psi"
        case (.pressure,"psi","bar"): result.value=value.value*0.06894757; result.unit="bar"
        case (.pressure,"bar","psi"): result.value=value.value/0.06894757; result.unit="psi"
        case (.pressure,"kpa","bar"): result.value=value.value/100; result.unit="bar"
        case (.pressure,"bar","kpa"): result.value=value.value*100; result.unit="kPa"
        case (.temperature,"°f","°c"),(.temperature,"f","c"): result.value=(value.value-32)*5/9; result.unit="°C"
        case (.temperature,"°c","°f"),(.temperature,"c","f"): result.value=value.value*9/5+32; result.unit="°F"
        case (.speed,"mph","km/h"): result.value=value.value*1.609344; result.unit="km/h"
        case (.speed,"km/h","mph"): result.value=value.value/1.609344; result.unit="mph"
        case (.time,"s","ms"): result.value=value.value*1000; result.unit="ms"
        case (.time,"ms","s"): result.value=value.value/1000; result.unit="s"
        case (.angle,"deg","rad"),(.angle,"°","rad"): result.value=value.value*Double.pi/180; result.unit="rad"
        case (.angle,"rad","deg"),(.angle,"rad","°"): result.value=value.value*180/Double.pi; result.unit="deg"
        case (.voltage,"v","mv"): result.value=value.value*1000; result.unit="mV"
        case (.voltage,"mv","v"): result.value=value.value/1000; result.unit="V"
        case (.current,"a","ma"): result.value=value.value*1000; result.unit="mA"
        case (.current,"ma","a"): result.value=value.value/1000; result.unit="A"
        case (.resistance,"ω","kω"),(.resistance,"ohm","kohm"): result.value=value.value/1000; result.unit="kΩ"
        case (.resistance,"kω","ω"),(.resistance,"kohm","ohm"): result.value=value.value*1000; result.unit="Ω"
        case (.torque,"lb-ft","n·m"),(.torque,"lb-ft","nm"): result.value=value.value*1.3558179483; result.unit="N·m"
        case (.torque,"n·m","lb-ft"),(.torque,"nm","lb-ft"): result.value=value.value/1.3558179483; result.unit="lb-ft"
        case (.power,"hp","kw"): result.value=value.value*0.745699872; result.unit="kW"
        case (.power,"kw","hp"): result.value=value.value/0.745699872; result.unit="hp"
        case (.mass,"lb","kg"): result.value=value.value*0.45359237; result.unit="kg"
        case (.mass,"kg","lb"): result.value=value.value/0.45359237; result.unit="lb"
        case (.length,"in","mm"): result.value=value.value*25.4; result.unit="mm"
        case (.length,"mm","in"): result.value=value.value/25.4; result.unit="in"
        default: if from == to { return value } else { return nil }
        }
        return result
    }
}
