# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https:#www.datadoghq.com/).
# Copyright 2016-2019 Datadog, Inc.

require "./lib/ostools.rb"
require 'pathname'

name "datadog-trace-agent"

dependency "datadog-agent"

trace_agent_version = ENV['TRACE_AGENT_VERSION']
if trace_agent_version.nil? || trace_agent_version.empty?
  trace_agent_version = 'master'
end

default_version trace_agent_version

source path: '..'
relative_path 'src/github.com/DataDog/datadog-agent'

build do
  # set GOPATH on the omnibus source dir for this software
  gopath = Pathname.new(project_dir) + '../../../..'
  if windows?
    env = {
      # Trace agent uses GNU make to build.  Some of the input to gnu make
      # needs the path with `\` as separators, some needs `/`.  Provide both,
      # and let the makefile sort it out (ugh)

      # also on windows don't modify the path.  Modifying the path here mixes
      # `/` with `\` in the PATH variable, which confuses the make (and sub-processes)
      # below.  When properly configured the path on the windows box is sufficient.
      'GOPATH' => "#{windows_safe_path(gopath.to_path)}",
    }
  else
    env = {
      'GOPATH' => gopath.to_path,
      'PATH' => "#{gopath.to_path}/bin:#{ENV['PATH']}",
    }
  end

  block do
    command "invoke trace-agent.build", :env => env

    if windows?
      copy 'bin/trace-agent/trace-agent.exe', "#{Omnibus::Config.source_dir()}/datadog-agent/src/github.com/DataDog/datadog-agent/bin/agent"
    else
      copy 'bin/trace-agent/trace-agent', '#{install_dir}/embedded/bin'
    end
  end
end
