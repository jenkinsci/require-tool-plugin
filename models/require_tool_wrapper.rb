java_import 'java.net.URLEncoder'
java_import 'java.net.URLDecoder'

class RequireToolWrapper < Jenkins::Tasks::BuildWrapper
  display_name "Require tool installations"

  class RequireToolDescriptor < Java.hudson.slaves.NodePropertyDescriptor
    include Jenkins::Model::Descriptor
    include_package 'hudson.tools'

    def installable_tools
      tool_installations = ToolInstallation.all.collect { |tid| tid.installations }.flatten
      installable_tools = tool_installations.find_all { |ti| ti.properties.get(InstallSourceProperty.java_class) }
      installable_tools.collect { |ti| [ti.descriptor.id, ti.name] }
    end
  end

  # Invoked with the form parameters when this extension point
  # is created from a configuration screen.
  def initialize(attrs = {})
    puts attrs.inspect
  end

  # Perform setup for a build
  #
  # invoked after checkout, but before any `Builder`s have been run
  # @param [Jenkins::Model::Build] build the build about to run
  # @param [Jenkins::Launcher] launcher a launcher for the orderly starting/stopping of processes.
  # @param [Jenkins::Model::Listener] listener channel for interacting with build output console
  def setup(build, launcher, listener)

  end

  # Optionally perform optional teardown for a build
  #
  # invoked after a build has run for better or for worse. It's ok if subclasses
  # don't override this.
  #
  # @param [Jenkins::Model::Build] the build which has completed
  # @param [Jenkins::Model::Listener] listener channel for interacting with build output console
  def teardown(build, listener)

  end

  describe_as Java.hudson.tasks.BuildWrapper, :with => RequireToolDescriptor
end
