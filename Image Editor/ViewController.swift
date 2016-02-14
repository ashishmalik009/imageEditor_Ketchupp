//
//  ViewController.swift
//  Image Editor
//
//  Created by Ashish Malik on 13/02/16.
//  Copyright © 2016 Ashish Malik. All rights reserved.
//

import UIKit
import AVFoundation

func loadShutterSoundPlayer() -> AVAudioPlayer?
{
    let theMainBundle = NSBundle.mainBundle()
    let filename = "Shutter sound"
    let fileType = "mp3"
    let soundfilePath: String? = theMainBundle.pathForResource(filename,
        ofType: fileType,
        inDirectory: nil)
    if soundfilePath == nil
    {
        return nil
    }
    //println("soundfilePath = \(soundfilePath)")
    let fileURL = NSURL.fileURLWithPath(soundfilePath!)
    var error: NSError?
    let result: AVAudioPlayer?
    do {
        result = try AVAudioPlayer(contentsOfURL: fileURL)
    } catch let error1 as NSError {
        error = error1
        result = nil
    }
    if let requiredErr = error
    {
        print("AVAudioPlayer.init failed with error \(requiredErr.debugDescription)")
    }

    result?.prepareToPlay()
    return result
}


class ViewController: UIViewController , UINavigationControllerDelegate, UIImagePickerControllerDelegate,CroppableImageViewDelegateProtocol,UIPopoverControllerDelegate
{
    @IBOutlet var selectImageButton: UIButton!
    @IBOutlet weak var whiteView: UIView!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var cropView: CroppableImageView!
    
    var shutterSoundPlayer = loadShutterSoundPlayer()
    var imagePicker = UIImagePickerController()
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.imagePicker.delegate = self;

    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    enum ImageSource: Int
    {
        case Camera = 1
        case PhotoLibrary
    }
    
    
    
    //MARK:-IBAction Methods
    
    @IBAction func rotateImage(sender: AnyObject)
    {
        self.cropView.imageToCrop = self.imageRotatedByDegrees(90, flip: false);

    }
    
    
    @IBAction func handleSelectImgButton(sender: UIButton)
    {
     // Option to use camera won't be visible on simulator as simlutor doesnt allow to open camera.
        let deviceHasCamera: Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)

        
        //Create an alert controller that asks the user what type of image to choose.
        let anActionSheet = UIAlertController(title: "Pick Image Source",
            message: nil,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        
        //If the current device has a camera, add a "Take a New Picture" button
        var takePicAction: UIAlertAction? = nil
        if deviceHasCamera
        {
            takePicAction = UIAlertAction(
                title: "Take a New Picture",
                style: UIAlertActionStyle.Default,
                handler:
                {
                    (alert: UIAlertAction)  in
                    self.pickImageFromSource(
                        ImageSource.Camera,
                        fromButton: sender)
                }
            )
        }
        
        //Allow the user to selecxt an amage from their photo library
        let selectPicAction = UIAlertAction(title:"Select Picture from library",style: UIAlertActionStyle.Default,handler:
            {
                (alert: UIAlertAction)  in
                self.pickImageFromSource(
                    ImageSource.PhotoLibrary,
                    fromButton: sender)
            }
        )
        
        let cancelAction = UIAlertAction(
            title:"Cancel",
            style: UIAlertActionStyle.Cancel,
            handler:
            {
                (alert: UIAlertAction)  in

            }
        )
       
        
        if let requiredtakePicAction = takePicAction
        {
            anActionSheet.addAction(requiredtakePicAction)
        }
        anActionSheet.addAction(selectPicAction)
        anActionSheet.addAction(cancelAction)
        
        let popover = anActionSheet.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = sender.bounds;
        
        self.presentViewController(anActionSheet, animated: true){}
        
    }
    
    @IBAction func handleCropButton(sender: UIButton)
    {
        if let croppedImage = cropView.croppedImage()
        {
            self.whiteView.hidden = false
            delay(0)
                {
                    self.shutterSoundPlayer?.play()
                    self.cropView.imageToCrop = croppedImage;
                    
                    delay(0.2)
                        {
                            self.whiteView.hidden = true
                            self.shutterSoundPlayer?.prepareToPlay()
                    }
            }
            
            
        }
    }

    
    @IBAction func saveImageToGallery(sender: UIBarButtonItem)
    {
        if(self.cropView.imageToCrop != nil)
        {
        UIImageWriteToSavedPhotosAlbum(self.cropView.imageToCrop!, nil, nil, nil);
        let alert = UIAlertController(title: "Image Editor", message: "Image Saved To Gallery", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        }
     
    }
   
    //MARK:-pick Image
    func pickImageFromSource(theImageSource:ImageSource,fromButton:UIButton)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        switch theImageSource
        {
        case .Camera:
        print("User chose take new pic button")
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.Front;
            
        case .PhotoLibrary:
        print("User chose select pic button")
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        }
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad
        {
            if theImageSource == ImageSource.Camera
            {
            self.presentViewController(imagePicker,animated: true){}
            }
            else
            {
            self.presentViewController(imagePicker,animated: true){}
            }
        }
        else
        {
            self.presentViewController(imagePicker,animated: true){}
        }
    }

    
    
    // MARK: - CroppableImageViewDelegateProtocol methods -
    //-------------------------------------------------------------------------------------------------------
    
    func haveValidCropRect(haveValidCropRect:Bool)
    {
        //println("In haveValidCropRect. Value = \(haveValidCropRect)")
        cropButton.enabled = haveValidCropRect
    }
    //-------------------------------------------------------------------------------------------------------
    // MARK: - UIImagePickerControllerDelegate methods -
    //-------------------------------------------------------------------------------------------------------
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        print("In \(__FUNCTION__)")
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
            cropView.imageToCrop = image
        }
        //cropView.setNeedsLayout()
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        print("In \(__FUNCTION__)")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //MARK:-Image Rotation By Degrees
    
    func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: self.cropView.frame.size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-self.cropView.frame.size.width / 2, -self.cropView.frame.size.height / 2, self.cropView.frame.size.width, self.cropView.frame.size.height), self.cropView.imageToCrop?.CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    

    
}








