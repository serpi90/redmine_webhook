class WebhookListener < Redmine::Hook::Listener

  def skip_webhooks(context)
    request = context[:request]
    if request.headers['X-Skip-Webhooks']
      return true
    end
    return false
  end

  def controller_issues_new_after_save(context = {})
    return if skip_webhooks(context)
    issue = context[:issue]
    controller = context[:controller]
    project = issue.project
    webhooks = Webhook.where(:project_id => project.project.id)
    webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
    return unless webhooks
    post(webhooks, issue_to_json(issue, controller))
  end

  def controller_issues_edit_after_save(context = {})
    return if skip_webhooks(context)
    journal = context[:journal]
    controller = context[:controller]
    issue = context[:issue]
    project = issue.project
    webhooks = Webhook.where(:project_id => project.project.id)
    webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
    return unless webhooks
    post(webhooks, journal_to_json(issue, journal, controller))
  end

  def controller_issues_bulk_edit_after_save(context = {})
    return if skip_webhooks(context)
    journal = context[:journal]
    controller = context[:controller]
    issue = context[:issue]
    project = issue.project
    webhooks = Webhook.where(:project_id => project.project.id)
    webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
    return unless webhooks
    post(webhooks, journal_to_json(issue, journal, controller))
  end

  def model_changeset_scan_commit_for_issue_ids_pre_issue_update(context = {})
    issue = context[:issue]
    journal = issue.current_journal
    webhooks = Webhook.where(:project_id => issue.project.project.id)
    webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
    return unless webhooks
    post(webhooks, journal_to_json(issue, journal, nil))
  end

  private
  def issue_to_json(issue, controller)
    {
      :payload => {
        :action => 'opened',
        :issue => IssueWrapper.new(issue).to_hash,
        :url => controller.issue_url(issue)
      }
    }.to_json
  end

  def journal_to_json(issue, journal, controller)
    {
      :payload => {
        :action => 'updated',
        :issue => IssueWrapper.new(issue).to_hash,
        :journal => JournalWrapper.new(journal).to_hash,
        :url => controller.nil? ? 'not yet implemented' : controller.issue_url(issue)
      }
    }.to_json
  end

  def post(webhooks, request_body)
    Thread.start do
      webhooks.each do |webhook|
        begin
          if webhook.url[0..4] == 'redis' then
              pos = webhook.url.rindex('#')
              redis_url = webhook.url[0..pos-1]
              topic = webhook.url[pos+1..-1]
              redis = Redis.new(url: redis_url)
              redis.publish(topic, request_body)
          else
              Faraday.post do |req|
                req.url webhook.url
                req.headers['Content-Type'] = 'application/json'
                req.body = request_body
              end
          end
        rescue => e
          Rails.logger.error e
        end
      end
    end
  end
end
