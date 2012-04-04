
Jenkins::Plugin::Specification.new do |plugin|
  plugin.name = "require-tool"
  plugin.display_name = "Require Tool Plugin"
  plugin.version = '0.0.1'
  plugin.description = 'enter description here'

  # You should create a wiki-page for your plugin when you publish it, see
  # https://wiki.jenkins-ci.org/display/JENKINS/Hosting+Plugins#HostingPlugins-AddingaWikipage
  # This line makes sure it's listed in your POM.
  plugin.url = 'https://wiki.jenkins-ci.org/display/JENKINS/Require+Tool+Plugin'

  # The first argument is your user name for jenkins-ci.org.
  plugin.developed_by "jtjerno", "J\303\270rgen P. Tjern\303\270 <jtjerno@mylookout.com>"

  plugin.uses_repository :github => 'require-tool-plugin'

  # This is a required dependency for every ruby plugin.
  plugin.depends_on 'ruby-runtime', '0.10'
end
