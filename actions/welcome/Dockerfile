FROM ruby

LABEL "com.github.actions.name"="Welcome"
LABEL "com.github.actions.description"="This is the welcome action to test Squiddy out"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

COPY welcome.rb /opt/welcome.rb
ENTRYPOINT ["ruby", "/opt/welcome.rb"]
