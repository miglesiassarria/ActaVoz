import Foundation
import AVFoundation
@main struct Test {
 static func main() async throws {
  let root=URL(fileURLWithPath:CommandLine.arguments[1]).appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
  defer { try? FileManager.default.removeItem(at: root) }
  let first=UUID(), second=UUID(); var paths:[URL]=[]
  for (source,id,freq,start,duration) in [(CaptureSource.microphone,first,440.0,0.0,3.0),(.system,first,880.0,0.5,2.0),(.microphone,second,1320.0,3.0,2.0)] {
   let name=(source == .microphone ? "microfono-" : "sistema-")+id.uuidString+".caf";let url=root.appendingPathComponent(name)
   let fmt=AVAudioFormat(standardFormatWithSampleRate:48000,channels:1)!;let count=AVAudioFrameCount(duration*48000)
   let buf=AVAudioPCMBuffer(pcmFormat:fmt,frameCapacity:count)!;buf.frameLength=count
   for i in 0..<Int(count){buf.floatChannelData![0][i]=Float(0.2*sin(2*Double.pi*freq*Double(i)/48000))}
   do{let file=try AVAudioFile(forWriting:url,settings:fmt.settings);try file.write(from:buf)}
   try AudioTimelineFragment(source:source,segmentID:id,spans:[.init(fileStart:0,sessionStart:start,duration:duration)]).save(for:url);paths.append(url)
  }
  let output=root.appendingPathComponent("combined.m4a");try await CompositionAudioFinalizer().combine(paths,to:output)
  let file=try AVAudioFile(forReading:output);let buf=AVAudioPCMBuffer(pcmFormat:file.processingFormat,frameCapacity:AVAudioFrameCount(file.length))!;try file.read(into:buf)
  let samples=buf.floatChannelData![0];let rate=file.processingFormat.sampleRate
  func amplitude(_ freq:Double,_ from:Double,_ to:Double)->Double{var re=0.0, im=0.0;let start=Int(from*rate),end=Int(to*rate);for i in start..<end {let angle=2*Double.pi*freq*Double(i)/rate;re+=Double(samples[i])*cos(angle);im+=Double(samples[i])*sin(angle)};return 2*hypot(re,im)/Double(end-start)}
  let a=amplitude(440,0.7,1.7),b=amplitude(880,0.7,1.7),c=amplitude(1320,3.3,4.5),leak=amplitude(440,3.3,4.5)
  print("duration=\(Double(file.length)/rate) 440=\(a) 880=\(b) 1320=\(c) late440=\(leak)")
  guard abs(Double(file.length)/rate-5)<0.1,a>0.04,b>0.04,c>0.04,leak<c/5 else {throw CaptureError.driverFailed("Cronología incorrecta")}
 }
}
