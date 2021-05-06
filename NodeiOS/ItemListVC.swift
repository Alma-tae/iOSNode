//
//  ItemListVC.swift
//  NodeiOS
//
//  Created by Sinchon on 2021/05/06.
//

import UIKit

import Alamofire
import Nuke

//DTO 역할을 수행할 구조체 - swift에서는 구조체로 만들음
struct Item{
    var itemid : Int?
    var itemname : String?
    var price : Int?
    var description : String?
    var pictureurl : String?
    var updatedate : String?
}

class ItemListVC: UITableViewController {
    //테이블 뷰에 출력할 데이터 배열
    var itemList = Array<Item>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //네비게이션 바의 타이틀 설정
        title = "데이터 목록"
        
        //파일을 핸들링하기 위한 객체 가져오기
        let fileMgr = FileManager.default
        
        //데이터 베이스 파일 경로 생성
        let docPathURL = fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = docPathURL.appendingPathComponent("item.sqlite").path
        //업데이트 된 시간을 저장할 텍스트 파일 경로 생성
        let updatePath = docPathURL.appendingPathComponent("update.txt").path
        
        //데이터를 다운로드 받을 URL
        let url = "http://192.168.1.148/item/getall"
        
        //데이터베이스 파일이 없으면 다운로드 받아서 저장한 후 출력
        if fileMgr.fileExists(atPath: dbPath) == false{
            //대화상자 출력
            let alert = UIAlertController(title: "데이터 출력", message: "데이터가 없어서 다운로드 받아 출력", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            
            //데이터베이스 파일 생성
            let itemDB = FMDatabase(path: dbPath)
            //데이터베이스 열기
            itemDB.open()
            
            //데이터 다운로드 - get 방식이고 파라미터 없고 결과는 json
            let request = AF.request(url, method: .get, encoding: JSONEncoding.default, headers: nil)
            
            //데이터를 받은 결과를 사용하기
            request.responseJSON{
                response in
                //전체 데이터를 객체로 받기
                if let jsonObject = response.value as? [String:Any]{
                    //데이터를 저장할 테이블 생성
                    let sql = "create table if not exists item(itemid INTEGER not null primary key, itemname text, price INTEGER, description text, pictureurl text, updatedate text)"
                    itemDB.executeStatements(sql)
                    
                    //전체 데이터에서 list 키의 값을 배열로 가져오기
                    //배열은 기본적으로 순회임을 기억!(반복문 필요)
                    let list = jsonObject["list"] as! NSArray
                    //배열의 데이터 순회
                    for index in 0...(list.count - 1){
                        //배열에서 하나씩 가져오기
                        let itemDict = list[index] as! NSDictionary
                        //하나의 DTO 객체를 생성
                        var item = Item()
                        //json 파싱해서 객체에 데이터 대입
                        item.itemid = ((itemDict["itemid"] as! NSNumber).intValue)
                        item.itemname = itemDict["itemname"] as? String
                        item.price = ((itemDict["price"] as! NSNumber).intValue)
                        item.description = itemDict["description"] as? String
                        item.pictureurl = itemDict["pictureurl"] as? String
                        item.updatedate = itemDict["updatedate"] as? String
                        //배열에 추가
                        self.itemList.append(item)
                        
                        //데이터를 삽입할 SQL 생성
                        let sql = "insert into item(itemid, itemname, price, description, pictureurl, updatedate) values(:itemid, :itemname, :price, :description, :pictureurl, :updatedate)"
                        
                        //파라미터 생성
                        var paramDict = [String:Any]()
                        paramDict["itemid"] = item.itemid!
                        paramDict["itemname"] = item.itemname!
                        paramDict["price"] = item.price!
                        paramDict["description"] = item.description!
                        paramDict["pictureurl"] = item.pictureurl!
                        paramDict["updatedate"] = item.updatedate!
                        
                        //sql 실행
                        itemDB.executeUpdate(sql, withParameterDictionary: paramDict)
                    }
                    //반복문 종료
                }
                //데이터 가져와서 파싱하는 문장 종료
                self.tableView.reloadData()
                itemDB.close()
            }
            //다운로드 종료
            //업데이트 받은 시간을 파일에 저장
            
        }
        //데이터베이스 파일이 존재한다면
        else{
            
        }
    }

    // MARK: - Table view data source 테이블 뷰 관련 메서드
    
    //섹션의 개수를 설정하는 메서드 - 선택
    //iOS에서는 그룹을 섹션이라고 함
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    //섹션 별 행의 개수를 설정하는 메서드 - 필수
    //section이 섹션의 인덱스 - 앞에서 1을 리턴하면 0
    //앞에서 2를 리턴하면 0과 1이 됩니다.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemList.count
    }

    //셀을 만들어주는 메서드
    //indexPath.section이 그룹 번호
    //indexPath.row가 행 변호
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //제공되는 셀의 스타일을 이용해서 생성
        //이 이름을 Main.storyboard의 TableViewController의 TableViewCell의 Identifier로 설정해서 사용하는 것을 권장
        let cellIdentifier = "itemCell"
        //재사용 가능한 셀을 찾아옵니다.
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        //재사용 가능한 셀이 없다면 생성
        if cell == nil{
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        //출력할 데이털르 배열에서 찾아오기
        let item = itemList[indexPath.row]

        //데이터를 출력
        cell?.textLabel?.text = item.itemname
        cell?.detailTextLabel?.text = item.description
        //이미지는 다운로드 받아서 출력
        //메인 스레드에서 작업
        //일반 스레드는 UI 갱신을 못함
        //이미지는 다운로드 받아야 하므로 스레드를 사용해야 하기 때문에 다운로드 받은 후 출력을 하려면 Alamofire나 메인 스레드 이용
        DispatchQueue.main.async(execute: {
            //이미지 다운로드 받을 URL 생성
            let url : URL! = URL(string:"http://192.168.1.148/img/\(item.pictureurl!)")
            //Nuke의 옵션 설정
            let options = ImageLoadingOptions(placeholder: UIImage(named: "placeholder"), transition: .fadeIn(duration: 2)
            )
            //Nuke라이브러리로 이비지를 출력
            Nuke.loadImage(with: url, options:options, into: cell!.imageView!)
        })
        
        return cell!
    }
    
}
