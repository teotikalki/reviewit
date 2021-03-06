module MergeRequestsHelper
  def patches
    @patches ||= @mr.patches
  end

  def patch_name(patch, version = nil)
    version ||= @mr.patches.index(patch) + 1
    patch.description.blank? ? "#{version.ordinalize} version" : "v#{version}: #{patch.description}"
  end

  def patch_linter_status(patch)
    content_tag(:span, '', class: "fa #{patch.linter_ok? ? 'fa-check ok' : 'fa-remove fail'}")
  end

  def search_request?
    !params[:author].blank? || !params[:target_branch].blank? || !params[:subject].blank?
  end

  def merge_request_status_line(mr)
    if mr.closed?
      "Closed #{distance_of_time_in_words(Time.now, mr.updated_at)} ago,"
    else
      last_patch = mr.patch
      return if last_patch.nil?
      time = last_patch.updated_at
      last_comment = last_patch.comments.order('id DESC').limit(1).first
      time = last_comment.created_at if last_comment
      time = distance_of_time_in_words(Time.now, time)
      "Pending for #{time},"
    end
  end

  def patch_ci_status(patch)
    if patch.success?
      'review-list--success'
    elsif patch.canceled?
      'review-list--canceled'
    elsif patch.failed?
      'review-list--failure'
    end
  end

  def patch_ci_icon(patch)
    return unless patch.project.gitlab_ci?

    icon = "<i class='fa #{patch_ci_fa(patch)}'></i>".html_safe
    if patch.unknown?
      icon
    else
      content_tag(:a, icon, 'data-balloon' => patch_ci_tip(patch),
                            'data-balloon-pos' => "down",
                             target: "patch-#{patch.gitlab_ci_hash}",
                             href: "#{patch.project.gitlab_ci_project_url}/builds/#{patch.gitlab_ci_build}")
    end
  end

  def should_show_patch_comment_divisor(patch, main_patch)
    return patch.comments.general.any? if patch == main_patch
    patch.comments.general.any?
  end

  def interdiff_view?
    @from.nonzero?
  end

  def diff_file_status(file)
    flags = {}
    if file.new?
      flags['new'] = 'new'
      flags['chmod-changed'] = "chmod #{file.new_chmod}"
    elsif file.deleted?
      flags['deleted'] = 'deleted'
    elsif file.renamed?
      flags['renamed'] = "renamed #{file.similarity}"
    elsif file.chmod_changed?
      flags['chmod-changed'] = "chmod change: #{file.old_chmod} → #{file.new_chmod}"
    end

    # interdiff tags
    flags['interdiff-tag'] = file.interdiff_tag if file.interdiff_tag

    flags.map do |flag, label|
      content_tag(:span, label, class: "flag #{flag}")
    end.join.html_safe
  end

  def target_branch_locked?
    @target_branch_locked ||= @mr.target_branch_locked?
  end

  def foreach_locked_branches
    @project.locked_branches.includes(:who).group_by(&:who).each do |user, locked_branches|
      branches = locked_branches.map { |i| "<strong>#{i.branch}</strong>" }.to_sentence.html_safe
      yield(user.name, branches, locked_branches.size)
    end
  end

  def issue_link(issue)
    content = issue.content.truncate(120)
    options = { anchor: "comment-#{issue.id}" }
    if issue.patch_id != @mr.patch.id
      version = @mr.patch_ids.index(issue.patch_id) + 1
      options[:to] = version
      extra = "On #{version.ordinalize} version"
    end

    output = link_to(content, project_merge_request_path(@project, @mr, options))
    output += content_tag(:span, extra, class: 'flag patch-warning') unless extra.blank?
    output
  end

  def code_comment_icon(comments)
    if comments.any?(&:blocker?)
      'fa fa-exclamation'
    elsif comments.any?(&:solved?)
      'fa fa-check'
    else
      'fa fa-comments'
    end
  end

  private

  def code_line_type(line)
    case line[0]
    when '+' then 'add'
    when '-' then 'del'
    when '@' then 'info'
    end
  end

  def patch_ci_tip(patch)
    "CI #{patch.gitlab_ci_status}"
  end

  def patch_ci_fa(patch)
    case patch.gitlab_ci_status
    when 'failed' then 'fa-remove fail'
    when 'success' then 'fa-check ok'
    when 'unknown' then 'fa-question'
    when 'pending' then 'fa-clock-o'
    when 'canceled' then 'fa-ban'
    when 'running' then 'fa-cog fa-spin'
    end
  end

  def target_branch_options
    options = MergeRequest.uniq.where(project_id: @project.id).order('target_branch ASC').pluck(:target_branch)
    options.unshift(['', ''])
    options_for_select(options, params[:target_branch])
  end

  def member_options
    options = User.uniq.order('name ASC').joins(:merge_requests)
                  .where('merge_requests.project_id = ?', @project.id).pluck(:name, :id)
    options.unshift(['', ''])
  end
end
