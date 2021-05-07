//
//  ItemAddVC.swift
//  NodeiOS
//
//  Created by Sinchon on 2021/05/07.
//

import UIKit
import Alamofire

class ItemAddVC: UIViewController {
    @IBAction func btnSave(_ sender: Any) {
        //서버의 URL - http://192.168.1.143/item.insert
        //전송 방식 - post
        //파라미터 - itemname, price, description, membernickname, pictureurl(파일)
        //결과는 {result:true 또는 false}
        //입력된 내용을 가져옵니다.
        let itemname = tfItemName.text
        let price = tfPrice.text
        let description = tvDescription.text
        let membernickname = "아담"
        
        //이미지
        let image = imgPictureUrl.image
        //이미지를 데이터로 변환
        //let imageData = image?.pngData()
        //png는 압축이 아니고, jpeg는 압축이 아니라서 압축 비율을 줘야 함
        //압축 비율이 높아지면 용량 많이 잡아 먹지만 화질은 좋음
        let imageData = image?.jpegData(compressionQuality: 0.5)
        
        //업로드
        AF.upload(multipartFormData:{
            multipartData in
            multipartData.append(Data(itemname!.utf8), withName:"itemname")
            multipartData.append(Data(price!.utf8), withName:"price")
            multipartData.append(Data(description!.utf8), withName:"description")
            multipartData.append(Data(membernickname.utf8), withName:"membernickname")
            multipartData.append(imageData!, withName:"pictureurl", fileName:"pear.jpeg", mimeType:"image/jpeg")
        }, to:"http://192.168.1.148/item/insert").responseJSON{
            response in
            if let jsonObject = response.value as? [String:Any]{
                let result = jsonObject["result"] as! Int32
                if result == 1{
                    print("삽입 성공")
                    self.navigationController?.popViewController(animated: true)
                }else{
                    print("삽입 실패")
                }
            }
        }
        
    }
   
    @IBAction func btnCancel(_ sender: Any) {
        //네비게이션 컨트롤러를 이용해서 push로 이동한 경우, 제자리로 돌아가기
        navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var imgPictureUrl: UIImageView!
    @IBOutlet weak var tvDescription: UITextView!
    @IBOutlet weak var tfPrice: UITextField!
    @IBOutlet weak var tfItemName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "아이템 추가"
        
        tvDescription.text = ""
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
