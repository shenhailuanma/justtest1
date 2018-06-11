//
//  ConfigureController.swift
//  rabbit
//
//  Created by 张旭 on 2018/6/10.
//  Copyright © 2018 yicheng. All rights reserved.
//

import UIKit

class ConfigureController: UIViewController, UITableViewDelegate,UITableViewDataSource {
 
    
    
    
    let btnStartTag:Int = 1000  //定义btn的tag起始值
    
    //数组，其中的数据是(String,String)格式的元组
    //其内容为列表的应用名和对应的appstore链接
    let name_links_tuples : [(String,String)] =
        []
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    //table的行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return name_links_tuples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
        
        let title :String = name_links_tuples[indexPath.row].0  //获取应用名
        cell.textLabel!.text = title
        
        //每一行有一个下载按钮
        let btn:UIButton = UIButton(type: UIButtonType.custom)
        
        cell.contentView.addSubview(btn)
        
        return cell
    }
    
    //隐藏状态栏方法
    
    override var prefersStatusBarHidden: Bool{
        
        return true
        
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        
    }
}

