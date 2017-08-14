//
//  SignupViewModel.swift
//  TaskElephant
//
//  Created by apple on 17/4/12.
//  Copyright © 2017年 xiangguohe. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
class SignupViewModel: NSObject {

    var validatedUserName : Driver<ValidationResult>!//用户名
    var validatePassWord : Driver<ValidationResult>!//密码
    var validatedPasswordRepeated : Driver<ValidationResult>!//验证密码

    //注册按钮的交互
    var signupEnabled : Driver<Bool>!
    
    //注册指示器
    var signingIn : Driver<Bool>!
    
    //注册后 -- 成功或失败
    var signedIn: Driver<Bool>!
    
    init(
        input:( //传参
            userName:Driver<String>,
            passWord:Driver<String>,
            repeatPassWord:Driver<String>,
            loginTaps:Driver<Void>
        ),
        dependency:(//服务,接口
            API:GitHubAPI,
            validationService:GitHubValidationService,
            wireFrame :Wireframe
        )
        ) {
           super.init()
           //缓存接口网址
           let API = dependency.API
           let validationService = dependency.validationService
           let wireframe = dependency.wireFrame
        
           //用户名
           validatedUserName = input.userName
                     .flatMapLatest({ (userName) in
                        return validationService.validateUsername(userName: userName)
                               .asDriver(onErrorJustReturn: .failed(message: "连接服务器错误"))//Error contacting server
                     })
           //密码
           validatePassWord = input.passWord
                      .map({ (passWord) in
                        return validationService.validationPassWord(passWord: passWord)
                      })
           //验证密码
           validatedPasswordRepeated = Driver.combineLatest(input.passWord, input.repeatPassWord, resultSelector: validationService.validationRepeatedPassword)
        
           //注册指示器
        let signingIn = ActivityIndicator()
        self.signingIn = signingIn.asDriver()
        
        let userNameAndPassWord = Driver.combineLatest(input.userName, input.passWord) { ($0, $1) }
        
        signedIn = input.loginTaps.withLatestFrom(userNameAndPassWord)
               .flatMapLatest({ (userName,passWord) in
                   return API.signup(userName: userName, passWord: passWord)
                        .trackActivity(signingIn)
                        .asDriver(onErrorJustReturn: false)
               })
               .flatMapLatest({ (loggedIn) -> Driver<Bool> in
                   let message  = loggedIn ? "注册成功" : "注册失败"
                return wireframe.promptFor(message, cancelAction: "OK", actions: [])
                    // propagate original value
                    .map { _ in
                        loggedIn
                    }
                    .asDriver(onErrorJustReturn: false)
               })
        
         //缓存注册按钮交互
        cacheSignupEnabled()
        
    }
    
}

extension SignupViewModel {
    
    func cacheSignupEnabled() -> Void {
        
        signupEnabled = Driver.combineLatest(validatedUserName, validatePassWord, validatedPasswordRepeated, signingIn){ username, password, repeatPassword, signingIn in
            username.isValid &&
                password.isValid &&
                repeatPassword.isValid &&
                !signingIn
            }.distinctUntilChanged()
        
    }
    
}








