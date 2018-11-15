Gem::Specification.new do |s|
  s.name        = 'simulator'
  s.version     = '0.0.1'
  s.date        = '2015-12-03'
  s.summary     = "NewCo simulator framework"
  s.executables << 'sim'
  s.description = "Implements a simulator framework"
  s.authors     = ["Steve Tuckner", "Mike Graves"]
  s.email       = 'mgraves@outcome.com'
  s.homepage    = 'http://justculture.org'
  s.files       = Dir["lib/*"]
  s.license     = 'MIT'

  s.add_dependency 'activesupport', '~> 4.0'
  s.add_dependency 'rgl',           '~> 0.5.0'
  s.add_dependency 'lspace',        '~> 0.13.0'
  s.add_dependency 'anima',         '~> 0.2.0'
  s.add_dependency 'adamantium',    '~> 0.2.0'
  s.add_dependency 'hamster',       '~> 1.0'
  s.add_dependency 'funkify',       '~> 0.0.4'
  s.add_dependency 'algebrick',     '~> 0.7'
  s.add_dependency 'descriptive_statistics', '~> 2.5'
  s.add_dependency 'concurrent-ruby-edge', '~> 0.1.1'
end
