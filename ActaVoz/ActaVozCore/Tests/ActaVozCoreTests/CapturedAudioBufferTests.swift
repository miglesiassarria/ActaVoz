import XCTest
import AVFoundation
import CoreMedia
@testable import ActaVozCore

final class CapturedAudioBufferTests: XCTestCase {
    func testCopiesStereoPlanarAndInterleavedSamples() throws {
        for interleaved in [false, true] {
            let format = try XCTUnwrap(AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 2, interleaved: interleaved))
            let pcm = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 128))
            pcm.frameLength = 128
            for buffer in UnsafeMutableAudioBufferListPointer(pcm.mutableAudioBufferList) {
                let samples = buffer.mData!.assumingMemoryBound(to: Float.self)
                for i in 0..<(Int(buffer.mDataByteSize) / 4) { samples[i] = 0.25 }
            }
            var description: CMAudioFormatDescription?
            XCTAssertEqual(CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: format.streamDescription, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &description), noErr)
            var sample: CMSampleBuffer?
            var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 48000), presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
            XCTAssertEqual(CMSampleBufferCreate(allocator: kCFAllocatorDefault, dataBuffer: nil, dataReady: false, makeDataReadyCallback: nil, refcon: nil, formatDescription: description, sampleCount: 128, sampleTimingEntryCount: 1, sampleTimingArray: &timing, sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &sample), noErr)
            let input = try XCTUnwrap(sample)
            XCTAssertEqual(CMSampleBufferSetDataBufferFromAudioBufferList(input, blockBufferAllocator: kCFAllocatorDefault, blockBufferMemoryAllocator: kCFAllocatorDefault, flags: 0, bufferList: pcm.audioBufferList), noErr)
            CMSampleBufferSetDataReady(input)
            let copied = try XCTUnwrap(CapturedAudioBuffer.copy(input), "interleaved=(interleaved)")
            XCTAssertEqual(copied.frameLength, 128)
            let buffers = UnsafeMutableAudioBufferListPointer(copied.mutableAudioBufferList)
            XCTAssertEqual(buffers.count, interleaved ? 1 : 2)
            for buffer in buffers {
                let samples = buffer.mData!.assumingMemoryBound(to: Float.self)
                for i in 0..<(Int(buffer.mDataByteSize) / 4) { XCTAssertEqual(samples[i], 0.25) }
            }
        }
    }
}
