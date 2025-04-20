//
//  ViewController.swift
//  Play It
//
//  Created by 申潤五 on 2018/7/25.
//  Copyright © 2018年 申潤五. All rights reserved.
//

import Cocoa
import AVFoundation
import WebKit

class ViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource,AVAudioPlayerDelegate {
    
    @IBOutlet weak var copyRight: WKWebView!
    //取得 context
    var context:NSManagedObjectContext = ((NSApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext)!
    //取得 appDelegate
    let appDelegate = (NSApplication.shared.delegate as? AppDelegate)!
    
    @IBOutlet weak var playlistTabelView: NSTableView!
    
    @IBOutlet weak var playSegment: NSSegmentedControl!
    
    
    @IBOutlet weak var musicInfo: NSTextField!
    @IBOutlet weak var musicControlPanel: NSBox!
    
    var playListItems:[PlayListItem] = []
    var myPlayer:AVAudioPlayer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        playlistTabelView.delegate = self
        playlistTabelView.dataSource = self
        updatePlaylist()
        myPlayer?.delegate = self
        musicControlPanel.isHidden = true
        copyRight.loadHTMLString("<div>Icons made by <a href=\"http://www.freepik.com\" title=\"Freepik\">Freepik</a> from <a href=\"https://www.flaticon.com/\" title=\"Flaticon\">www.flaticon.com</a> is licensed by <a href=\"http://creativecommons.org/licenses/by/3.0/\" title=\"Creative Commons BY 3.0\" target=\"_blank\">CC 3.0 BY</a></div>", baseURL: nil)

    }
    
    func updatePlaylist(){
        playListItems = []
        //由 Core Data 取得清單
        do {
            playListItems = try context.fetch(PlayListItem.fetchRequest())
            print(playListItems.count)
        } catch  {
            print(error.localizedDescription)
        }
    
        playlistTabelView.reloadData()
        //更新 Play List 的 Table View
    }
    

    @IBAction func addNewSong(_ sender: NSButton) {
        //讀取新檔案
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["mp3"]
        openPanel.allowsOtherFileTypes = false
        openPanel.beginSheetModal(for: self.view.window!) { (id) in
            if (id.rawValue == 1) {
                print(openPanel.url?.absoluteString)
                let playList = PlayListItem(context: self.context)
                playList.fileLocation = openPanel.url?.absoluteString
                playList.filename = openPanel.url?.lastPathComponent
                self.appDelegate.saveAction(nil)
                self.updatePlaylist()
            }
        }
    }
    
    // MARK: Table View Delegate / Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return playListItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        print(tableColumn?.identifier.rawValue)
        switch tableColumn?.identifier.rawValue {
        case "AutomaticTableColumnIdentifier.0":
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "filename"), owner: self) as? NSTableCellView{
                cell.textField?.stringValue = playListItems[row].filename ?? ""
                return cell
            }
        case "AutomaticTableColumnIdentifier.1":
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "myfavorite"), owner: self) as? NSTableCellView{
                if playListItems[row].myfavorite == true {
                    cell.textField?.stringValue = "❤️"
                }else{
                    cell.textField?.stringValue = ""
                }
                return cell
            }
            break
        default:
            break
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print(playlistTabelView.selectedRow)
        musicControlPanel.isHidden = false
        if playlistTabelView.selectedRow == -1 {return}
        musicInfo.stringValue = playListItems[playlistTabelView.selectedRow].fileLocation ?? ""
    }
    
    @IBAction func playClicked(_ sender: Any) {
        if let fileLocation = playListItems[playlistTabelView.selectedRow].fileLocation{
            playSong(fileLocation: fileLocation)
        }
    }
    
    @IBAction func deleteClicked(_ sender: Any) {
        musicControlPanel.isHidden = true
        context.delete(playListItems[playlistTabelView.selectedRow])
        self.appDelegate.saveAction(nil)
        updatePlaylist()
    }
    
    
    @IBAction func setFavouriteClicked(_ sender: Any) {
        musicControlPanel.isHidden = true
        let selectedRow = playlistTabelView.selectedRow
        playListItems[playlistTabelView.selectedRow].myfavorite = !playListItems[selectedRow].myfavorite
        appDelegate.saveAction(nil)
        playlistTabelView.reloadData()
        playlistTabelView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: true)
    }
    
    // MARK:AVAudioPlayer
    
    @IBAction func stopPlay(_ sender: Any) {
        myPlayer?.stop()
    }
    
    func playSong(fileLocation:String){
        do{
            let url = URL(string: fileLocation)
            try myPlayer = AVAudioPlayer(contentsOf: url!)
            myPlayer?.delegate = self
            myPlayer?.play()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("End\(playSegment.selectedSegment)")
        switch playSegment.selectedSegment {
        case 0:
            return
        case 1:
            var nextSeletedRow = playlistTabelView.selectedRow
            
            var checkCounter = 0
            repeat{
                nextSeletedRow += 1
                checkCounter += 1
                if nextSeletedRow == playListItems.count { nextSeletedRow = 0 }
            }while(playListItems[nextSeletedRow].myfavorite == false)
                  && checkCounter <= playListItems.count//如果找到我的最愛或己轉了一廻圈，就跳出
            if checkCounter > playListItems.count { return } //己轉了一廻圈表示沒有我的最月心水
            //清除選取
            playlistTabelView.selectRowIndexes(IndexSet.init(), byExtendingSelection: false)
            //設定選取
            playlistTabelView.selectRowIndexes(IndexSet(integer: nextSeletedRow), byExtendingSelection: true)
            //播放
            playClicked("autoplay")
            return
        case 2:
            var nextSeletedRow = playlistTabelView.selectedRow + 1
            
            //如果己到最後一首，跳到第一首
            if nextSeletedRow == playListItems.count { nextSeletedRow = 0 }
            //清除選取
            playlistTabelView.selectRowIndexes(IndexSet.init(), byExtendingSelection: false)
            //設定選取
            playlistTabelView.selectRowIndexes(IndexSet(integer: nextSeletedRow), byExtendingSelection: true)
            //播放
            playClicked("autoplay")
        default:
            return
        }
    }
    
    
    
}

