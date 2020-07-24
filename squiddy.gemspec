Gem::Specification.new do |s|
  s.name        = 'squiddy'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = "A FutureLearn bot for GitHub Actions"
  s.files       = Dir['lib/*.rb', 'lib/squiddy/*.rb', 'bin/*']
  s.homepage    = 'https://github.com/futurelearn/squiddy'
  s.authors     = ['Laura Martin']
  s.email       = ['laura.martin@futurelearn.com']
  s.bindir      = 'bin'
  s.executables = 'squiddy'

  # Dependencies
  s.add_runtime_dependency 'octokit', '~> 4.18.0'
  s.add_runtime_dependency 'ruby-trello', '~> 2.3.1'
end
