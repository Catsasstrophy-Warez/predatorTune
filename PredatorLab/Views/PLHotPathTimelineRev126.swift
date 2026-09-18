import SwiftUI

struct PLHotPathTimelineRev126:View {
 let series:[TimelineSeriesRev117];let cursor:Double;let windowStart:Double;let windowEnd:Double
 var body:some View{PLInstrumentChrome{VStack(alignment:.leading,spacing:4){
  HStack{Text("SYNCHRONIZED FORENSIC TIMELINE").font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(.plBoost);Spacer();Text(String(format:"%.3f s",cursor)).font(.system(size:7,weight:.bold,design:.monospaced))}
  GeometryReader{g in let frame=TimelineRenderPipelineRev126.frame(series:Array(series.prefix(8)),start:windowStart,end:windowEnd,cursor:cursor,pixelWidth:Int(max(1,g.size.width)))
   Canvas{ctx,size in guard frame.end>frame.start else{return};for band in frame.bands {let span=max(band.maximum-band.minimum,0.000001);var minPath=Path(),maxPath=Path()
    for (i,e) in band.envelopes.enumerated(){let x=((e.start+e.end)/2-frame.start)/(frame.end-frame.start)*size.width;let ymin=size.height-(e.minimum-band.minimum)/span*size.height;let ymax=size.height-(e.maximum-band.minimum)/span*size.height;if i==0{minPath.move(to:.init(x:x,y:ymin));maxPath.move(to:.init(x:x,y:ymax))}else{minPath.addLine(to:.init(x:x,y:ymin));maxPath.addLine(to:.init(x:x,y:ymax))}}
    ctx.stroke(minPath,with:.foreground,lineWidth:0.55);ctx.stroke(maxPath,with:.foreground,lineWidth:0.55)}
    let x=(frame.cursor-frame.start)/(frame.end-frame.start)*size.width;var p=Path();p.move(to:.init(x:x,y:0));p.addLine(to:.init(x:x,y:size.height));ctx.stroke(p,with:.foreground,lineWidth:1)
   }.accessibilityIdentifier("forensic.timeline.canvas")
  }.frame(height:170)
  Text("Extrema-preserving envelopes keep spikes visible while bounding render work. Cursor/window selection never changes evidence authority.").font(.system(size:7)).foregroundStyle(.plTextSecondary)
 }}}
}
