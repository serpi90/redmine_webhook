require_dependency 'projects_helper'
module RedmineWebhook
  module ProjectsHelperPatch
    def self.included(base)
      base.class_eval do
        alias_method :project_settings_tabs_without_webhook, :project_settings_tabs
        alias_method :project_settings_tabs, :project_settings_tabs_with_webhook
      end
    end

    def project_settings_tabs_with_webhook
      tabs = project_settings_tabs_without_webhook
      tabs << {
        :name => 'webhook',
        :controller => 'webhook_settings',
        :action => :show,
        :partial => 'webhook_settings/show',
        :label => :webhook
      }
    end
  end
end
