Pod::Spec.new do |s|
  s.name             = 'PPQueue'
  s.version          = '1.0.0'
  s.license          = 'MIT'
  s.summary          = 'A priorized persistent background job queue for iOS.'
  s.homepage         = 'https://github.com/daluethi/ppqueue'
  s.author           = 'Daniel Luethi'
  s.social_media_url = "http://twitter.com/daluethi"
  s.source           = { :git => 'https://github.com/daluethi/ppqueue.git', :tag => 'v1.0.0' }
  s.platform         = :ios, '5.0'
  s.source_files     = 'PPQueue'
  s.library          = 'sqlite3.0'
  s.requires_arc     = true
  s.dependency 'FMDB', '~> 2.0'
end
