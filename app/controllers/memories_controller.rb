class MemoriesController < ApplicationController
  STALE_MESSAGE = "Memory changed outside the editor. Reload before continuing."

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
    return unless load_for_edit

    assign_selection
    @show_readiness = params[:view_presentation].present?
    @h2_warning = params[:h2_warning].present?
    @confirming_delete = params[:confirming_delete].present?
  end

  def update
    @memory = Memory.find(params[:id])
    unless @memory.source_readable?
      redirect_to root_path, alert: "This Memory's Markdown file is missing."
      return
    end

    @document = @memory.document
    @page = params[:page].presence || "title"
    @h2_warning = false

    apply_metadata
    apply_selected_page_fields

    case params[:intent].to_s
    when "add_page"
      @document = @document.add_blank_page
      @page = @document.pages.size.to_s
    when "request_delete"
      persist_document!
      redirect_to edit_redirect_path(confirming_delete: 1) and return
    when "delete_page"
      unless params[:confirm_delete].present?
        persist_document!
        redirect_to edit_redirect_path(confirming_delete: 1) and return
      end
      if (index = page_index)
        @document = @document.delete_page_at(index)
      end
      @page = "title"
    when "move_earlier"
      if page_index
        @document, new_index = @document.move_page(page_index, -1)
        @page = (new_index + 1).to_s
      end
    when "move_later"
      if page_index
        @document, new_index = @document.move_page(page_index, 1)
        @page = (new_index + 1).to_s
      end
    end

    @page = params[:select_page] if params[:select_page].present?

    persist_document!

    respond_to do |format|
      format.html { redirect_to edit_redirect_path(view_presentation: params[:view_presentation].presence) }
      format.json do
        render json: {
          status: "saved",
          fingerprint: @memory.source_fingerprint,
          saved_label: "Saved"
        }
      end
    end
  rescue Memory::Store::StaleError
    respond_to do |format|
      format.html do
        load_for_edit
        assign_selection
        flash.now[:alert] = STALE_MESSAGE
        render :edit, status: :conflict
      end
      format.json { render json: { status: "conflict", message: STALE_MESSAGE }, status: :conflict }
    end
  rescue Memory::Store::WriteError
    respond_to do |format|
      format.html do
        load_for_edit
        assign_selection
        flash.now[:alert] = "Could not save Memory."
        render :edit, status: :unprocessable_entity
      end
      format.json { render json: { status: "error", message: "Could not save Memory." }, status: :unprocessable_entity }
    end
  end

  private

  def create_another?
    params[:create_another].present?
  end

  def load_for_edit
    @memory = Memory.find(params[:id])
    unless @memory.source_readable?
      redirect_to root_path, alert: "This Memory's Markdown file is missing."
      return false
    end

    @document = @memory.document
    Memory::Store.reindex_if_stale(@memory, @document)
    @readiness = Memory::Readiness.new(@document, directory: @memory.directory_pathname)
    true
  end

  def assign_selection
    @page = params[:page].presence || "title"
    if page_index.nil? && @page != "title"
      @page = "title"
    end
    @selected_page = page_index && @document.pages[page_index]
  end

  def apply_metadata
    @document = @document.with(
      title: memory_params[:title],
      start_date: parse_date(memory_params[:start_date]),
      end_date: parse_date(memory_params[:end_date]),
      subtitle: memory_params[:subtitle]
    )
  end

  def apply_selected_page_fields
    index = page_index
    return unless index
    return unless memory_params.key?(:page_heading) || memory_params.key?(:page_body)

    body = memory_params[:page_body]
    @h2_warning = Memory::Markdown.contains_h2?(body.to_s)
    @document = @document.replace_page(
      index,
      heading: memory_params[:page_heading],
      body: body
    )
  end

  def persist_document!
    Memory::Store.write(
      @document,
      memory: @memory,
      expected_fingerprint: params[:source_fingerprint]
    )
    @memory.reload
  end

  def page_index
    return if @page.blank? || @page == "title"

    index = @page.to_i - 1
    return if index.negative? || index >= @document.pages.size

    index
  end

  def edit_redirect_path(extra = {})
    options = extra.compact
    options[:page] = @page if @page.present? && @page != "title"
    options[:h2_warning] = 1 if @h2_warning
    edit_memory_path(@memory, options)
  end

  def memory_params
    params.fetch(:memory, {}).permit(:title, :start_date, :end_date, :subtitle, :page_heading, :page_body)
  end

  def parse_date(value)
    return if value.blank?

    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def first_authored_page?
    page_index&.zero?
  end
  helper_method :first_authored_page?

  def last_authored_page?
    page_index && page_index == @document.pages.size - 1
  end
  helper_method :last_authored_page?
end
