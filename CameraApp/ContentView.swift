//
//  ContentView.swift
//  Camera2
//
//  Created by 何特 on 2021/08/17.
//

import SwiftUI
import AVFoundation
struct CameraView: View {
    @StateObject var camera = CameraModel()
    var body: some View {
        ZStack{
            
            
    //    Color.black
            CameraPreview(camera: camera)
                // 这个CameraPreview()是无视了安全区的，把它注释掉
//                .ignoresSafeArea()
            
            // 在这里加一个不限制大小的长方形，就把整个CameraPreview()遮挡了
//            Rectangle()
//                .fill(Color.black)
//                .ignoresSafeArea()
            
            // 下面就是各种按钮
            VStack{
                
                if camera.isTaken{
                    HStack{
                    Spacer()
//                        Text("屏幕右上角的图标")
                        Button(action: camera.reTake, label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            
                    }).padding(.trailing,10)
                }
                    Spacer()
                }
                Spacer()
                HStack{
                    if camera.isTaken{
//                        Text("拍照之后的保存按钮")
                        Button(action: {
                            if !camera.isSaved{
                                camera.savePic()
                            }
                        }, label: {
                            Text(camera.isSaved ? "Saved" : "Save")
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                                .padding(.vertical,10)
                                .padding(.horizontal,20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }).padding(.leading)
                        Spacer()
                        
                    }else{
                        // 这里就是拍照的摄像头预览界面
                        
                        ZStack{
                            // 我在这里加了一个蓝色正方形，理论上这里可以加入比方浏览器界面或者电子书
                            // 来遮挡摄像头预览
//                            Rectangle()
//                                .fill(Color.black)
//                                .frame(width: 300, height: 300, alignment: .center)
                            
                            // 这是拍照按钮
                            Button(action: {
                                camera.takePic()
                                if !camera.isSaved{
                                    camera.savePic()
                                }
                                camera.reTakeChange()
                                
                            }, label: {
//                                ZStack{
                                    // 原来是圆形拍照按钮，我现在把它换成其他小图标
//                                    Circle()
//                                        .fill(Color.white)
//                                        .frame(width: 65, height: 65, alignment: .center)
//                                    Circle()
//                                        .stroke(Color.white,lineWidth: 2)
//                                        .frame(width: 75, height: 75, alignment: .center)
                                    
//                                }
                                Image(systemName: "camera.metering.spot")
                                    .foregroundColor(Color.gray)
                                
                            })
                            
                        }
                        
                        
                        
                        
                    }
                }.frame(height: 75)
            }
        }.onAppear(perform: {
            camera.check()
        }).alert(isPresented: $camera.alert){
            Alert(title: Text("Enable camera"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}


class CameraModel : NSObject, ObservableObject, AVCapturePhotoCaptureDelegate{
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    
    @Published var preview : AVCaptureVideoPreviewLayer!
    
    @Published var isSaved = false
    @Published var picData = Data(count:0)
    
    func check(){
        // 这是一进入App就调用的func，也就是摄像头的浏览画面
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined :
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status{
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    func setUp(){
        do{
            self.session.beginConfiguration()
         
            // 这个position是摄像头前置/后置的意思 .back .front
            guard let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: .back) else {
                return
            }
            let input = try AVCaptureDeviceInput(device: device)
            if self.session.canAddInput(input){
                print("input taken")
                self.session.addInput(input)
            }else{
                print("input not  taken")
            }
            if self.session.canAddOutput(output){
                print("output taken")
                self.session.addOutput(output)
            }
            self.session.commitConfiguration()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func takePic(){
         self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
         DispatchQueue.global(qos: .background).async {
            // 这里self.session.stopRunning()注释掉
//             self.session.stopRunning()
            
             DispatchQueue.main.async {
                 withAnimation{
                     self.isTaken.toggle()
 
                 }
             }
         }
     }
 
     func reTake(){
 
         DispatchQueue.global(qos: .background).async {
             self.session.startRunning()
             DispatchQueue.main.async {
                 withAnimation{
                     self.isTaken.toggle()
 
                 }
                     self.isSaved=false
                     self.picData=Data(count: 0)
 
             }
         }
     }
 
    func reTakeChange(){
        DispatchQueue.global(qos: .background).async {
//            self.session.startRunning()
            DispatchQueue.main.async {
                    self.isTaken.toggle()
                    self.isSaved = false
                    self.picData = Data(count: 0)

            }
        }
    }
    
     func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
         if error != nil{
             return
         }
         print("picture taken")
         guard let imageData = photo.fileDataRepresentation() else {
             return
         }
         self.picData = imageData
     }
 
     func savePic(){
         guard let image = UIImage(data: self.picData) else{return}
         //saving image
         UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
         self.isSaved = true
         print("pic saved")
     }
 
}

struct CameraPreview : UIViewRepresentable{
    @ObservedObject var camera : CameraModel
    func makeUIView(context:Context) -> UIView {
        let view = UIView(frame:UIScreen.main.bounds)
        camera .preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        self.camera.session.startRunning()
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
