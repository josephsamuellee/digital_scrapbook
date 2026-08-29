class MemoriesController < ApplicationController
  def new
    @continue_draft = Memory.most_recent_incomplete
    if @continue_draft.nil?
      redirect_to root_path
    end
  end

  def create
    unless create_another?
      @continue_draft = Memory.most_recent_incomplete
      if @continue_draft
        render :new, status: :unprocessable_entity
        return
      end
    end

    memory = Memory::Allocator.create!
    redirect_to edit_memory_path(memory)
  rescue Memory::Store::WriteError
    redirect_to root_path, alert: "Could not save Memory."
  end

  def continue
    memory = Memory.most_recent_incomplete
    if memory
      redirect_to edit_memory_path(memory)
    else
      redirect_to root_path
    end
  end

  def edit
    load_for_edit
    @show_readiness = params[:view_presentation].present?
  end

  def update
    load_for_edit
    @document = @document.with(
      title: memory_params[:title],
      start_date: parse_date(memory_params[:start_date]),
      end_date: parse_date(memory_params[:end_date]),
      subtitle: memory_params[:subtitle]
    )
    Memory::Store.write(@document, memory: @memory)
    redirect_to edit_memory_path(@memory)
  rescue Memory::Store::WriteError
    flash.now[:alert] = "Could not save Memory."
    render :edit, status: :unprocessable_entity
  end

  private

  def create_another?
    params[:create_another].present?
  end

  def load_for_edit
    @memory = Memory.find(params[:id])
    @document = @memory.document
    Memory::Store.reindex_if_stale(@memory, @document)
    @readiness = Memory::Readiness.new(@document, directory: @memory.directory_pathname)
  end

  def memory_params
    params.require(:memory).permit(:title, :start_date, :end_date, :subtitle)
  end

  def parse_date(value)
    return if value.blank?

    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
