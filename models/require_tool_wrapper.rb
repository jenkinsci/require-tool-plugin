java_import 'hudson.slaves.NodeSpecific'
java_import 'hudson.model.EnvironmentSpecific'
# Can't java_import, since it clashes with the ruby-runtime Jenkins module.
JenkinsModel = Java.jenkins.model.Jenkins

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

  def tool_instance(tool)
    descriptor = JenkinsModel.instance.descriptor(tool['descriptor_id'])
    descriptor.installations.find { |ti| ti.name == tool['name'] }
  end

  # This mimics hudson.cli.InstallToolCommand#install until it's public.
  def install_tool(build, listener, tool)
    build = build.native
    exec = build.executor
    return nil unless exec

    node = exec.owner.node
    if tool.java_kind_of?(NodeSpecific)
      tool = tool.forNode(node, listener)
    end

    if tool.java_kind_of?(EnvironmentSpecific)
      tool = tool.forEnvironment(build.environment(listener))
    end

    tool
  end

  # Invoked with the form parameters when this extension point
  # is created from a configuration screen.
  def initialize(attrs = {})
    @tools = []
    attrs.each do |attr, info|
      next unless attr.start_with?('tool_') and info and not info.empty?
      descriptor_id, name = info['tool'].split(';', 2)
      @tools << {'descriptor_id' => descriptor_id, 'name' => name}
    end
  end

  # Used in view to check stuff.
  def is_required?(id, name)
    if tools
      tools.any? { |tool| tool["descriptor_id"] == id and tool["name"] == name }
    else
      false
    end
  end

  # Perform setup for a build
  #
  # invoked after checkout, but before any `Builder`s have been run
  # @param [Jenkins::Model::Build] build the build about to run
  # @param [Jenkins::Launcher] launcher a launcher for the orderly starting/stopping of processes.
  # @param [Jenkins::Model::Listener] listener channel for interacting with build output console
  def setup(build, launcher, listener)
    tools.each do |tool_description|
      next if tool_description.empty?

      unless tool_description["name"] and tool_description["descriptor_id"]
        listener.error "[require-tool] Invalid configuration data: #{tool_description.inspect}"
        next
      end

      tool = tool_instance(tool_description)
      unless tool
        build.halt("[require-tool] Could not look up tool: #{tool_description.inspect}")
      end

      tool = install_tool(build, listener, tool)
      if tool
        env_var = tool_description['name'].upcase.gsub(/[^A-Z0-9]+/, '_') + '_HOME'
        build.env[env_var] = tool.home
        listener.info "[require-tool] Making #{env_var} point to #{tool_description['name']}"
      else
        build.halt("[require-tool] Could not install tool!")
      end
    end
  end

  describe_as Java.hudson.tasks.BuildWrapper, :with => RequireToolDescriptor
end
