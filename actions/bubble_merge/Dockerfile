FROM ruby

LABEL "com.github.actions.name"="Bubble Merge"
LABEL "com.github.actions.description"="This does a bubble merge!"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

COPY bubble_merge.rb /opt/bubble_merge.rb
ENTRYPOINT ["ruby", "/opt/bubble_merge.rb"]
