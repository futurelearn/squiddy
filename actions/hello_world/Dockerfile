FROM ruby

LABEL "com.github.actions.name"="Hello World"
LABEL "com.github.actions.description"="Write arguments to the standard output"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

COPY hello_world.rb /opt/hello_world.rb
ENTRYPOINT ["ruby", "/opt/hello_world.rb"]
