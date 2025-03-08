import SwiftUI
import Speech
import AVFoundation

struct VoiceInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isRecording = false
    @State private var transcript = ""
    
    // Completion returns a parsed amount and description
    var completion: (_ recognizedAmount: Double, _ recognizedDescription: String) -> Void
    
    // Speech recognition properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var body: some View {
        VStack {
            Text("Speak your expense")
                .font(.headline)
                .padding()
            Text(transcript)
                .padding()
            
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Image(systemName: isRecording ? "stop.circle" : "mic.circle")
                    .resizable()
                    .frame(width: 60, height: 60)
            }
            .padding()
            
            Button("Done") {
                let (amount, description) = parseTranscript(transcript)
                completion(amount, description)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .onAppear {
            requestSpeechAuthorization()
        }
    }
    
    func startRecording() {
        transcript = ""
        isRecording = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                transcript = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal ?? false) {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start: \(error)")
        }
    }
    
    func stopRecording() {
        isRecording = false
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus != .authorized {
                print("Speech recognition not authorized")
            }
        }
    }
    
    // Helper function to parse the transcript into an amount and a description.
    // This expects the transcript to begin with a number (which can include commas or spaces)
    // followed by the rest of the description.
    func parseTranscript(_ transcript: String) -> (Double, String) {
        let pattern = #"^([\d,\.\s]+)(.*)$"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsTranscript = transcript as NSString
            if let match = regex.firstMatch(in: transcript, range: NSRange(location: 0, length: nsTranscript.length)),
               match.numberOfRanges >= 3 {
                let amountString = nsTranscript.substring(with: match.range(at: 1))
                let descriptionString = nsTranscript.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                // Remove commas and spaces to normalize the number
                let cleanedAmount = amountString.replacingOccurrences(of: "[,\\s]", with: "", options: .regularExpression)
                let amount = Double(cleanedAmount) ?? 0.0
                return (amount, descriptionString)
            }
        } catch {
            print("Regex error: \(error.localizedDescription)")
        }
        // Fallback in case regex fails: split by spaces
        let components = transcript.components(separatedBy: " ")
        let amount = Double(components.first ?? "") ?? 0.0
        let description = components.dropFirst().joined(separator: " ")
        return (amount, description)
    }
}
