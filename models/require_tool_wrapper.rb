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

  attr_accessor :tools

  def tool_instance(tool_name)
    id, name = tool_name.split(';', 2)
    descriptor = Java.jenkins.model.Jenkins.instance.descriptor(id)
    tool = descriptor.installations.find {|ti| ti.name == name }
  end

  # This mimics hudson.cli.InstallToolCommand#install until it's public.
  def install_tool(build, listener, tool)
    build = build.native
    exec = build.executor
    return nil unless exec

    node = exec.owner.node
    if tool.java_kind_of?(Java.hudson.slaves.NodeSpecific)
      tool = tool.forNode(node, listener)
    end

    if tool.java_kind_of?(Java.hudson.model.EnvironmentSpecific)
      tool = tool.forEnvironment(build.environment(listener))
    end

    tool
  end

  # Invoked with the form parameters when this extension point
  # is created from a configuration screen.
  def initialize(attrs = {})
    @tools = attrs.find_all {|attr, _| attr.start_with?('tool_')}.collect {|_, v| v.empty? ? nil : v}.flatten
  end

  # Perform setup for a build
  #
  # invoked after checkout, but before any `Builder`s have been run
  # @param [Jenkins::Model::Build] build the build about to run
  # @param [Jenkins::Launcher] launcher a launcher for the orderly starting/stopping of processes.
  # @param [Jenkins::Model::Listener] listener channel for interacting with build output console
  def setup(build, launcher, listener)
    tools.each do |tool|
      next unless tool["tool"]
      instance = tool_instance(tool["tool"])
      instance = install_tool(build, listener, instance)

      if instance
        # TODO: Set env vars.
      else
        build.halt("Could not install tool!")
      end
    end
  end

  describe_as Java.hudson.tasks.BuildWrapper, :with => RequireToolDescriptor
end
