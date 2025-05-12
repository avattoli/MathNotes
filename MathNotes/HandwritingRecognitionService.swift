//
//  HandwritingRecognitionService.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-12.
//

import Foundation
import Vision
import PencilKit
import UIKit

// Global instance for app-wide use
let globalRecognitionService = HandwritingRecognitionService()

class HandwritingRecognitionService {
    
    // Convert a PKDrawing to recognized text
    func recognizeText(from drawing: PKDrawing, completion: @escaping (Result<String, Error>) -> Void) {
        // Create a UIImage from the drawing
        let bounds = drawing.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 1000, height: 1000) : drawing.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(bounds)
            drawing.image(from: bounds, scale: UIScreen.main.scale).draw(in: bounds)
        }
        
        // Perform text recognition
        recognizeText(from: image, completion: completion)
    }
    
    // Recognize text from a UIImage
    private func recognizeText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "HandwritingRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])))
            return
        }
        
        // Create a text recognition request
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "HandwritingRecognition", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get results"])))
                return
            }
            
            // Process the recognized text
            let recognizedText = observations.compactMap { observation -> String? in
                // Get the top candidate
                return observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            completion(.success(recognizedText))
        }
        
        // Configure the request for math recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.customWords = ["∫", "∂", "√", "π", "∞", "∑", "∏", "=", "+", "-", "×", "÷"]
        
        // Create a request handler and perform the request
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
} 