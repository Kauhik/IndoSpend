import SwiftUI
import Vision
import UIKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    // Completion returns the recognized total amount and receipt title
    var completion: (_ recognizedAmount: Double, _ recognizedDescription: String) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ReceiptScannerView
        
        init(_ parent: ReceiptScannerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            guard let image = info[.originalImage] as? UIImage,
                  let cgImage = image.cgImage else {
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    print("OCR error: \(error.localizedDescription)")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                
                // Sort observations based on the top of the bounding box (assuming top receipt text is the title)
                let sortedObservations = observations.sorted { (obs1, obs2) -> Bool in
                    let y1 = obs1.boundingBox.origin.y + obs1.boundingBox.size.height
                    let y2 = obs2.boundingBox.origin.y + obs2.boundingBox.size.height
                    return y1 > y2
                }
                
                // Use the top-most recognized text as the receipt title
                let title = sortedObservations.first?.topCandidates(1).first?.string ?? "Unknown Title"
                
                var totalAmount: Double = 0.0
                // Look for a line that contains the word "total" (case-insensitive)
                for observation in observations {
                    if let candidate = observation.topCandidates(1).first {
                        let text = candidate.string
                        if text.lowercased().contains("total") {
                            if let amount = self.extractAmount(from: text) {
                                totalAmount = amount
                                break
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.completion(totalAmount, title)
                }
            }
            
            // Configure the text recognition request
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error.localizedDescription)")
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        // Helper method to extract a numeric amount from a given text using a regular expression
        private func extractAmount(from text: String) -> Double? {
            // This pattern matches numbers with optional decimal places
            let pattern = "\\d+\\.\\d{1,2}|\\d+"
            do {
                let regex = try NSRegularExpression(pattern: pattern)
                let nsText = text as NSString
                let results = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
                // Assuming the last match in the string is the total amount
                if let match = results.last {
                    let amountString = nsText.substring(with: match.range)
                    return Double(amountString)
                }
            } catch {
                print("Regex error: \(error.localizedDescription)")
            }
            return nil
        }
    }
}
