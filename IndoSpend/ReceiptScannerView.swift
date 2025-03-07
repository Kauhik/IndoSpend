import SwiftUI
import Vision
import UIKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    // Completion returns a recognized amount and description from the receipt
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
            if let image = info[.originalImage] as? UIImage {
                // Here you would perform OCR using the Vision framework.
                // For demonstration, we simulate a recognized expense.
                let recognizedAmount: Double = 20.0
                let recognizedDescription: String = "Receipt OCR"
                
                DispatchQueue.main.async {
                    self.parent.completion(recognizedAmount, recognizedDescription)
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
