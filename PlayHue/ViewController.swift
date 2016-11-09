//
//  ViewController.swift
//  PlayHue
//
//  Created by Vina Rianti on 9/11/16.
//  Copyright © 2016 Vina Rianti. All rights reserved.
//

import Alamofire
import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var image: UIImageView!
    
    @IBAction func capture(_ sender: UIButton) {
        changeColor()
    }
    
    func changeColor() {
        let imagePicker: UIImagePickerController = UIImagePickerController()
        imagePicker.delegate = self
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Application cannot access the camera.")
            return
        }
        
        guard (UIImagePickerController.availableCaptureModes(for: .rear) != nil) else {
            print("Camera not found")
            return
        }
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        imagePicker.cameraDevice = .rear
        imagePicker.modalPresentationStyle = .overCurrentContext
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.image.contentMode = .scaleAspectFit
            self.image.image = pickedImage
            let averageColor = UIImage.areaAverage(pickedImage)
            print(averageColor)
            self.view.backgroundColor = averageColor()
            
            let hueColor = averageColor()
            let array = hueColor.XYColor()
            
            // Send request to Bulb to change color
            
            let url = "http://10.10.43.119/api/zoG5NHui7WTIgaJQUkEDl51Rl1xTqYHhyy8wtKVV/lights/2/state"
            let data: [String: Any] = [
                "on": true,
                "xy": [array[0], array[1]]
            ]
            
           
//            Alamofire.request(url, parameters: data, method: .put).responseJSON { response in
//                print(response)
//            }
            
            Alamofire.request(url, method: .put, parameters: data, encoding: JSONEncoding.default).responseJSON(completionHandler: {response in
                
                print(response)
            })
            
        }
        
        
        
//        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
//        let imageData = UIImageJPEGRepresentation(image, 0.8)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension UIColor {
    
    var redValue: CGFloat? {
        return self.cgColor.components?[0]
    }
    
    var greenValue: CGFloat? {
        return self.cgColor.components?[1]
    }
    
    var blueValue: CGFloat? {
        return self.cgColor.components?[2]
    }
    
    var alphaValue: CGFloat? {
        return self.cgColor.components?[3]
    }
    
    func XYColor() -> Array<Double> {
        
        var normalizedToOne: [Double] = []
        
        normalizedToOne.append(Double(self.redValue!))
        normalizedToOne.append(Double(self.greenValue!))
        normalizedToOne.append(Double(self.blueValue!))
        
        var red: Float
        var green: Float
        var blue: Float
        
        // Make red more vivid
        if (normalizedToOne[0] > 0.04045) {
            red = pow((Float(normalizedToOne[0]) + 0.055) / (1.0 + 0.055), 2.4)
        } else {
            red = Float(normalizedToOne[0]) / 12.92
        }
        
        // Make green more vivid
        if (normalizedToOne[0] > 0.04045) {
            green = pow((Float(normalizedToOne[1]) + 0.055) / (1.0 + 0.055), 2.4)
        } else {
            green = Float(normalizedToOne[1]) / 12.92
        }
        
        // Make blue more vivid
        if (normalizedToOne[0] > 0.04045) {
            blue = pow((Float(normalizedToOne[2]) + 0.055) / (1.0 + 0.055), 2.4)
        } else {
            blue = Float(normalizedToOne[2]) / 12.92
        }
        
        let xValue = Double(red * 0.649926 + green * 0.103455 + blue * 0.197109)
        let yValue = Double(red * 0.234327 + green * 0.743075 + blue * 0.022598)
        let zValue = Double(red * 0.0000000 + green * 0.053077 + blue * 1.035763)
        
        let x = xValue / (xValue + yValue + zValue)
        let y = yValue / (xValue + yValue + zValue)
        
        var array: [Double] = []
        array.append(x)
        array.append(y)
        
        return array
    }
}

extension UIImage {
    
    func areaAverage() -> UIColor {
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        let context = CIContext(options: nil)
        let cgImg = context.createCGImage(CoreImage.CIImage(cgImage: self.cgImage!), from: CoreImage.CIImage(cgImage: self.cgImage!).extent)
        
        let inputImage = CIImage(cgImage: cgImg!)
        let extent = inputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
        let outputImage = filter.outputImage!
        let outputExtent = outputImage.extent
        assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
        
        // Render to bitmap.
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }
    
}
