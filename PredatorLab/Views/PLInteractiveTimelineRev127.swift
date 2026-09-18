import SwiftUI
struct PLInteractiveTimelineRev127:View {
 let series:[TimelineSeriesRev117];let episodes:[GT500EpisodeRev122];let totalStart:Double;let totalEnd:Double
 @Binding var viewport:TimelineViewportRev127
 @State private var gestureStart:TimelineViewportRev127?
 var body:some View{VStack(alignment:.leading,spacing:5){
  PLHotPathTimelineRev126(series:series,cursor:viewport.cursor,windowStart:viewport.start,windowEnd:viewport.end)
   .overlay(GeometryReader{g in Color.clear.contentShape(Rectangle())
    .gesture(DragGesture(minimumDistance:0).onChanged{x in
     if gestureStart==nil{gestureStart=viewport};guard let base=gestureStart else{return};let ratio=min(max(x.location.x/max(g.size.width,1),0),1);let t=base.start+ratio*(base.end-base.start)
     viewport.cursor=TimelineInteractionRev127.snapCursor(t,episodes:episodes,tolerance:max(0.04,base.duration*0.015))
    }.onEnded{_ in gestureStart=nil})
    .simultaneousGesture(MagnificationGesture().onChanged{scale in guard scale>0 else{return};viewport=TimelineInteractionRev127.zoom(viewport,factor:1/scale,anchor:viewport.cursor,totalStart:totalStart,totalEnd:totalEnd)})
   })
  HStack{Button("−"){viewport=TimelineInteractionRev127.zoom(viewport,factor:1.6,anchor:viewport.cursor,totalStart:totalStart,totalEnd:totalEnd)}
   Button("＋"){viewport=TimelineInteractionRev127.zoom(viewport,factor:0.625,anchor:viewport.cursor,totalStart:totalStart,totalEnd:totalEnd)}
   Button("◀"){viewport=TimelineInteractionRev127.pan(viewport,delta:-viewport.duration*0.5,totalStart:totalStart,totalEnd:totalEnd)}
   Button("▶"){viewport=TimelineInteractionRev127.pan(viewport,delta:viewport.duration*0.5,totalStart:totalStart,totalEnd:totalEnd)}
   Spacer();Text(String(format:"WINDOW %.2f s",viewport.duration)).font(.system(size:7,weight:.bold,design:.monospaced))}
  ScrollView(.horizontal,showsIndicators:false){HStack{ForEach(series.prefix(8)){s in let b=EvidenceAuthorityPresentationRev127.badge(channel:s.id);Text("\(b.authority.rawValue) · \(s.id)").font(.system(size:7,weight:.bold,design:.monospaced)).padding(.horizontal,6).padding(.vertical,3).overlay(RoundedRectangle(cornerRadius:3).stroke(Color.plStroke))}}}
 }.accessibilityIdentifier("forensic.timeline.interactive")}
}
