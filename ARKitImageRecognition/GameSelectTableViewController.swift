//
//  GameSelectTableViewController.swift
//  ARKitImageRecognition
//
//  Created by yihsuanlee on 2018/6/10.
//  Copyright © 2018年 Jayven Nhan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class GameSelectTableViewController: UITableViewController {
    
    var gameList: [GameSimpleInfo] = []
    var presentGame: GameSimpleInfo = GameSimpleInfo()
    var alert: UIAlertController!
    var presentGameInfo: GameInfo = GameInfo()
    var downloadCount: Int = 0
    let downloadFinalCount: Int = 9
    let ref = Database.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        setBgImg()
        loadDataFromFireBase()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    func setBgImg(){
        
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "editorbackground.png")
        backgroundImage.contentMode =  UIViewContentMode.scaleAspectFill
        backgroundImage.alpha = 0.5
        //self.view.insertSubview(backgroundImage, at: 0)
        tableView.backgroundView = backgroundImage

    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    func loadDataFromFireBase(){
        
        ref.observe(DataEventType.value, with: { (snapshot) in
            if let gameDictionary = snapshot.value as? [String: AnyObject]{
                for (gameID, data) in gameDictionary {
                    let tempGSInfo = GameSimpleInfo()
                    tempGSInfo.gameID = gameID
                    let dataDictionary = data as! [String: AnyObject]
                    tempGSInfo.title = dataDictionary["name"] as! String
                    tempGSInfo.introduction = dataDictionary["introduction"] as! String
                    self.gameList.append(tempGSInfo)
                    self.tableView.reloadData()
                }
            }
            //SList.scoreList.append(tempValue)
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return Int(truncating: NSNumber(value:presentGame.title != ""))
        }else{
            return gameList.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return "遊戲中地圖"
        } else {
            return "可下載地圖列表"
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameIntroCell", for: indexPath) as! GameSelectTableViewCell
        var game:GameSimpleInfo = GameSimpleInfo()
        if(indexPath.section == 0){
            game = self.presentGame
        } else {
            game = gameList[indexPath.row]
        }
        cell.gameTitle.text = game.title
        cell.gameIntro.text = game.introduction
        cell.gameLogo.translatesAutoresizingMaskIntoConstraints = false
        cell.gameLogo.layer.cornerRadius = 15
        cell.gameLogo.layer.masksToBounds = true
        return cell
        
    }
 
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: prevent from redownloading
        if(indexPath.section == 0){
            return
        }else{
            self.downloadCount = 0
            print("Start downloading game of \(gameList[indexPath.row].title)")
            setDownloadAlertVC()
            downloadData(gameID: gameList[indexPath.row].gameID)
            //alert.dismiss(animated: true, completion: nil)
        }
    }
    func setDownloadAlertVC(){
        alert = UIAlertController(title: "Downloading...", message: "\n請稍等\n", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
    }
    func downloadData(gameID: String){
        // getting the simple information of the game
        ref.child(gameID).observeSingleEvent(of: .value, with: { (snapshot) in
            let topDictiondary = snapshot.value as? NSDictionary
            self.presentGame.gameID = gameID
            self.setGameInformation(dict: topDictiondary!)
        }) { (error) in
            print(error.localizedDescription)
        }
        // getting the box image information
        ref.child(gameID).child("boxImgInfo").observeSingleEvent(of: .value, with: { (snapshot) in
            let imageDictiondary = snapshot.value as? NSDictionary
            self.presentGameInfo.boxImg = self.setImageInformation(dict: imageDictiondary!, imageName: "treasureBox")
        }) { (error) in
            print(error.localizedDescription)
        }
        // getting the keys information
        self.presentGameInfo.goldKeyInfo = self.setKeysInformation(gameID: gameID, keyType: "goldKey")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(presentGameInfo.goldKeyInfo.keyClue)
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        self.presentGameInfo.silverKeyInfo = self.setKeysInformation(gameID: gameID, keyType: "silverKey")
        self.presentGameInfo.copperKeyInfo = self.setKeysInformation(gameID: gameID, keyType: "copperKey")
        
    }
    func setGameInformation(dict: NSDictionary){
        self.presentGame.title = dict["name"] as! String
        self.presentGame.introduction = dict["introduction"] as! String
        self.presentGameInfo.gameName = dict["name"] as! String
        self.presentGameInfo.introduction = dict["introduction"] as! String
        self.presentGameInfo.boxPos = dict["boxPos"] as! String
        self.presentGameInfo.winMessage = dict["winMsg"] as! String
        addDownloadCount()
    }
    func setKeysInformation(gameID:String, keyType: String) -> KeyInfo{
        var destination = KeyInfo()
        ref.child(gameID).child("keys").child(keyType).observeSingleEvent(of: .value, with: { (snapshot) in
            let keyDictiondary = snapshot.value as? NSDictionary
            destination = self.setSingleKeyInformation(dict: keyDictiondary!, Imgref: self.ref.child(gameID).child("keys").child(keyType).child("keyImgInfo"), keyType: keyType)
        }) { (error) in
            print(error.localizedDescription)
        }
        if(keyType == "goldKey"){
            print("????????????????????????????")
            print(destination.keyClue)
            print("????????????????????????????")
        }
        return destination
    }
    func setSingleKeyInformation(dict: NSDictionary, Imgref: DatabaseReference, keyType: String) -> KeyInfo{
        let destination = KeyInfo()
        destination.keyClue = dict["clue"] as! String
        destination.keyHint = dict["hint"] as! String
        Imgref.observeSingleEvent(of: .value, with: { (snapshot) in
            let imageDictiondary = snapshot.value as? NSDictionary
            destination.keyImg = self.setImageInformation(dict: imageDictiondary!, imageName: keyType)
        }) { (error) in
            print(error.localizedDescription)
        }
        if(keyType == "goldKey"){
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
            print(destination.keyClue)
            print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        }
        return destination
    }
    func setImageInformation(dict: NSDictionary, imageName: String) -> ImageInfo{
        let destination = ImageInfo()
        //destination.image = dict["data"] as! UIImage
        saveImage(url: dict["data"] as! String, filename:imageName)
        destination.isFloor = dict["isFloor"] as! Bool
        addDownloadCount()
        return destination
    }
    func saveImage(url: String, filename: String){
        let imageUrl = URL(string: url)
        URLSession.shared.dataTask(with: imageUrl!, completionHandler: { (data, response, error) in
            if error != nil {
                print("Download Image Task Fail: \(error!.localizedDescription)")
            }
            else if let imageData = data {
                if let image = UIImage(data: imageData){
                    guard let data = UIImageJPEGRepresentation(image, 1) else {return}
                    guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {return}
                    do {
                        try data.write(to: directory.appendingPathComponent("\(filename).jpg")!)
                        print(directory)
                        self.addDownloadCount()
                        return
                    } catch {
                        print(error.localizedDescription)
                        return
                    }
                }
            }
        }).resume()
    }
    func addDownloadCount(){
        self.downloadCount += 1
        print(self.downloadCount)
        if(self.downloadCount == self.downloadFinalCount){
            DispatchQueue.main.async {
                self.alert.dismiss(animated: true, completion: nil)
                self.tableView.reloadData()
                self.startGameHint()
            }
            //print(self.presentGame.title)
            //print(self.presentGameInfo.gameName)
        }
    }
    func startGameHint(){
        let alert = UIAlertController(title: "下載成功", message: "請點擊右上角按鈕開始遊戲", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == "StartGame"){
            if presentGame.title == ""{
                let alert = UIAlertController(title: "開啟遊戲失敗", message: "請先下載下方列表遊戲再開始", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
                return false
            }
            else{
                return true
            }
        }
        // by default, transition
        return true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "StartGame"){
            let gameVC = segue.destination as! ViewController
            gameVC.info = self.presentGameInfo
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

}
