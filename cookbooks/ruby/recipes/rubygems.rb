def ensure_rubygems_version
  rubygems = node.engineyard.environment.ruby.fetch(:rubygems,nil) if node.engineyard.environment.ruby?

  if rubygems && (Gem::Version.new(`gem -v`) != Gem::Version.new(rubygems))
    # set rubygem update command

    # 1.5.2 is a "special needs" version, since gem system update syntax changed from that version and up.
    # sort -t. -k1,1n -k2,2n -k3,3n -k4,4n is used to do a version sort, and if 1.5.2 is the lesser of the
    # two versions, then it needs to use the new syntax

    update_command =<<-EOF
    gem_version=`gem -v`
    if [[ "$(printf "1.5.2\\n$gem_version" | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | head -n1)" == "1.5.2" ]] ; then gem update --system #{rubygems}; else update_rubygems; fi
    EOF

    # Uninstall previously installed version of Rubygems
    #  TODO: uninstall ALL versions of rubygems -- the below code won't work if there are multiple versions installed
    ruby_block "uninstall previous versions of rubygems" do
      block do
        output = Mixlib::ShellOut.new('gem list rubygems').run_command.stdout
        matchdata = output.match(/\(([^\)]*)\)/)
        if versions = (matchdata && matchdata[1])
          versions.split(',').each do |version|
            version.strip!
             if version != rubygems
               Mixlib::ShellOut.new('gem uninstall rubygems-update -v #{version}')
             end
          end
        else
          Mixlib::ShellOut.new('gem install rubygems-update -v #{rubygems} --no-ri --no-rdoc')
        end
      end
    end

    ey_cloud_report "rubygems update" do
      message "installing Rubygems #{rubygems}"
    end

    execute "install rubygems #{rubygems}" do
      command "gem install rubygems-update -v #{rubygems} --no-ri --no-rdoc"
    end

    bash "update rubygems to >= #{rubygems}" do
      code update_command
    end

  end
end

if node.engineyard.environment.ruby?
  ensure_rubygems_version
end