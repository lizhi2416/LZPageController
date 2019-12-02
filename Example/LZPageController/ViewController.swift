//
//  ViewController.swift
//  LZPageController
//
//  Created by jlzgit on 12/02/2019.
//  Copyright (c) 2019 jlzgit. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    let dataSources = ["StyleDefault", "StyleLine", "StyleFlood", "StyleFloodHollow", "ShowOnNav", "StyleSegmented", "StyleTriangle", "StyleNaughty", "StyleRadius", "StyleBottom"]
        

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Examples"
        
        self.tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "defaultCell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSources.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell")
        cell?.textLabel?.text = dataSources[indexPath.row]
        cell?.accessoryType = .disclosureIndicator
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

