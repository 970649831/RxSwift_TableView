//
//  SignupViewController.swift
//  TaskElephant
//
//  Created by apple on 17/4/12.
//  Copyright © 2017年 xiangguohe. All rights reserved.
//

import UIKit

#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

class SignupViewController: UIViewController {
    
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var userNameActivityLabel: UILabel!
    
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var passWordActivityLabel: UILabel!
    
    @IBOutlet var repeatPassWordTextField: UITextField!
    @IBOutlet var repeatPassWordActivityLabel: UILabel!
    
    @IBOutlet var signUpBtn: UIButton!
    @IBOutlet var signUpActivityView: UIActivityIndicatorView!
    
    var disposeBag = DisposeBag()

    lazy var viewModel: SignupViewModel = {
        
        let viewModel = SignupViewModel.init(
            input: (
                userName: self.userNameTextField.rx.text.orEmpty.asDriver(),
                passWord: self.passwordTextField.rx.text.orEmpty.asDriver(),
                repeatPassWord: self.repeatPassWordTextField.rx.text.orEmpty.asDriver(),
                loginTaps: self.signUpBtn.rx.tap.asDriver()),
                                             
            dependency:(
                    API:GitHubDefaultAPI.sharedAPI,
                    validationService:GitHubDefaultValidationService.sharedValidationService,
                    wireFrame :DefaultWireframe.sharedInstance
                                                
            )
        )
        
        return viewModel
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if IOS7 {
            self.edgesForExtendedLayout = .top
        }
        
        view.backgroundColor = whiteColor
        self.automaticallyAdjustsScrollViewInsets = false

        //登录按钮用户交互
        viewModel.signupEnabled
            .drive(onNext: { [weak self] valid in
                self?.signUpBtn.isEnabled = valid
                self?.signUpBtn.alpha = valid ? 1.0 : 0.5
            })
            .addDisposableTo(disposeBag)
      
        //用户名
        viewModel.validatedUserName
            .drive(userNameActivityLabel.rx.validationResult)
            .addDisposableTo(disposeBag)
        
        //密码
        viewModel.validatePassWord
            .drive(passWordActivityLabel.rx.validationResult)
            .addDisposableTo(disposeBag)
        
        //重复密码
        viewModel.validatedPasswordRepeated
            .drive(repeatPassWordActivityLabel.rx.validationResult)
            .addDisposableTo(disposeBag)

        //注册中
        viewModel.signingIn
            .drive(signUpActivityView.rx.isAnimating)
            .addDisposableTo(disposeBag)

        //注册后
        viewModel.signedIn
            .drive(onNext: { signedIn in
                print("User signed in \(signedIn)")
            })
            .addDisposableTo(disposeBag)

        ShowProgressHUD.showSuccessWithStatus(status: "成功啦")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
   
}









