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
                // Naively parse the transcript:
                // Expecting format: "<amount> <description...>"
                let components = transcript.components(separatedBy: " ")
                let amount = Double(components.first ?? "") ?? 0.0
                let description = components.dropFirst().joined(separator: " ")
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
}
