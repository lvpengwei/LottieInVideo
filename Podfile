source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

inhibit_all_warnings!

def ui
    pod 'UIColor_Hex_Swift', '~> 4.2.0'
    pod 'SnapKit', '~> 4.2.0'
end

def video
    pod 'lottie-ios', :git => 'https://github.com/lvpengwei/lottie-ios.git', :commit => '382dc16e78cbe345585c58b284078aefd39624c8'
    pod 'AVPlayerSeeker', :git => 'https://github.com/lvpengwei/AVPlayerSeeker.git', :commit => '31381b0249d0d9a3dbae3a2c893fb132561547e7'
    pod 'SCRecorder', :git => 'https://github.com/lvpengwei/SCRecorder.git', :commit => 'f507fcc38228e14d1c2d970f559548742cbf13a6'
end

def fundmental
    pod 'RxCocoa', '~> 4.4.0'
end

target 'LottieInVideo' do
    use_frameworks!
    
    ui
    video
    fundmental
end
