Pod::Spec.new do |s|
  s.name             = "Sqlable"
  s.version          = "1.0.0"
  s.summary          = "Swift ORM framework."

  s.description      = <<-DESC
    Sqlable is a Swift ORM framework.
                       DESC

  s.homepage         = "https://github.com/Meniny/Sqlable"
  s.license          = { :type => "MIT", :file => "LICENSE.md" }
  s.author           = { "Elias Abel" => "admin@meniny.cn" }
  s.source           = { :git => "https://github.com/Meniny/Sqlable.git", :tag => s.version.to_s }
  s.social_media_url = 'https://meniny.cn/'

  s.module_name      = 'Sqlable'

  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target = "9.1"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.2"

  s.swift_version    = '4.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => s.swift_version.to_s }
  s.source_files = 'Sqlable/**/*.{swift}'
  # s.private_header_files = 'Sqlable/**/*.h'
  s.library = 'sqlite3'
  s.xcconfig = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -DSQLITE_SWIFT_STANDALONE' }
  # s.xcconfig = {
  #     'OTHER_SWIFT_FLAGS' => '$(inherited) -DSQLITE_SWIFT_SQLCIPHER',
  #     'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1'
  #   }
end
