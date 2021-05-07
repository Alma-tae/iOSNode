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
    }

    //뷰가 보여질 때 호출되는 메서드
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //네비게이션 바의 왼쪽에 editButton을 배치
        navigationItem.leftBarButtonItem = editButtonItem
        
        //파일을 핸들링하기 위한 객체 가져오기
        let fileMgr = FileManager.default
        
        //데이터 베이스 파일 경로 생성
        let docPathURL = fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = docPathURL.appendingPathComponent("item.sqlite").path
        
        //로그인 처리
        //로그인 관련 파일의 경로를 생성
        let loginPath = docPathURL.appendingPathComponent("login.txt").path
        //로그인 한 상태
        var loginBtnTitle = ""
        if fileMgr.fileExists(atPath: loginPath){
            loginBtnTitle = "로그아웃"
            //파일의 내용을 읽어서 두번째 저장한 nickname을 찾아옵니다
            let databuffer = fileMgr.contents(atPath: loginPath)
            let logintext = String(bytes: databuffer!, encoding: .utf8)
            let ar = logintext?.components(separatedBy:":")
            self.title = ar![1]
        }
        //로그아웃된 상태
        else{
            loginBtnTitle = "로그인"
        }
        
        //바버튼 아이템 생성
        let loginBarButtonItem = UIBarButtonItem(title: loginBtnTitle, style: .done, target: self, action: #selector(login(_:)))
        let addBarButtonItem = UIBarButtonItem(title: "추가", style: .done, target: self, action: #selector(add(_:)))
        
        //네비게이션 바의 오른쪽에 바버튼 아이템 배치
        self.navigationItem.rightBarButtonItems = [addBarButtonItem, loginBarButtonItem]
        
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
            
            //업데이트 된 시간 정보를 서버에서 받아오기
            let updateurl = "http://192.168.1.148/item/lastupdatetime"
            //JSON 데이터를 get 방식으로 다운로드
            let updaterequest = AF.request(updateurl, method: .get, encoding: JSONEncoding.default, headers: [:])
            updaterequest.responseJSON{
                response in
                //받은 데이터를 NXDictionary로 변환
                if let jsonObject = response.value as? [String:Any]{
                    //result 키의 값을 문자열로 가져오기
                    let result = jsonObject["result"] as? String
                    
                    //result를 파일에 기록
                    let dataBuffer = result!.data(using: String.Encoding.utf8)
                    fileMgr.createFile(atPath: updatePath, contents: dataBuffer, attributes: nil)
                    
                }
            }
            
        }
        //데이터베이스 파일이 존재한다면
        else{
            //업데이트 된 시간을 기록한 파일의 경로를 이용해서 데이터 읽어오기
            let databuffer = fileMgr.contents(atPath: updatePath)
            let updatetime = NSString(data: databuffer!, encoding: String.Encoding.utf8.rawValue) as String?
            //서버에서 업데이트 된 시간을 찾아오기
            let updateurl = "http://192.168.1.148/item/lastupdatetime"
            //JSON 데이터를 get 방식으로 다운로드
            let updaterequest = AF.request(updateurl, method: .get, encoding: JSONEncoding.default, headers: [:])
            //받아온 데이터를 읽기
            updaterequest.responseJSON{
                response in
                if let jsonObject = response.value as? [String:Any]{
                    let result = jsonObject["result"] as? String
                    //로컬에 저장돈 시간과 서버의 시간을 비교
                    //서버의 시간과 로컬의 시간이 같다면 다운로드 받지 않고 SQLite의 내용을 그대로 출력
                    if updatetime == result{
                        let alert = UIAlertController(title: "server data 사용", message: "서버의 시간과 로컬의 시간이 같아서 로컬의 데이터 출력", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default))
                        self.present(alert, animated: true)
                        
                        //저장해놓은 데이터베이스 파일의 내용 읽기
                        let itemDB = FMDatabase(path: dbPath)
                        itemDB.open()
                        
                        do{
                            let sql = """
                                select *
                                from item
                                order by itemid asc
                            """
                            
                            //sql 실행
                            let rs = try itemDB.executeQuery(sql, values: nil)
                            
                            //결과를 순회
                            while rs.next(){
                                var item = Item()
                                
                                item.itemid = Int(rs.int(forColumn: "itemid"))
                                item.itemname = rs.string(forColumn: "itemname")
                                item.price = Int(rs.int(forColumn: "price"))
                                item.description = rs.string(forColumn: "description")
                                item.pictureurl = rs.string(forColumn: "pictureurl")
                                item.updatedate = rs.string(forColumn: "updatedate")
                                
                                //데이터를 list에 저장
                                self.itemList.append(item)
                            }
                            //테이블 뷰 다시 출력
                            self.tableView.reloadData()
                        }catch let error as NSError{
                            NSLog("데이터베이스 읽기 실패:\(error .localizedDescription)")
                        }
                        //데이터베이스 닫기
                        itemDB.close()
                    }
                    //서버의 시간과 로컬의 시간이 같지 않다면 데이터를 다시 다운로드 받아서 출력
                    else{
                        let alert = UIAlertController(title: "server data 사용", message: "서버의 시간과 로컬의 시간이 달라서 다시 다운로드", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default))
                        self.present(alert, animated: true)
                        
                        //기존 데이터를 전부 지우고 새로 다운로드
                        
                        //기존에 저장해 둔 데이터를 전부 삭제
                        try! fileMgr.removeItem(atPath : dbPath)
                        try! fileMgr.removeItem(atPath : updatePath)
                        self.itemList.removeAll()
                        
                        //데이터베이스를 다시 생성하고 열기
                        let itemDB = FMDatabase(path: dbPath)
                        itemDB.open()
                        
                        //테이블 생성
                        let sql = "create table if not exists item(itemid integer not null primary key, itemname text, price integer, description text, pictureurl test, updatedate text)"
                        itemDB.executeStatements(sql)
                        
                        //서버에서 데이터 읽어오기
                        //url = "http://192.168.1.143/item.getall"
                        //210처럼 하거나 아래처럼 쓰거나.
                        let request = AF.request(url, method: .get, encoding: JSONEncoding.default, headers: [:])
                        request.responseJSON{
                            response in
                            if let jsonObject = response.value as? [String:Any]{
                                //디셔너리에서 list 키의 데이터를 배열로 가져오기
                                let list = jsonObject["list"] as! NSArray
                                //배열을 순회
                                for index in 0...(list.count - 1){
                                    //객체 가져오기
                                    let itemDict = list[index] as! NSDictionary
                                    
                                    //하나씩 읽어서 메모리에 저장
                                    var item = Item()
                                    item.itemid = ((itemDict["itemid"] as! NSNumber).intValue)
                                    item.itemname = itemDict["itemname"] as? String
                                    item.price = ((itemDict["price"] as! NSNumber).intValue)
                                    item.description = itemDict["description"] as? String
                                    item.pictureurl = itemDict["pictureurl"] as? String
                                    item.updatedate = itemDict["updatedate"] as? String
                                    
                                    //데이터를 itemList에 추가
                                    self.itemList.append(item)
                                    
                                    //데이터베이스에 삽입
                                    let sql = "insert into item(itemid, itemname, price, description, pictureurl, updatedate) values(:itemid, :itemname, :price, :description, :pictureurl, :updatedate)"
                                    //파라미터에 값을 채워서 실행
                                    var paramDict = [String:Any]()
                                    paramDict["itemid"] = item.itemid!
                                    paramDict["itemname"] = item.itemname
                                    paramDict["price"] = item.price
                                    paramDict["description"] = item.description
                                    paramDict["pictureurl"] = item.pictureurl
                                    paramDict["updatedate"] = item.updatedate
                                    itemDB.executeUpdate(sql, withParameterDictionary: paramDict)
                                }
                            }
                            //테이블 뷰 다시 출력
                            self.tableView.reloadData()
                            //데이터베이스 닫기
                            itemDB.close()
                            
                            //업데이트한 시간을 기록
                            let updaterequest = AF.request("http://192.168.1.148/item/lastupdatedate", method: .get, encoding: JSONEncoding.default, headers: [:])
                            
                            updaterequest.responseJSON{
                                response in
                                if let jsonObject = response.value as? [String:Any]{
                                    let result = jsonObject["result"] as? String
                                    let databuffer = result!.data(using: String.Encoding.utf8)
                                    fileMgr.createFile(atPath: updatePath, contents: databuffer, attributes: nil)
                                }
                            }
                        }
                    }
                }
            }
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
    
    //edit 버튼을 눌렀을 때, 보여질 아이콘을 설정하는 메서드
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //edit 버튼을 누르고 보여지는 아이콘을 선택했을 때 호출되는 메서드 재정의
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //취소와 확인을 갖는 대화상자를 출력
        let alert = UIAlertController(title: "데이터 삭제", message: "정말로 삭제하시겠습니까?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취조", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "확인", style: .default){(action) -> Void in
            //삭제할 itemid를 찾아오기
            let itemid = self.itemList[indexPath.row].itemid
            //데이터 목록에서 삭제
            self.itemList.remove(at: indexPath.row)
            //테이블 뷰에서 삭제하는 애니메이션 수행
            self.tableView.deleteRows(at: [indexPath], with: .right)
            
            //서버에서 삭제
            
            //파일이 없는 post 방식에서의 파라미터 만들기
            let parameters = ["itemid":"\(itemid!)"]
            
            //서버의 요청 생성
            let request = AF.request("http://192.168.1.143/item/delete", method: .post, parameters: parameters, encoding: URLEncoding.httpBody, headers: [:])
            request.responseJSON{
                response in
                
                if let jsonObject = response.value as? [String:Any]{
                    //result를 정수로 변환
                    let result = jsonObject["result"] as! Int32
                    
                    var msg = ""
                    if result == 1{
                        msg = "삭제 성공"
                    }else{
                        msg = "삭제 실패"
                    }
                    let resultAlert = UIAlertController(title: "삭제 여부", message: msg, preferredStyle: .alert)
                    resultAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(resultAlert, animated: true)
                }
            }
            
        })
        
        
        //대화상자 출력
        present(alert, animated: true)
    }
    
    //로그인 처리를 위한 메소드로 네비게이션 바의 오른쪽 바 버튼과 연결할 메서드
    //@objc 대신에 @IBAction을 붙이면 Main.storyboard에서 연결해야 하고, @objc를 붙이면 코드로 연결해야 합니다.
    @objc func login(_ sender : Any){
        //이벤트가 발생한 bar button 아이템의 참조 가져오기
        let barButtonItem = sender as! UIBarButtonItem
        
        //로그인 정보를 저장할 파일 경로를 생성
        let fileMgr = FileManager.default
        let docPathURL = fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first!
        let loginPath = docPathURL.appendingPathComponent("login.txt").path
        
        //로그인 처리
        if barButtonItem.title == "로그인"{
            //아이디와 비밀번호 입력창을 출력하고, 로그인 처리를 수행
            let loginAlert = UIAlertController(title: "로그인", message: "아이디와 비밀번호를 입력하세요", preferredStyle: .alert)
            
            //입력란 만들기
            loginAlert.addTextField(){(tf) -> Void in tf.placeholder = "아이디를 입력하세요."}
            loginAlert.addTextField(){(tf) -> Void in tf.isSecureTextEntry = true
                tf.placeholder = "비밀번호를 입력하세요."}
            
            //버튼 만들기
            loginAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
            loginAlert.addAction(UIAlertAction(title: "확인", style: .default){(action) -> Void in
                
                //입력한 내용 가져오기
                let id = loginAlert.textFields?[0].text
                let pw = loginAlert.textFields?[1].text
                
                //post 방식으로 전송할 파라미터로 만들기
                let parameters = ["memberid":id!, "memberpw":pw!]
                
                //요청을 생성
                let request = AF.request("http://192.168.1.148/member/login", method: .post, parameters: parameters, encoding: URLEncoding.httpBody, headers: nil)
                //요청을 전송하고 결과 사용하기
                request.responseJSON{
                    response in
                    //전체 데이터를 디셔너리로 변환
                    if let jsonObject = response.value as? [String:Any]{
                        //result 키의 데이터 가져오기
                        let result = jsonObject["result"] as! Int32
                        //로그인 결과를 출력할 문자열
                        var loginMsg = ""
                        //로그인 성공
                        if result == 1{
                            loginMsg = "succese"
                            //버튼의 타이틀을 변경
                            barButtonItem.title = "log out"
                            
                            //member key의 값을 가져오기
                            let member = jsonObject["member"] as! NSDictionary
                            //nickname 가져오기
                            let nickname = member["membernickname"] as! String
                            //nickname을 타이틀로 설정
                            self.title = nickname
                            
                            //아이디와 별명을 저장
                            let data = "\(id!):\(nickname)"
                            let databuffer = data.data(using: .utf8)
                            fileMgr.createFile(atPath: loginPath, contents: databuffer, attributes: nil)
                        }
                        //로그인 실패
                        else{
                            loginMsg = "fail"
                        }
                        
                        //로그인 결과 출력하기
                        let resultAlert = UIAlertController(title: "로그인 결과", message: loginMsg, preferredStyle: .alert)
                        resultAlert.addAction(UIAlertAction(title: "확인", style: .default))
                        self.present(resultAlert, animated: true)
                    }
                }
            })
            
            //출력
            self.present(loginAlert, animated: true)
        }
        //로그아웃 처리
        else{
            //로그인 성공했을 때 만들어진 파일을 제거
            try! fileMgr.removeItem(atPath: loginPath)
            //대화상자 출력
            let resultAlert = UIAlertController(title: "로그아웃", message: "로그아웃 하셨습니다.", preferredStyle: .alert)
            resultAlert.addAction(UIAlertAction(title: "확인", style: .default))
            self.present(resultAlert, animated: true)
            //버튼의 타이틀 변경
            barButtonItem.title = "로그인"
            self.title = "아이템 목록"
        }
    }
    
    //아이템 추가가 호출할 메소드
    @objc func add(_ sender:Any){
        //ItemAddVC  뷰 컨트롤러 객체 생성
        let addVC = storyboard?.instantiateViewController(identifier: "ItemAddVC") as! ItemAddVC
        
        //네비게이션 바를 이용해서 출력
        self.navigationController?.pushViewController(addVC, animated: true)
    }
}
