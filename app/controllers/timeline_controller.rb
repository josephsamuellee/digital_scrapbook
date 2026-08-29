class TimelineController < ApplicationController
  def index
    Memory::Reconciler.run
    @continue_draft = Memory.most_recent_incomplete
    @years = Memory::Timeline.build
  end
end
