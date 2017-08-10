//
//  TravelViewController.swift
//  PayRoad
//
//  Created by Febrix on 2017. 8. 8..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit

import RealmSwift

class TransactionTableViewController: UIViewController {
    
    var travel: Travel!
    var notificationToken: NotificationToken? = nil
    
    @IBOutlet weak var tableView: UITableView!
    
    var dateDictionary = [Date: [Transaction]]()
    var dateList = [Date]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = travel.name
        
        tableView.delegate = self
        tableView.dataSource = self
        
        initDataStructures()
        
        notificationToken = travel.transactions.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            self?.initDataStructures()
            tableView.reloadData()
        }
    }
    
    @IBAction func editButtonDidTap(_ sender: Any) {
        let moreOptionAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let travelEdit = UIAlertAction(title: "여행 수정", style: .default) { _ in
            print("여행 수정")
            
            //TODO: present(여행 수정 ViewController)
            let travelEditorViewController = UIStoryboard.loadViewController(from: .TravelEditorView, ID: "TravelEditorViewController") as! TravelEditorViewController
            travelEditorViewController.originTravel = self.travel
            travelEditorViewController.mode = .edit
            
            let navigationController = UINavigationController(rootViewController: travelEditorViewController)
            
            self.present(navigationController, animated: true, completion: nil)
        }
        
        let currencySetting = UIAlertAction(title: "통화 설정", style: .default) { [unowned self] _ in
            let currencyTableViewController = UIStoryboard.loadViewController(from: .CurrencyTableView, ID: "CurrencyTableViewController") as! CurrencyTableViewController
            let navigationController = UINavigationController(rootViewController: currencyTableViewController)
            currencyTableViewController.travel = self.travel

            self.present(navigationController, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        moreOptionAlertController.addAction(travelEdit)
        moreOptionAlertController.addAction(currencySetting)
        moreOptionAlertController.addAction(cancel)
        present(moreOptionAlertController, animated: true, completion: nil)
    }
    
    //TODO: 스트링 길다. 나중에 자릅시다.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addTransaction" {
            guard let navigationController = segue.destination as? UINavigationController,
                let addTransactionTableViewController = navigationController.topViewController as? TransactionEditorViewController
            else {
                return
            }
            addTransactionTableViewController.travel = travel
        }
    }
    
    func initDataStructures() {
        dateDictionary = [Date: [Transaction]]()
        dateList = [Date]()
        
        for transaction in travel.transactions {
            guard let dateKey = DateUtil.dateKeyFromDate(from: transaction.date) else {
                print("dateKey로 변환 실패 : \(transaction)")
                continue
            }
            
            if dateDictionary[dateKey] == nil {
                dateDictionary[dateKey] = []
            }
            
            if !dateList.contains(dateKey) {
                dateList.append(dateKey)
            }
            
            dateDictionary[dateKey]?.append(transaction)
            
//            let dateString = DateUtil.defaultFormatter.string(from: transaction.date)
//            
//            print(DateUtil.dateKeyFromDate(from: transaction.date))
//            
//            if dateDictionary[dateString] == nil {
//                dateDictionary[dateString] = []
//            }
//            
//            if !dateList.contains(dateString) {
//                dateList.append(dateString)
//            }
//            
//            dateDictionary[dateString]?.append(transaction)
        }
        
        //TODO: String sort인데, Date 포맷에 종속적이라 나중에 바꿀 필요 있음.
        dateList.sort(by: <)
    }
}

extension TransactionTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dateString = dateList[section]
        
        guard let transactions = dateDictionary[dateString] else {
            return 0
        }
        
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        
        return DateUtil.dateFormatter.string(from: dateList[section])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        
        let dateString = dateList[indexPath.section]
        
        guard let transaction = dateDictionary[dateString]?[indexPath.row] else {
            return cell
        }
        
        cell.textLabel?.text = transaction.name
        
        //TODO: 하나의 Label에 String 속성 변경하는 코드 (통화 3글자 색상 변경) -> 이 코드는 UITableViewCell이 별도의 클래스로 지정될 때 그 클래스의 내부에 선언
        let attributedString = NSMutableAttributedString(string: "\(transaction.currency?.code ?? "") \(transaction.amount)")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray, range: NSRange(location: 0, length: 3))
        cell.detailTextLabel?.attributedText = attributedString
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dateList.count
    }
}
