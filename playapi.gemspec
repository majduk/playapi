Gem::Specification.new do |s|
  s.name        = "playapi"
  s.version     = "1.1"
  s.platform    = Gem::Platform::RUBY
  s.summary     = "PlayAPI client"
  s.email       = ""
  s.homepage    = "http://www.play.pl"
  s.description = "PlayAPI Clients"
  s.authors     = ['Michal Ajduk']

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency("serviceproxy")
  s.add_dependency("hpricot")
end
