class TimelineController < ApplicationController
  def index
    @continue_draft = Memory.most_recent_incomplete
    @years = Memory::Timeline.build
  end
end
